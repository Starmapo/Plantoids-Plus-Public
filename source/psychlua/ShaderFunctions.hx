package psychlua;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

class ShaderFunctions
{
	public static function implement(funk:BaseLua)
	{
		var lua = funk.lua;
		// shader shit
		funk.addLocalCallback("initLuaShader", function(name:String, ?glslVersion:Int = 120)
		{
			if (!ClientPrefs.data.shaders)
				return false;

			#if (!flash && MODS_ALLOWED && sys)
			return funk.initLuaShader(name, glslVersion);
			#else
			funk.onError("initLuaShader: Platform unsupported for Runtime Shaders!");
			#end
			return false;
		});

		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String)
		{
			if (!ClientPrefs.data.shaders)
				return false;

			#if (!flash && MODS_ALLOWED && sys)
			if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
			{
				funk.onError('setSpriteShader: Shader $shader is missing!');
				return false;
			}

			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = funk.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = funk.getVarInArray(funk.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				var arr:Array<String> = funk.runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
				return true;
			}
			#else
			funk.onError("setSpriteShader: Platform unsupported for Runtime Shaders!");
			#end
			return false;
		});
		Lua_helper.add_callback(lua, "removeSpriteShader", function(obj:String)
		{
			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = funk.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				leObj = funk.getVarInArray(funk.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null)
			{
				leObj.shader = null;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getShaderBool", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if (shader == null)
			{
				funk.onError("getShaderBool: Shader is not FlxRuntimeShader!");
				return null;
			}
			return shader.getBool(prop);
			#else
			funk.onError("getShaderBool: Platform unsupported for Runtime Shaders!");
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("getShaderBoolArray: Shader is not FlxRuntimeShader!");
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			funk.onError("getShaderBoolArray: Platform unsupported for Runtime Shaders!");
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("getShaderInt: Shader is not FlxRuntimeShader!");
				return null;
			}
			return shader.getInt(prop);
			#else
			funk.onError("getShaderInt: Platform unsupported for Runtime Shaders!");
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("getShaderIntArray: Shader is not FlxRuntimeShader!");
				return null;
			}
			return shader.getIntArray(prop);
			#else
			funk.onError("getShaderIntArray: Platform unsupported for Runtime Shaders!");
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("getShaderFloat: Shader is not FlxRuntimeShader!");
				return null;
			}
			return shader.getFloat(prop);
			#else
			funk.onError("getShaderFloat: Platform unsupported for Runtime Shaders!");
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("getShaderFloatArray: Shader is not FlxRuntimeShader!");
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			funk.onError("getShaderFloatArray: Platform unsupported for Runtime Shaders!");
			return null;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("setShaderBool: Shader is not FlxRuntimeShader!");
				return false;
			}
			shader.setBool(prop, value);
			return true;
			#else
			funk.onError("setShaderBool: Platform unsupported for Runtime Shaders!");
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("setShaderBoolArray: Shader is not FlxRuntimeShader!");
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
			#else
			funk.onError("setShaderBoolArray: Platform unsupported for Runtime Shaders!");
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("setShaderInt: Shader is not FlxRuntimeShader!");
				return false;
			}
			shader.setInt(prop, value);
			return true;
			#else
			funk.onError("setShaderInt: Platform unsupported for Runtime Shaders!");
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("setShaderIntArray: Shader is not FlxRuntimeShader!");
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
			#else
			funk.onError("setShaderIntArray: Platform unsupported for Runtime Shaders!");
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("setShaderFloat: Shader is not FlxRuntimeShader!");
				return false;
			}
			shader.setFloat(prop, value);
			return true;
			#else
			funk.onError("setShaderFloat: Platform unsupported for Runtime Shaders!");
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("setShaderFloatArray: Shader is not FlxRuntimeShader!");
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			funk.onError("setShaderFloatArray: Platform unsupported for Runtime Shaders!");
			return true;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String)
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				funk.onError("setShaderSampler2D: Shader is not FlxRuntimeShader!");
				return false;
			}

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.image(bitmapdataPath);
			if (value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			return false;
			#else
			funk.onError("setShaderSampler2D: Platform unsupported for Runtime Shaders!");
			return false;
			#end
		});
	}

	#if (!flash && sys)
	public static function getShader(obj:String):FlxRuntimeShader
	{
		var split:Array<String> = obj.split('.');
		var target:FlxSprite = null;
		if (split.length > 1)
			target = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
		else
			target = LuaUtils.getObjectDirectly(split[0]);

		if (target == null)
		{
			FunkinLua.luaTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
			return null;
		}
		return cast(target.shader, FlxRuntimeShader);
	}
	#end
}
