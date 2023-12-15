package psychlua;

import psychlua.CustomSubstate;
import psychlua.FunkinLua;

#if HSCRIPT_ALLOWED
class HScript extends BaseHScript
{
	public static function initHaxeModule(parent:BaseLua)
	{
		BaseHScript.initHaxeModule(parent);
	}

	public static function initHaxeModuleCode(parent:BaseLua, code:String)
	{
		BaseHScript.initHaxeModuleCode(parent, code);
	}

	override function preset()
	{
		super.preset();

		// Functions & Variables
		set('debugPrint', function(text:String, ?color:FlxColor = null)
		{
			if (color == null)
				color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});

		// For adding your own callbacks

		// not very tested but should work
		set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if (script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});

		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);
	}

	override function onError(msg:String, important:Bool = false)
	{
		FunkinLua.luaTrace(msg, important, false, FlxColor.RED);
	}

	public static function implement(funk:BaseLua)
	{
		BaseHScript.implement(funk);
	}
}
#end
