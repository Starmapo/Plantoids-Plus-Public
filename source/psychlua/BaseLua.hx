package psychlua;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.addons.display.FlxRuntimeShader;
import haxe.Constraints.Function;
import objects.Note;
import objects.NoteSplash;
import sys.FileSystem;
import sys.io.File;

class BaseLua
{
	public static var Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";
	public static var Function_StopHScript:Dynamic = "##PSYCHLUA_FUNCTIONSTOPHSCRIPT";
	public static var Function_StopAll:Dynamic = "##PSYCHLUA_FUNCTIONSTOPALL";

	public static var lastCalledScript:BaseLua = null;

	#if LUA_ALLOWED
	public static function getBool(variable:String)
	{
		if (lastCalledScript == null)
			return false;

		var lua:State = lastCalledScript.lua;
		if (lua == null)
			return false;

		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null)
		{
			return false;
		}
		return (result == 'true');
	}
	#end

	// clone functions
	public static function getBuildTarget():String
	{
		#if windows
		return 'windows';
		#elseif linux
		return 'linux';
		#elseif mac
		return 'mac';
		#elseif html5
		return 'browser';
		#elseif android
		return 'android';
		#elseif switch
		return 'switch';
		#else
		return 'unknown';
		#end
	}

	#if LUA_ALLOWED
	public var lua:State = null;
	#end
	public var scriptName:String = '';
	public var closed:Bool = false;

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();

	#if SScript
	public var hscript:BaseHScript = null;
	#end

	// main
	public var lastCalledFunction:String = '';

	#if (MODS_ALLOWED && !flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end

	public var game(default, null):IScriptState;

	var luaArray(get, never):Array<BaseLua>;

	function get_luaArray()
	{
		return game.luaArray;
	}

	var hscriptArray(get, never):Array<BaseHScript>;

	function get_hscriptArray()
	{
		return game.hscriptArray;
	}

	public function new(scriptName:String)
	{
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		// trace('Lua version: ' + Lua.version());
		// trace("LuaJIT version: " + Lua.versionJIT());

		// LuaL.dostring(lua, CLENSE);

		this.scriptName = scriptName;

		game = cast MusicBeatState.getState();
		game.luaArray.push(this);

		preset();

		loadFile();
		#end
	}

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		#if LUA_ALLOWED
		if (closed)
			return Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		try
		{
			if (lua == null)
				return Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION)
			{
				if (type > Lua.LUA_TNIL)
					onError("ERROR (" + func + "): attempt to call a " + LuaUtils.typeToString(type) + " value");

				Lua.pop(lua, 1);
				return Function_Continue;
			}

			for (arg in args)
				Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK)
			{
				var error:String = getErrorMessage(status);
				onError("ERROR (" + func + "): " + error);
				return Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null)
				result = Function_Continue;

			Lua.pop(lua, 1);
			if (closed)
				stop();
			return result;
		}
		catch (e:Dynamic)
		{
			trace(e);
		}
		#end
		return Function_Continue;
	}

	public function set(variable:String, data:Dynamic)
	{
		#if LUA_ALLOWED
		if (lua == null)
		{
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	public function addLocalCallback(name:String, myFunction:Dynamic)
	{
		#if LUA_ALLOWED
		callbacks.set(name, myFunction);
		Lua_helper.add_callback(lua, name, null); // just so that it gets called
		#end
	}

	public function getErrorMessage(status:Int):String
	{
		#if LUA_ALLOWED
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null)
			v = v.trim();
		if (v == null || v == "")
		{
			switch (status)
			{
				case Lua.LUA_ERRRUN:
					return "Runtime Error";
				case Lua.LUA_ERRMEM:
					return "Memory Allocation Error";
				case Lua.LUA_ERRERR:
					return "Critical Error";
			}
			return "Unknown Error";
		}

		return v;
		#end
		return null;
	}

	public function stop()
	{
		#if LUA_ALLOWED
		closed = true;

		if (lua == null)
		{
			return;
		}
		Lua.close(lua);
		lua = null;
		#if HSCRIPT_ALLOWED
		if (hscript != null)
		{
			hscript.destroy();
			hscript = null;
		}
		#end
		#end
	}

	public function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true, ?allowMaps:Bool = false):Dynamic
	{
		switch (objectName)
		{
			case 'this' | 'instance' | 'game':
				return game;

			default:
				var obj:Dynamic = game.getLuaObject(objectName, checkForTextsToo);
				if (obj == null)
					obj = getVarInArray(getTargetInstance(), objectName, allowMaps);
				return obj;
		}
	}

	public function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any
	{
		var splitProps:Array<String> = variable.split('[');
		if (splitProps.length > 1)
		{
			var target:Dynamic = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}

		if (allowMaps && LuaUtils.isMap(instance))
		{
			// trace(instance);
			return instance.get(variable);
		}

		return Reflect.getProperty(instance, variable);
	}

	public function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic
	{
		var obj:Dynamic = getObjectDirectly(split[0], checkForTextsToo);
		var end = split.length;
		if (getProperty)
			end = split.length - 1;

		for (i in 1...end)
			obj = getVarInArray(obj, split[i], allowMaps);
		return obj;
	}

	public function getTargetInstance():FlxState
	{
		return cast game;
	}

	public function resetSpriteTag(tag:String)
	{
		#if LUA_ALLOWED
		if (!game.modchartSprites.exists(tag))
		{
			return;
		}

		var target:ModchartSprite = game.modchartSprites.get(tag);
		target.kill();
		game.remove(target, true);
		target.destroy();
		game.modchartSprites.remove(tag);
		#end
	}

	public function resetTextTag(tag:String)
	{
		#if LUA_ALLOWED
		if (!game.modchartTexts.exists(tag))
		{
			return;
		}

		var target:FlxText = game.modchartTexts.get(tag);
		target.kill();
		game.remove(target, true);
		target.destroy();
		game.modchartTexts.remove(tag);
		#end
	}

	public function cameraFromString(cam:String):FlxCamera
	{
		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud':
				return game.camHUD;
			case 'camother' | 'other':
				return game.camOther;
		}
		return game.camGame;
	}

	public function addObject(obj:FlxBasic, front:Bool = false)
	{
		if (front)
			getTargetInstance().add(obj);
		else
			getTargetInstance().insert(getTargetInstance().members.indexOf(getLowestCharacterGroup()), obj);
	}

	public function getLowestCharacterGroup():FlxSpriteGroup
	{
		var group:FlxSpriteGroup = game.gfGroup;
		var pos:Int = game.members.indexOf(group);

		var newPos:Int = game.members.indexOf(game.boyfriendGroup);
		if (newPos < pos)
		{
			group = game.boyfriendGroup;
			pos = newPos;
		}

		newPos = game.members.indexOf(game.dadGroup);
		if (newPos < pos)
		{
			group = game.dadGroup;
			pos = newPos;
		}
		return group;
	}

	public function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
	{
		var splitProps:Array<String> = variable.split('[');
		if (splitProps.length > 1)
		{
			var target:Dynamic = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if (i >= splitProps.length - 1) // Last array
					target[j] = value;
				else // Anything else
					target = target[j];
			}
			return target;
		}

		if (allowMaps && LuaUtils.isMap(instance))
		{
			// trace(instance);
			instance.set(variable, value);
			return value;
		}

		Reflect.setProperty(instance, variable, value);
		return value;
	}

	public function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic> = null)
	{
		if (args == null)
			args = [];
		var split:Array<String> = funcStr.split('.');
		var funcToRun:Function = null;
		var obj:Dynamic = classObj;

		// trace('start: $obj');
		if (obj == null)
		{
			return null;
		}
		for (i in 0...split.length)
		{
			obj = getVarInArray(obj, split[i].trim());
			// trace(obj, split[i]);
		}
		funcToRun = cast obj;
		// trace('end: $obj');
		return funcToRun != null ? Reflect.callMethod(obj, funcToRun, args) : null;
	}

	inline public function getTextObject(name:String):FlxText
	{
		return #if LUA_ALLOWED game.modchartTexts.exists(name) ? game.modchartTexts.get(name) : #end
		Reflect.getProperty(game, name);
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if (!ClientPrefs.data.shaders)
			return false;

		#if (MODS_ALLOWED && !flash && sys)
		if (runtimeShaders.exists(name))
		{
			onLuaLog('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for (mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if (FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else
					frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else
					vert = null;

				if (found)
				{
					runtimeShaders.set(name, [frag, vert]);
					// trace('Found shader $name!');
					return true;
				}
			}
		}
		onError('Missing shader $name .frag AND .vert files!');
		#else
		onError('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}

	#if (!flash && sys)
	public function getShader(obj:String):FlxRuntimeShader
	{
		var split:Array<String> = obj.split('.');
		var target:FlxSprite = null;
		if (split.length > 1)
			target = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
		else
			target = getObjectDirectly(split[0]);

		if (target == null)
		{
			onError('Error on getting shader: Object $obj not found');
			return null;
		}
		return cast(target.shader, FlxRuntimeShader);
	}
	#end

	public function addAnimByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Int = 24, loop:Bool = false)
	{
		var obj:Dynamic = getObjectDirectly(obj, false);

		if (obj != null && obj.animation != null)
		{
			var indices:Any = indices;
			if (indices == null)
				indices = [];
			if (Std.isOfType(indices, String))
			{
				var strIndices:Array<String> = cast(indices, String).trim().split(',');
				var myIndices:Array<Int> = [];
				for (i in 0...strIndices.length)
				{
					myIndices.push(Std.parseInt(strIndices[i]));
				}
				indices = myIndices;
			}
			obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
			if (obj.animation.curAnim == null)
			{
				if (obj.playAnim != null)
					obj.playAnim(name, true);
				else
					obj.animation.play(name, true);
			}
			return true;
		}
		return false;
	}

	public function initHaxeModule(?file:String)
	{
		hscript = new BaseHScript(this, file);
	}

	public function onError(msg:String, important:Bool = false)
	{
		game.addTextToDebug(msg, FlxColor.RED);
		trace(msg);
	}

	public function onLuaLog(msg:String)
	{
		game.addTextToDebug(msg, FlxColor.WHITE);
		trace(msg);
	}

	public function warnDeprecated(msg:String)
	{
		game.addTextToDebug(msg, FlxColor.WHITE);
		trace(msg);
	}

	function preset()
	{
		// Lua shit
		set('Function_StopLua', Function_StopLua);
		set('Function_StopHScript', Function_StopHScript);
		set('Function_StopAll', Function_StopAll);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// Music stuff
		set('curSection', 0);
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		// Some settings, no jokes
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('scoreZoom', ClientPrefs.data.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		// Noteskin/Splash
		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		set('buildTarget', getBuildTarget());

		Lua_helper.add_callback(lua, "getRunningScripts", function()
		{
			var runningScripts:Array<String> = [];
			for (script in luaArray)
				runningScripts.push(script.scriptName);
			return runningScripts;
		});

		addLocalCallback("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName))
				exclusions.push(scriptName);
			game.setOnScripts(varName, arg, exclusions);
		});
		addLocalCallback("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName))
				exclusions.push(scriptName);
			game.setOnHScript(varName, arg, exclusions);
		});
		addLocalCallback("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
		{
			if (exclusions == null)
				exclusions = [];
			if (ignoreSelf && !exclusions.contains(scriptName))
				exclusions.push(scriptName);
			game.setOnLuas(varName, arg, exclusions);
		});

		addLocalCallback("callOnScripts",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && !excludeScripts.contains(scriptName))
					excludeScripts.push(scriptName);
				game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
		addLocalCallback("callOnLuas",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && !excludeScripts.contains(scriptName))
					excludeScripts.push(scriptName);
				game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
		addLocalCallback("callOnHScript",
			function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null,
					?excludeValues:Array<Dynamic> = null)
			{
				if (excludeScripts == null)
					excludeScripts = [];
				if (ignoreSelf && !excludeScripts.contains(scriptName))
					excludeScripts.push(scriptName);
				game.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});

		Lua_helper.add_callback(lua, "callScript", function(luaFile:String, funcName:String, ?args:Array<Dynamic> = null)
		{
			if (args == null)
			{
				args = [];
			}

			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in luaArray)
					if (luaInstance.scriptName == foundScript)
					{
						luaInstance.call(funcName, args);
						return;
					}
		});

		Lua_helper.add_callback(lua, "getGlobalFromScript", function(luaFile:String, global:String)
		{ // returns the global from a script
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in luaArray)
					if (luaInstance.scriptName == foundScript)
					{
						Lua.getglobal(luaInstance.lua, global);
						if (Lua.isnumber(luaInstance.lua, -1))
							Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
						else if (Lua.isstring(luaInstance.lua, -1))
							Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
						else if (Lua.isboolean(luaInstance.lua, -1))
							Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
						else
							Lua.pushnil(lua);

						// TODO: table

						Lua.pop(luaInstance.lua, 1); // remove the global

						return;
					}
		});
		Lua_helper.add_callback(lua, "setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic)
		{ // returns the global from a script
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in luaArray)
					if (luaInstance.scriptName == foundScript)
						luaInstance.set(global, val);
		});
		/*Lua_helper.add_callback(lua, "getGlobals", function(luaFile:String) { // returns a copy of the specified file's globals
			var foundScript:String = findScript(luaFile);
			if(foundScript != null)
			{
				for (luaInstance in luaArray)
				{
					if(luaInstance.scriptName == foundScript)
					{
						Lua.newtable(lua);
						var tableIdx = Lua.gettop(lua);

						Lua.pushvalue(luaInstance.lua, Lua.LUA_GLOBALSINDEX);
						while(Lua.next(luaInstance.lua, -2) != 0) {
							// key = -2
							// value = -1

							var pop:Int = 0;

							// Manual conversion
							// first we convert the key
							if(Lua.isnumber(luaInstance.lua,-2)){
								Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -2));
								pop++;
							}else if(Lua.isstring(luaInstance.lua,-2)){
								Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -2));
								pop++;
							}else if(Lua.isboolean(luaInstance.lua,-2)){
								Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -2));
								pop++;
							}
							// TODO: table


							// then the value
							if(Lua.isnumber(luaInstance.lua,-1)){
								Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
								pop++;
							}else if(Lua.isstring(luaInstance.lua,-1)){
								Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
								pop++;
							}else if(Lua.isboolean(luaInstance.lua,-1)){
								Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
								pop++;
							}
							// TODO: table

							if(pop==2)Lua.rawset(lua, tableIdx); // then set it
							Lua.pop(luaInstance.lua, 1); // for the loop
						}
						Lua.pop(luaInstance.lua,1); // end the loop entirely
						Lua.pushvalue(lua, tableIdx); // push the table onto the stack so it gets returned

						return;
					}

				}
			}
		});*/

		Lua_helper.add_callback(lua, "isRunning", function(luaFile:String)
		{
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
				for (luaInstance in luaArray)
					if (luaInstance.scriptName == foundScript)
						return true;
			return false;
		});

		Lua_helper.add_callback(lua, "setVar", function(varName:String, value:Dynamic)
		{
			game.variables.set(varName, value);
			return value;
		});
		Lua_helper.add_callback(lua, "getVar", function(varName:String)
		{
			return game.variables.get(varName);
		});

		Lua_helper.add_callback(lua, "addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{ // would be dope asf.
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (luaInstance in luaArray)
						if (luaInstance.scriptName == foundScript)
						{
							onLuaLog('addLuaScript: The script "' + foundScript + '" is already running!');
							return;
						}

				game.initLua(foundScript);
				return;
			}
			onError("addLuaScript: Script doesn't exist!");
		});
		Lua_helper.add_callback(lua, "addHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			#if HSCRIPT_ALLOWED
			var foundScript:String = findScript(luaFile, '.hx');
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (script in hscriptArray)
						if (script.origin == foundScript)
						{
							onLuaLog('addHScript: The script "' + foundScript + '" is already running!');
							return;
						}

				game.initHScript(foundScript);
				return;
			}
			onError("addHScript: Script doesn't exist!");
			#else
			onError("addHScript: HScript is not supported on this platform!");
			#end
		});
		Lua_helper.add_callback(lua, "removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			var foundScript:String = findScript(luaFile);
			if (foundScript != null)
			{
				if (!ignoreAlreadyRunning)
					for (luaInstance in luaArray)
						if (luaInstance.scriptName == foundScript)
						{
							luaInstance.stop();
							trace('Closing script ' + luaInstance.scriptName);
							return true;
						}
			}
			onError('removeLuaScript: Script $luaFile isn\'t running!');
			return false;
		});

		Lua_helper.add_callback(lua, "loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0)
		{
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = getObjectDirectly(split[0]);
			var animated = gridX != 0 || gridY != 0;

			if (split.length > 1)
			{
				spr = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			}
		});
		Lua_helper.add_callback(lua, "loadFrames", function(variable:String, image:String, spriteType:String = "sparrow")
		{
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && image != null && image.length > 0)
			{
				LuaUtils.loadFrames(spr, image, spriteType);
			}
		});

		// shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxBasic = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				return getTargetInstance().members.indexOf(leObj);
			}
			onError("getObjectOrder: Object " + obj + " doesn't exist!");
			return -1;
		});
		Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxBasic = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				getTargetInstance().remove(leObj, true);
				getTargetInstance().insert(position, leObj);
				return;
			}
			onError("setObjectOrder: Object " + obj + " doesn't exist!");
		});

		Lua_helper.add_callback(lua, "mouseClicked", function(button:String)
		{
			var click:Bool = FlxG.mouse.justPressed;
			switch (button)
			{
				case 'middle':
					click = FlxG.mouse.justPressedMiddle;
				case 'right':
					click = FlxG.mouse.justPressedRight;
			}
			return click;
		});
		Lua_helper.add_callback(lua, "mousePressed", function(button:String)
		{
			var press:Bool = FlxG.mouse.pressed;
			switch (button)
			{
				case 'middle':
					press = FlxG.mouse.pressedMiddle;
				case 'right':
					press = FlxG.mouse.pressedRight;
			}
			return press;
		});
		Lua_helper.add_callback(lua, "mouseReleased", function(button:String)
		{
			var released:Bool = FlxG.mouse.justReleased;
			switch (button)
			{
				case 'middle':
					released = FlxG.mouse.justReleasedMiddle;
				case 'right':
					released = FlxG.mouse.justReleasedRight;
			}
			return released;
		});

		// Identical functions
		Lua_helper.add_callback(lua, "FlxColor", function(color:String) return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromName", function(color:String) return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromString", function(color:String) return FlxColor.fromString(color));
		Lua_helper.add_callback(lua, "getColorFromHex", function(color:String) return FlxColor.fromString('#$color'));
		//

		Lua_helper.add_callback(lua, "getCharacterX", function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return game.dadGroup.x;
				case 'gf' | 'girlfriend':
					return game.gfGroup.x;
				default:
					return game.boyfriendGroup.x;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterX", function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					game.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.x = value;
				default:
					game.boyfriendGroup.x = value;
			}
		});
		Lua_helper.add_callback(lua, "getCharacterY", function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return game.dadGroup.y;
				case 'gf' | 'girlfriend':
					return game.gfGroup.y;
				default:
					return game.boyfriendGroup.y;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterY", function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					game.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.y = value;
				default:
					game.boyfriendGroup.y = value;
			}
		});

		Lua_helper.add_callback(lua, "getMouseX", function(camera:String)
		{
			var cam:FlxCamera = cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		Lua_helper.add_callback(lua, "getMouseY", function(camera:String)
		{
			var cam:FlxCamera = cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});

		Lua_helper.add_callback(lua, "getMidpointX", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getMidpointY", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "getGraphicMidpointX", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getGraphicMidpointY", function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "getScreenPositionX", function(variable:String, ?camera:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getScreenPositionY", function(variable:String, ?camera:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				obj = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "characterDance", function(character:String)
		{
			switch (character.toLowerCase())
			{
				case 'dad':
					game.dad.dance();
				case 'gf' | 'girlfriend':
					if (game.gf != null)
						game.gf.dance();
				default:
					game.boyfriend.dance();
			}
		});

		Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String = null, ?x:Float = 0, ?y:Float = 0)
		{
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}
			game.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});
		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite",
			function(tag:String, image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = "sparrow")
			{
				tag = tag.replace('.', '');
				resetSpriteTag(tag);
				var leSprite:ModchartSprite = new ModchartSprite(x, y);

				LuaUtils.loadFrames(leSprite, image, spriteType);
				game.modchartSprites.set(tag, leSprite);
			});

		Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF')
		{
			var spr:FlxSprite = getObjectDirectly(obj, false);
			if (spr != null)
				spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
		});

		Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true)
		{
			var obj:Dynamic = getObjectDirectly(obj, false);
			if (obj != null && obj.animation != null)
			{
				obj.animation.addByPrefix(name, prefix, framerate, loop);
				if (obj.animation.curAnim == null)
				{
					if (obj.playAnim != null)
						obj.playAnim(name, true);
					else
						obj.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true)
		{
			var obj:Dynamic = getObjectDirectly(obj, false);
			if (obj != null && obj.animation != null)
			{
				obj.animation.add(name, frames, framerate, loop);
				if (obj.animation.curAnim == null)
				{
					obj.animation.play(name, true);
				}
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "addAnimationByIndices",
			function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false)
			{
				return addAnimByIndices(obj, name, prefix, indices, framerate, loop);
			});

		Lua_helper.add_callback(lua, "playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
		{
			var obj:Dynamic = getObjectDirectly(obj, false);
			if (obj != null)
			{
				if (obj.playAnim != null)
				{
					obj.playAnim(name, forced, reverse, startFrame);
					return true;
				}
				else
				{
					obj.animation.play(name, forced, reverse, startFrame);
					return true;
				}
			}
			return false;
		});

		Lua_helper.add_callback(lua, "addOffset", function(obj:String, anim:String, x:Float, y:Float)
		{
			var obj:Dynamic = getObjectDirectly(obj, false);
			if (obj != null && obj.addOffset != null)
			{
				obj.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float)
		{
			if (game.getLuaObject(obj, false) != null)
			{
				var shit:FlxObject = game.getLuaObject(obj, false);
				shit.scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(getTargetInstance(), obj);
			if (object != null)
			{
				object.scrollFactor.set(scrollX, scrollY);
			}
		});

		Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, front:Bool = false)
		{
			if (game.modchartSprites.exists(tag))
			{
				final shit:ModchartSprite = game.modchartSprites.get(tag);
				addObject(shit, front);
			}
		});

		Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true)
		{
			if (game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.setGraphicSize(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				poop = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null)
			{
				poop.setGraphicSize(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			onError('setGraphicSize: Couldnt find object: ' + obj);
		});

		Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true)
		{
			if (game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.scale.set(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				poop = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}

			if (poop != null)
			{
				poop.scale.set(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			onError('scaleObject: Couldnt find object: ' + obj);
		});

		Lua_helper.add_callback(lua, "updateHitbox", function(obj:String)
		{
			if (game.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = game.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getTargetInstance(), obj);
			if (poop != null)
			{
				poop.updateHitbox();
				return;
			}
			onError('updateHitbox: Couldnt find object: ' + obj);
		});

		Lua_helper.add_callback(lua, "updateHitboxFromGroup", function(group:String, index:Int)
		{
			if (Std.isOfType(Reflect.getProperty(getTargetInstance(), group), FlxTypedGroup))
			{
				Reflect.getProperty(getTargetInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(getTargetInstance(), group)[index].updateHitbox();
		});

		Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String, destroy:Bool = true)
		{
			if (!game.modchartSprites.exists(tag))
			{
				return;
			}

			var pee:ModchartSprite = game.modchartSprites.get(tag);
			if (destroy)
			{
				pee.kill();
			}

			getTargetInstance().remove(pee, true);
			if (destroy)
			{
				pee.destroy();
				game.modchartSprites.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "luaSpriteExists", function(tag:String)
		{
			return game.modchartSprites.exists(tag);
		});

		Lua_helper.add_callback(lua, "luaTextExists", function(tag:String)
		{
			return game.modchartTexts.exists(tag);
		});

		Lua_helper.add_callback(lua, "setObjectCamera", function(obj:String, camera:String = '')
		{
			var real:FlxSprite = game.getLuaObject(obj);
			if (real != null)
			{
				real.cameras = [cameraFromString(camera)];
				return true;
			}

			var split:Array<String> = obj.split('.');
			var object:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				object = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}

			if (object != null)
			{
				object.cameras = [cameraFromString(camera)];
				return true;
			}
			onError("setObjectCamera: Object " + obj + " doesn't exist!");
			return false;
		});

		Lua_helper.add_callback(lua, "setBlendMode", function(obj:String, blend:String = '')
		{
			var real:FlxSprite = game.getLuaObject(obj);
			if (real != null)
			{
				real.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}

			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null)
			{
				spr.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}
			onError("setBlendMode: Object " + obj + " doesn't exist!");
			return false;
		});

		Lua_helper.add_callback(lua, "screenCenter", function(obj:String, pos:String = 'xy')
		{
			var spr:FlxSprite = game.getLuaObject(obj);

			if (spr == null)
			{
				var split:Array<String> = obj.split('.');
				spr = getObjectDirectly(split[0]);
				if (split.length > 1)
				{
					spr = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
				}
			}

			if (spr != null)
			{
				switch (pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
						return;
					case 'y':
						spr.screenCenter(Y);
						return;
					default:
						spr.screenCenter(XY);
						return;
				}
			}
			onError("screenCenter: Object " + obj + " doesn't exist!");
		});

		Lua_helper.add_callback(lua, "objectsOverlap", function(obj1:String, obj2:String)
		{
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length)
			{
				var real:FlxSprite = game.getLuaObject(namesArray[i]);
				if (real != null)
				{
					objectsArray.push(real);
				}
				else
				{
					objectsArray.push(Reflect.getProperty(getTargetInstance(), namesArray[i]));
				}
			}

			if (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
			{
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getPixelColor", function(obj:String, x:Int, y:Int)
		{
			var split:Array<String> = obj.split('.');
			var spr:FlxSprite = getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = getVarInArray(getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null)
				return spr.pixels.getPixel32(x, y);
			return FlxColor.BLACK;
		});

		Lua_helper.add_callback(lua, "debugPrint",
			function(text:Dynamic = '', color:String = 'WHITE') game.addTextToDebug(text, CoolUtil.colorFromString(color)));

		addLocalCallback("close", function()
		{
			closed = true;
			trace('Closing script $scriptName');
			return closed;
		});

		#if desktop DiscordClient.addLuaCallbacks(lua); #end
		#if SScript HScript.implement(this); #end
		ReflectionFunctions.implement(this);
		TextFunctions.implement(this);
		ExtraFunctions.implement(this);
		ShaderFunctions.implement(this);
		DeprecatedFunctions.implement(this);
	}

	function loadFile()
	{
		try
		{
			var result:Dynamic = LuaL.dofile(lua, scriptName);
			var resultStr:String = Lua.tostring(lua, result);
			if (resultStr != null && result != 0)
			{
				trace(resultStr);
				#if windows
				lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
				#else
				onLoadError(resultStr);
				#end
				lua = null;
				return;
			}
		}
		catch (e:Dynamic)
		{
			trace(e);
			return;
		}

		trace('lua file loaded succesfully:' + scriptName);

		call('onCreate', []);
	}

	function findScript(scriptFile:String, ext:String = '.lua')
	{
		if (!scriptFile.endsWith(ext))
			scriptFile += ext;
		var preloadPath:String = Paths.getPreloadPath(scriptFile);
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(scriptFile);
		if (FileSystem.exists(scriptFile))
			return scriptFile;
		else if (FileSystem.exists(path))
			return path;

		if (FileSystem.exists(preloadPath))
		#else
		if (Assets.exists(preloadPath))
		#end
		{
			return preloadPath;
		}
		return null;
	}

	function onLoadError(msg:String)
	{
		game.addTextToDebug('$scriptName\n$msg', FlxColor.RED);
		trace(msg);
	}
}
