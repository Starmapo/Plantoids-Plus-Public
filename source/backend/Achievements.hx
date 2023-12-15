package backend;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import tjson.TJSON as Json;

class Achievements
{
	public static var baseAchievements:Array<AchievementData> = [
		{
			name: "friday_night_play",
			displayName: "Freaky on a Friday Night",
			description: "Play on a Friday... Night.",
			hidden: true
		},
		{
			name: "ur_bad",
			displayName: "What a Funkin' Disaster!",
			description: "Complete a Song with a rating lower than 20%.",
		},
		{
			name: "ur_good",
			displayName: "Perfectionist",
			description: "Complete a Song with a rating of 100%.",
		},
		{
			name: "oversinging",
			displayName: "Oversinging Much...?",
			description: "Hold down a note for 10 seconds.",
		},
		{
			name: "hype",
			displayName: "Hyperactive",
			description: "Finish a Song without going Idle.",
		},
		{
			name: "two_keys",
			displayName: "Just the Two of Us",
			description: "Finish a Song pressing only two keys.",
		},
		{
			name: "toastie",
			displayName: "Toaster Gamer",
			description: "Have you tried to run the game on a toaster?",
		},
		{
			name: "debugger",
			displayName: "Debugger",
			description: "Beat the \"Test\" Stage from the Chart Editor.",
			hidden: true
		}
	];
	public static var loadedAchievements:Array<AchievementData> = [];
	public static var achievementsMap:Map<String, Bool> = new Map<String, Bool>();
	public static var henchmenDeath:Int = 0;

	// this is so 2 mods using the same achievement name won't break this system
	public static function getInternalName(name:String, ?mod:String)
	{
		if (mod != null && mod.length > 0)
			return mod + ':' + name;
		else
			return name;
	}

	public static function getExternalName(name:String)
	{
		if (name.contains(':'))
			return name.substr(name.indexOf(':') + 1);

		return name;
	}

	public static function unlockAchievement(name:String):Void
	{
		FlxG.log.add('Completed achievement "' + name + '"');
		achievementsMap.set(name, true);
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	public static function isAchievementUnlocked(name:String)
	{
		if (achievementsMap.exists(name))
			return achievementsMap.get(name);

		return false;
	}

	public static function getAchievement(name:String)
	{
		return loadedAchievements[getAchievementIndex(name)];
	}

	public static function getAchievementIndex(name:String)
	{
		for (i in 0...loadedAchievements.length)
		{
			if (loadedAchievements[i].name == name)
				return i;
		}
		return -1;
	}

	public static function loadAchievements():Void
	{
		if (FlxG.save.data != null && FlxG.save.data.achievementsMap != null)
			achievementsMap = FlxG.save.data.achievementsMap;
	}

	public static function reloadAchievements()
	{
		loadedAchievements.resize(0);

		for (ach in baseAchievements)
			loadedAchievements.push(ach);

		pushAchievements(Paths.mods());

		for (mod in Mods.parseList().enabled)
			pushAchievements(Path.join([Paths.mods(), mod]), mod);
	}

	static function pushAchievements(path:String, mod:String = '')
	{
		var list = CoolUtil.coolTextFile(Path.join([path, 'achievements/achievementList.txt']));
		for (name in list)
		{
			if (name == null || name.length < 1)
				continue;

			var achPath = Path.join([path, 'achievements/' + name + '.json']);
			if (FileSystem.exists(achPath))
			{
				var json = Json.parse(File.getContent(achPath));
				loadedAchievements.push({
					name: getInternalName(name, mod),
					displayName: json.displayName,
					description: json.description,
					hidden: json.hidden == true,
					unlockCondition: json.unlockCondition,
					mod: mod
				});
			}
		}
	}
}

typedef AchievementData =
{
	var name:String;
	var displayName:String;
	var description:String;
	var ?hidden:Bool;
	var ?unlockCondition:String;
	var ?mod:String;
}
