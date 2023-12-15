package psychlua;

class TextFunctions
{
	public static function implement(funk:BaseLua)
	{
		var lua = funk.lua;
		var game:Dynamic = funk.game;
		Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float)
		{
			tag = tag.replace('.', '');
			funk.resetTextTag(tag);
			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			leText.cameras = [game.camHUD];
			leText.scrollFactor.set();
			leText.borderSize = 2;
			game.modchartTexts.set(tag, leText);
		});

		Lua_helper.add_callback(lua, "setTextString", function(tag:String, text:String)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				obj.text = text;
				return true;
			}
			funk.onError("setTextString: Object " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setTextSize", function(tag:String, size:Int)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				obj.size = size;
				return true;
			}
			funk.onError("setTextSize: Object " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setTextWidth", function(tag:String, width:Float)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				obj.fieldWidth = width;
				return true;
			}
			funk.onError("setTextWidth: Object " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setTextBorder", function(tag:String, size:Int, color:String)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				if (size > 0)
				{
					obj.borderStyle = OUTLINE;
					obj.borderSize = size;
				}
				else
					obj.borderStyle = NONE;
				obj.borderColor = CoolUtil.colorFromString(color);
				return true;
			}
			funk.onError("setTextBorder: Object " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setTextColor", function(tag:String, color:String)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				obj.color = CoolUtil.colorFromString(color);
				return true;
			}
			funk.onError("setTextColor: Object " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setTextFont", function(tag:String, newFont:String)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				obj.font = Paths.font(newFont);
				return true;
			}
			funk.onError("setTextFont: Object " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setTextItalic", function(tag:String, italic:Bool)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				obj.italic = italic;
				return true;
			}
			funk.onError("setTextItalic: Object " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setTextAlignment", function(tag:String, alignment:String = 'left')
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				obj.alignment = LEFT;
				switch (alignment.trim().toLowerCase())
				{
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
				}
				return true;
			}
			funk.onError("setTextAlignment: Object " + tag + " doesn't exist!");
			return false;
		});

		Lua_helper.add_callback(lua, "getTextString", function(tag:String)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null && obj.text != null)
			{
				return obj.text;
			}
			funk.onError("getTextString: Object " + tag + " doesn't exist!");
			return null;
		});
		Lua_helper.add_callback(lua, "getTextSize", function(tag:String)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				return obj.size;
			}
			funk.onError("getTextSize: Object " + tag + " doesn't exist!");
			return -1;
		});
		Lua_helper.add_callback(lua, "getTextFont", function(tag:String)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				return obj.font;
			}
			funk.onError("getTextFont: Object " + tag + " doesn't exist!");
			return null;
		});
		Lua_helper.add_callback(lua, "getTextWidth", function(tag:String)
		{
			var obj:FlxText = funk.getTextObject(tag);
			if (obj != null)
			{
				return obj.fieldWidth;
			}
			funk.onError("getTextWidth: Object " + tag + " doesn't exist!");
			return 0;
		});

		Lua_helper.add_callback(lua, "addLuaText", function(tag:String)
		{
			if (game.modchartTexts.exists(tag))
			{
				var shit:FlxText = game.modchartTexts.get(tag);
				funk.getTargetInstance().add(shit);
			}
		});
		Lua_helper.add_callback(lua, "removeLuaText", function(tag:String, destroy:Bool = true)
		{
			if (!game.modchartTexts.exists(tag))
			{
				return;
			}

			var pee:FlxText = game.modchartTexts.get(tag);
			if (destroy)
			{
				pee.kill();
			}

			funk.getTargetInstance().remove(pee, true);
			if (destroy)
			{
				pee.destroy();
				game.modchartTexts.remove(tag);
			}
		});
	}
}
