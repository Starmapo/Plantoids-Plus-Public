package psychlua;

import flixel.FlxBasic;
import objects.Character;
#if HSCRIPT_ALLOWED
import tea.SScript;

class BaseHScript extends SScript
{
	public static function initHaxeModule(parent:BaseLua)
	{
		if (parent.hscript == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.initHaxeModule();
		}
	}

	public static function initHaxeModuleCode(parent:BaseLua, code:String)
	{
		if (parent.hscript == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.initHaxeModule(code);
		}
	}

	public static function implement(funk:BaseLua)
	{
		#if LUA_ALLOWED
		funk.addLocalCallback("runHaxeCode",
			function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic
			{
				var retVal:TeaCall = null;
				#if SScript
				initHaxeModuleCode(funk, codeToRun);
				if (varsToBring != null)
				{
					for (key in Reflect.fields(varsToBring))
					{
						// trace('Key $key: ' + Reflect.field(varsToBring, key));
						funk.hscript.set(key, Reflect.field(varsToBring, key));
					}
				}
				retVal = funk.hscript.executeCode(funcToRun, funcArgs);
				if (retVal != null)
				{
					if (retVal.succeeded)
						return (retVal.returnValue == null
							|| LuaUtils.isOfTypes(retVal.returnValue, [Bool, Int, Float, String, Array])) ? retVal.returnValue : null;

					var e = retVal.exceptions[0];
					if (e != null)
						funk.onError(funk.hscript.origin + ":" + funk.lastCalledFunction + " - " + e);
					return null;
				}
				else if (funk.hscript.returnValue != null)
					return funk.hscript.returnValue;
				#else
				funk.onError("runHaxeCode: HScript isn't supported on this platform!");
				#end
				return null;
			});

		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null)
		{
			#if SScript
			var callValue = funk.hscript.executeFunction(funcToRun, funcArgs);
			if (!callValue.succeeded)
			{
				var e = callValue.exceptions[0];
				if (e != null)
					funk.onError('ERROR (${funk.hscript.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n')));
				return null;
			}
			else
				return callValue.returnValue;
			#else
			funk.onError("runHaxeFunction: HScript isn't supported on this platform!");
			#end
		});
		// This function is unnecessary because import already exists in SScript as a native feature
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '')
		{
			var str:String = '';
			if (libPackage.length > 0)
				str = libPackage + '.';
			else if (libName == null)
				libName = '';

			var c = Type.resolveClass(str + libName);

			#if SScript
			if (c != null)
				SScript.globalVariables[libName] = c;
			#end

			#if SScript
			if (funk.hscript != null)
			{
				try
				{
					if (c != null)
						funk.hscript.set(libName, c);
				}
				catch (e:Dynamic)
				{
					funk.onError(funk.hscript.origin + ":" + funk.lastCalledFunction + " - " + e);
				}
			}
			#else
			funk.onError("addHaxeLibrary: HScript isn't supported on this platform!");
			#end
		});
		#end
	}

	public var parentLua:BaseLua;
	public var origin:String;
	public var game(default, null):IScriptState;

	public function new(?parent:BaseLua, ?file:String)
	{
		if (file == null)
			file = '';

		super(file, false, false);
		parentLua = parent;
		if (parent != null)
			origin = parent.scriptName;
		if (scriptFile != null && scriptFile.length > 0)
			origin = scriptFile;
		game = cast MusicBeatState.getState();

		preset();
		execute();
	}

	override function preset()
	{
		super.preset();

		// Some very commonly used classes
		set('FlxG', flixel.FlxG);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxCamera', flixel.FlxCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxColor', CustomFlxColor);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', objects.Note);
		set('CustomSubstate', CustomSubstate);
		set('Countdown', backend.BaseStage.Countdown);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);

		set('setVar', function(name:String, value:Dynamic)
		{
			game.variables.set(name, value);
		});
		set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if (game.variables.exists(name))
				result = game.variables.get(name);
			return result;
		});
		set('removeVar', function(name:String)
		{
			if (game.variables.exists(name))
			{
				game.variables.remove(name);
				return true;
			}
			return false;
		});

		// tested
		set('createCallback', function(name:String, func:Dynamic, ?funk:BaseLua = null)
		{
			if (funk == null)
				funk = parentLua;

			if (parentLua != null)
				funk.addLocalCallback(name, func);
			else
				funk.onError('createCallback ($name): 3rd argument is null');
		});

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '')
		{
			try
			{
				var str:String = '';
				if (libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic)
			{
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));
				if (parentLua != null)
				{
					BaseLua.lastCalledScript = parentLua;
					msg = origin + ":" + parentLua.lastCalledFunction + " - " + msg;
				}
				else
					msg = '$origin - $msg';
				parentLua.onError(msg, true);
			}
		});

		set('parentLua', parentLua);
		set('this', this);
		set('game', game);
		set('buildTarget', FunkinLua.getBuildTarget());

		set('Function_Stop', FunkinLua.Function_Stop);
		set('Function_Continue', FunkinLua.Function_Continue);
		set('Function_StopLua', FunkinLua.Function_StopLua); // doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', FunkinLua.Function_StopHScript);
		set('Function_StopAll', FunkinLua.Function_StopAll);

		set('add', function(obj:FlxBasic) game.add(obj));
		set('addBehindGF', function(obj:FlxBasic) game.addBehindGF(obj));
		set('addBehindDad', function(obj:FlxBasic) game.addBehindDad(obj));
		set('addBehindBF', function(obj:FlxBasic) game.addBehindBF(obj));
		set('insert', function(pos:Int, obj:FlxBasic) game.insert(pos, obj));
		set('remove', function(obj:FlxBasic, splice:Bool = false) game.remove(obj, splice));
	}

	override public function destroy()
	{
		origin = null;
		parentLua = null;

		super.destroy();
	}

	public function executeCode(?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):TeaCall
	{
		if (funcToRun == null)
			return null;

		if (!exists(funcToRun))
		{
			onError(origin + ' - No HScript function named: $funcToRun');
			return null;
		}

		var callValue = call(funcToRun, funcArgs);
		if (!callValue.succeeded)
		{
			var e = callValue.exceptions[0];
			if (e != null)
			{
				var msg:String = e.toString();
				if (parentLua != null)
					msg = origin + ":" + parentLua.lastCalledFunction + " - " + msg;
				else
					msg = '$origin - $msg';
				onError(msg, parentLua == null);
			}
			return null;
		}
		return callValue;
	}

	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>):TeaCall
	{
		if (funcToRun == null)
			return null;

		return call(funcToRun, funcArgs);
	}

	public function onError(msg:String, important:Bool = false)
	{
		trace(msg);
	}
}

