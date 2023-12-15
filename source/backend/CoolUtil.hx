package backend;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import haxe.io.Path;
#if (sys && MODS_ALLOWED)
import sys.FileSystem;
import sys.io.File;
#else
import openfl.utils.Assets;
#end

class CoolUtil
{
	inline public static function quantize(f:Float, snap:Float)
	{
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		trace(snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		var formatted:Array<String> = path.split(':'); // prevent "shared:", "preload:" and other library names on file path
		path = formatted[formatted.length - 1];
		if (FileSystem.exists(path))
			daList = File.getContent(path);
		#else
		if (Assets.exists(path))
			daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x'))
			color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null)
			colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
						countByColor[colorOfThisPixel] = 1;
				}
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key in countByColor.keys())
		{
			if (countByColor[key] >= maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
			dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	/** Quick Function to Fix Save Files for Flixel 5
		@BeastlyGabi
	**/
	inline public static function getSavePath(folder:String = 'AdvenTeam'):String
	{
		return FlxG.stage.application.meta.get('company');
	}

	/**
	 * Replacement for `FlxG.mouse.overlaps` because it's currently broken when using a camera with a different position or size.
	 * It will be fixed eventually by HaxeFlixel v5.4.0.
	 * 
	 * @param 	objectOrGroup The object or group being tested.
	 * @param 	camera Specify which game camera you want. If null getScreenPosition() will just grab the first global camera.
	 * @return 	Whether or not the two objects overlap.
	 */
	@:access(flixel.group.FlxTypedGroup.resolveGroup)
	inline public static function mouseOverlaps(objectOrGroup:FlxBasic, ?camera:FlxCamera):Bool
	{
		var result:Bool = false;

		final group = FlxTypedGroup.resolveGroup(objectOrGroup);
		if (group != null)
		{
			group.forEachExists(function(basic:FlxBasic)
			{
				if (mouseOverlaps(basic, camera))
				{
					result = true;
					return;
				}
			});
		}
		else
		{
			final point = FlxG.mouse.getWorldPosition(camera, FlxPoint.weak());
			final object:FlxObject = cast objectOrGroup;
			result = object.overlapsPoint(point, true, camera);
		}

		return result;
	}

	public static function getImageOrPlaceholder(folder:String, name:String, placeholder:String, ?library:String = null, ?allowGPU:Bool = true)
	{
		return Paths.image(getImageOrPlaceholderPath(folder, name, placeholder, library), library, allowGPU);
	}

	public static function getImageOrPlaceholderPath(folder:String, name:String, placeholder:String, ?library:String = null)
	{
		var path = Path.join([folder, name]);
		if (!Paths.fileExists('images/$path.png', IMAGE, false, library))
			path = Path.join([folder, placeholder]);

		return path;
	}
}
