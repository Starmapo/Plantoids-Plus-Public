package psychlua;

//
// This is simply where i store deprecated functions for it to be more organized.
// I would suggest not messing with these, as it could break mods.
//
class DeprecatedFunctions
{
	public static function implement(funk:BaseLua)
	{
		var lua:State = funk.lua;
		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		Lua_helper.add_callback(lua, "addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24)
		{
			funk.warnDeprecated("addAnimationByIndicesLoop is deprecated! Use addAnimationByIndices instead");
			return funk.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		Lua_helper.add_callback(lua, "objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0)
		{
			funk.warnDeprecated("objectPlayAnimation is deprecated! Use playAnim instead");
			if (funk.game.getLuaObject(obj, false) != null)
			{
				funk.game.getLuaObject(obj, false).animation.play(name, forced, false, startFrame);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(funk.getTargetInstance(), obj);
			if (spr != null)
			{
				spr.animation.play(name, forced, false, startFrame);
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false)
		{
			funk.warnDeprecated("characterPlayAnim is deprecated! Use playAnim instead");
			switch (character.toLowerCase())
			{
				case 'dad':
					if (funk.game.dad.animOffsets.exists(anim))
						funk.game.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if (funk.game.gf != null && funk.game.gf.animOffsets.exists(anim))
						funk.game.gf.playAnim(anim, forced);
				default:
					if (funk.game.boyfriend.animOffsets.exists(anim))
						funk.game.boyfriend.playAnim(anim, forced);
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String)
		{
			funk.warnDeprecated("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead");
			if (funk.game.modchartSprites.exists(tag))
				funk.game.modchartSprites.get(tag).makeGraphic(width, height, CoolUtil.colorFromString(color));
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true)
		{
			funk.warnDeprecated("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead");
			if (funk.game.modchartSprites.exists(tag))
			{
				var cock:ModchartSprite = funk.game.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)
				{
					cock.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24)
		{
			funk.warnDeprecated("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead");
			if (funk.game.modchartSprites.exists(tag))
			{
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length)
				{
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:ModchartSprite = funk.game.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null)
				{
					pussy.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false)
		{
			funk.warnDeprecated("luaSpritePlayAnimation is deprecated! Use playAnim instead");
			if (funk.game.modchartSprites.exists(tag))
			{
				funk.game.modchartSprites.get(tag).animation.play(name, forced);
			}
		});
		Lua_helper.add_callback(lua, "setLuaSpriteCamera", function(tag:String, camera:String = '')
		{
			funk.warnDeprecated("setLuaSpriteCamera is deprecated! Use setObjectCamera instead");
			if (funk.game.modchartSprites.exists(tag))
			{
				funk.game.modchartSprites.get(tag).cameras = [funk.cameraFromString(camera)];
				return true;
			}
			funk.onLuaLog("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float)
		{
			funk.warnDeprecated("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead");
			if (funk.game.modchartSprites.exists(tag))
			{
				funk.game.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "scaleLuaSprite", function(tag:String, x:Float, y:Float)
		{
			funk.warnDeprecated("scaleLuaSprite is deprecated! Use scaleObject instead");
			if (funk.game.modchartSprites.exists(tag))
			{
				var shit:ModchartSprite = funk.game.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getPropertyLuaSprite", function(tag:String, variable:String)
		{
			funk.warnDeprecated("getPropertyLuaSprite is deprecated! Use getProperty instead");
			if (funk.game.modchartSprites.exists(tag))
			{
				var killMe:Array<String> = variable.split('.');
				if (killMe.length > 1)
				{
					var coverMeInPiss:Dynamic = Reflect.getProperty(funk.game.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length - 1)
					{
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
				}
				return Reflect.getProperty(funk.game.modchartSprites.get(tag), variable);
			}
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic)
		{
			funk.warnDeprecated("setPropertyLuaSprite is deprecated! Use setProperty instead");
			if (funk.game.modchartSprites.exists(tag))
			{
				var killMe:Array<String> = variable.split('.');
				if (killMe.length > 1)
				{
					var coverMeInPiss:Dynamic = Reflect.getProperty(funk.game.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length - 1)
					{
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
					return true;
				}
				Reflect.setProperty(funk.game.modchartSprites.get(tag), variable, value);
				return true;
			}
			funk.onLuaLog("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
	}
}
