package backend;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#else
import openfl.utils.Assets;
#end
import backend.Song;
import tjson.TJSON as Json;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;
	var isPixelStage:Bool;
	var stageUI:String;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;
	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;
}

class StageData
{
	public static function dummy():StageFile
	{
		return {
			directory: "",
			defaultZoom: 0.9,
			isPixelStage: false,
			stageUI: "normal",

			boyfriend: [770, 100],
			girlfriend: [400, 130],
			opponent: [100, 100],
			hide_girlfriend: false,

			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1
		};
	}

	public static var forceNextDirectory:String = null;

	public static function loadDirectory(SONG:SwagSong)
	{
		var stage:String = '';
		if (SONG.stage != null)
		{
			stage = SONG.stage;
		}
		else if (SONG.song != null)
		{
			stage = vanillaSongStage(Paths.formatToSongPath(SONG.song));
		}
		else
		{
			stage = 'stage';
		}

		var stageFile:StageFile = getStageFile(stage);
		if (stageFile == null) // preventing crashes
		{
			forceNextDirectory = '';
		}
		else
		{
			forceNextDirectory = stageFile.directory;
		}
	}

	public static function getStageFile(stage:String):StageFile
	{
		var rawJson:String = null;
		var path:String = Paths.getPreloadPath('stages/' + stage + '.json');

		#if MODS_ALLOWED
		var modPath:String = Paths.modFolders('stages/' + stage + '.json');
		if (FileSystem.exists(modPath))
		{
			rawJson = File.getContent(modPath);
		}
		else if (FileSystem.exists(path))
		{
			rawJson = File.getContent(path);
		}
		#else
		if (Assets.exists(path))
		{
			rawJson = Assets.getText(path);
		}
		#end
	else
	{
		return null;
	}
		return cast Json.parse(rawJson);
	}

	public static function vanillaSongStage(songName):String
	{
		switch (songName)
		{
			case 'spookeez' | 'south' | 'monster':
				return 'spooky';
			case 'pico' | 'blammed' | 'philly' | 'philly-nice':
				return 'philly';
			case 'milf' | 'satin-panties' | 'high':
				return 'limo';
			case 'cocoa' | 'eggnog':
				return 'mall';
			case 'winter-horrorland':
				return 'mallEvil';
			case 'senpai' | 'roses':
				return 'school';
			case 'thorns':
				return 'schoolEvil';
			case 'ugh' | 'guns' | 'stress':
				return 'tank';
		}
		return 'stage';
	}

	public static function getStageList():Array<String>
	{
		final directories = Paths.getDirectories('stages');

		final tempArray:Array<String> = [];
		final stageFile:Array<String> = Mods.mergeAllTextsNamed('data/stageList.txt', Paths.getPreloadPath());
		final stages:Array<String> = [];
		for (stage in stageFile)
		{
			if (stage.trim().length > 0)
			{
				stages.push(stage);
			}
			tempArray.push(stage);
		}
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
						final stageToCheck:String = file.substr(0, file.length - 5);
						if (stageToCheck.trim().length > 0 && !tempArray.contains(stageToCheck))
						{
							tempArray.push(stageToCheck);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}
		#end

		if (stages.length < 1)
			stages.push('stage');

		return stages;
	}

	public static function addHardcodedStage(stage:String)
	{
		switch (stage)
		{
			case 'stage':
				new states.stages.StageWeek1(); // Week 1
			case 'spooky':
				new states.stages.Spooky(); // Week 2
			case 'philly':
				new states.stages.Philly(); // Week 3
			case 'limo':
				new states.stages.Limo(); // Week 4
			case 'mall':
				new states.stages.Mall(); // Week 5 - Cocoa, Eggnog
			case 'mallEvil':
				new states.stages.MallEvil(); // Week 5 - Winter Horrorland
			case 'school':
				new states.stages.School(); // Week 6 - Senpai, Roses
			case 'schoolEvil':
				new states.stages.SchoolEvil(); // Week 6 - Thorns
			case 'tank':
				new states.stages.Tank(); // Week 7 - Ugh, Guns, Stress
		}
	}
}
