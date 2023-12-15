package backend;

import objects.HealthBar;
import sys.FileSystem;
import sys.io.File;
import tjson.TJSON as Json;

typedef UIFile =
{
	var countdownPrefix:String;
	var countdownSuffix:String;
	var ?countdownScale:Float;
	var ?countdownAntialiasing:Bool;
	var ?countdownThree:Bool;
	var countdownSoundsSuffix:String;
	var ratingsPrefix:String;
	var ratingsSuffix:String;
	var ?ratingsScale:Float;
	var ?ratingsAntialiasing:Bool;
	var comboPrefix:String;
	var comboSuffix:String;
	var ?comboScale:Float;
	var ?comboAntialiasing:Bool;
	var numPrefix:String;
	var numSuffix:String;
	var ?numScale:Float;
	var ?numAntialiasing:Bool;
	var healthBarBG:String;
	var ?healthBarBGUnder:Bool;
	var healthBarImage:String;
	var healthBarOffset:Array<Float>;
	var healthBarDownscrollOffset:Array<Float>;
	var healthBarSpacing:Array<Float>;
	var ?healthBarWidth:Int;
	var ?healthBarHeight:Int;
	var ?healthBarScale:Bool;
	var timeBarBG:String;
	var ?timeBarBGUnder:Bool;
	var timeBarImage:String;
	var timeBarOffset:Array<Float>;
	var timeBarDownscrollOffset:Array<Float>;
	var timeBarSpacing:Array<Float>;
	var ?timeBarWidth:Int;
	var ?timeBarHeight:Int;
	var ?timeBarScale:Bool;
	var timeBarFont:String;
	var songSign:String;

	var ?name:String;
}

class UIData
{
	public static final DEFAULT_SONG_SIGN:String = "plantoids_songSign";
	public static final DEFAULT_HEALTH_BAR:String = "healthBar";
	public static final DEFAULT_TIME_BAR:String = "timeBar";

	public static function getUIFile(name:String):UIFile
	{
		if (name == null || name.length < 1)
			return null;

		var rawJson:String = null;
		var path:String = Paths.getPreloadPath('ui/' + name + '.json');

		var modPath:String = Paths.modFolders('ui/' + name + '.json');
		if (FileSystem.exists(modPath))
			rawJson = File.getContent(modPath);
		else if (FileSystem.exists(path))
			rawJson = File.getContent(path);
		else
			return null;

		var file:UIFile = Json.parse(rawJson);
		file.name = name;
		if (file.countdownPrefix == null)
			file.countdownPrefix = '';
		if (file.countdownSuffix == null)
			file.countdownSuffix = '';
		if (file.countdownScale == null)
			file.countdownScale = 1;
		if (file.countdownAntialiasing == null)
			file.countdownAntialiasing = true;
		if (file.countdownThree == null)
			file.countdownThree = false;
		if (file.countdownSoundsSuffix == null)
			file.countdownSoundsSuffix = '';
		if (file.ratingsPrefix == null)
			file.ratingsPrefix = '';
		if (file.ratingsSuffix == null)
			file.ratingsSuffix = '';
		if (file.ratingsScale == null)
			file.ratingsScale = 0.7;
		if (file.ratingsAntialiasing == null)
			file.ratingsAntialiasing = true;
		if (file.comboPrefix == null)
			file.comboPrefix = '';
		if (file.comboSuffix == null)
			file.comboSuffix = '';
		if (file.comboScale == null)
			file.comboScale = 0.7;
		if (file.comboAntialiasing == null)
			file.comboAntialiasing = true;
		if (file.numPrefix == null)
			file.numPrefix = '';
		if (file.numSuffix == null)
			file.numSuffix = '';
		if (file.numScale == null)
			file.numScale = 0.5;
		if (file.numAntialiasing == null)
			file.numAntialiasing = true;
		if (file.healthBarBG == null)
			file.healthBarBG = DEFAULT_HEALTH_BAR;
		if (file.healthBarBGUnder == null)
			file.healthBarBGUnder = false;
		if (file.healthBarImage == null)
			file.healthBarImage = '';
		if (file.healthBarOffset == null)
			file.healthBarOffset = [0, 0];
		if (file.healthBarSpacing == null)
			file.healthBarSpacing = [3, 3];
		if (file.healthBarScale == null)
			file.healthBarScale = true;
		if (file.timeBarBG == null)
			file.timeBarBG = DEFAULT_TIME_BAR;
		if (file.timeBarBGUnder == null)
			file.timeBarBGUnder = false;
		if (file.timeBarImage == null)
			file.timeBarImage = '';
		if (file.timeBarOffset == null)
			file.timeBarOffset = [0, 0];
		if (file.timeBarSpacing == null)
			file.timeBarSpacing = [3, 3];
		if (file.timeBarScale == null)
			file.timeBarScale = true;
		if (file.timeBarFont == null)
			file.timeBarFont = '';
		if (file.songSign == null)
			file.songSign = DEFAULT_SONG_SIGN;

		return file;
	}

	public static function applyToBar(bar:HealthBar, ?spacing:Array<Float>, ?scale:Bool, ?barWidth:Int, ?barHeight:Int)
	{
		if (spacing != null)
			bar.barOffset.set(spacing[0], spacing[1]);

		if (scale != null)
			bar.barScale = scale;

		if (barWidth != null)
			bar.barWidth = barWidth;
		else if (scale)
			bar.barWidth = Std.int(bar.bg.width - bar.barOffset.x * 2);
		else
			bar.barWidth = Std.int(bar.leftBar.width);

		if (barHeight != null)
			bar.barHeight = barHeight;
		else if (scale)
			bar.barHeight = Std.int(bar.bg.height - bar.barOffset.y * 2);
		else
			bar.barHeight = Std.int(bar.leftBar.height);
	}

	public static function getUIList():Array<String>
	{
		final directories = Paths.getDirectories('ui');

		final tempArray:Array<String> = [];
		final uiSkins:Array<String> = [''];
		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			final directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					final path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						final uiToCheck:String = file.substr(0, file.length - 5);
						if (uiToCheck.trim().length > 0 && !tempArray.contains(uiToCheck))
						{
							tempArray.push(uiToCheck);
							uiSkins.push(uiToCheck);
						}
					}
				}
			}
		}
		#end

		return uiSkins;
	}
}