class CustomFlxColor
{
	public static var TRANSPARENT(default, null):Int = FlxColor.TRANSPARENT;
	public static var BLACK(default, null):Int = FlxColor.BLACK;
	public static var WHITE(default, null):Int = FlxColor.WHITE;
	public static var GRAY(default, null):Int = FlxColor.GRAY;

	public static var GREEN(default, null):Int = FlxColor.GREEN;
	public static var LIME(default, null):Int = FlxColor.LIME;
	public static var YELLOW(default, null):Int = FlxColor.YELLOW;
	public static var ORANGE(default, null):Int = FlxColor.ORANGE;
	public static var RED(default, null):Int = FlxColor.RED;
	public static var PURPLE(default, null):Int = FlxColor.PURPLE;
	public static var BLUE(default, null):Int = FlxColor.BLUE;
	public static var BROWN(default, null):Int = FlxColor.BROWN;
	public static var PINK(default, null):Int = FlxColor.PINK;
	public static var MAGENTA(default, null):Int = FlxColor.MAGENTA;
	public static var CYAN(default, null):Int = FlxColor.CYAN;

	public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int
	{
		return cast FlxColor.fromRGB(Red, Green, Blue, Alpha);
	}

	public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int
	{
		return cast FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);
	}

	public static function fromHSB(Hue:Float, Sat:Float, Brt:Float, Alpha:Float = 1):Int
	{
		return cast FlxColor.fromHSB(Hue, Sat, Brt, Alpha);
	}

	public static function fromHSL(Hue:Float, Sat:Float, Light:Float, Alpha:Float = 1):Int
	{
		return cast FlxColor.fromHSL(Hue, Sat, Light, Alpha);
	}

	public static function fromString(str:String):Int
	{
		return cast FlxColor.fromString(str);
	}
}
#end
