package states;

import backend.Achievements;
import backend.WeekData;
import objects.AttachedAchievement;

class AchievementsMenuState extends MusicBeatState
{
	#if ACHIEVEMENTS_ALLOWED
	var options:Array<AchievementData> = [];
	private var grpOptions:FlxTypedGroup<Alphabet>;

	private static var curSelected:Int = 0;

	private var achievementArray:Array<AttachedAchievement> = [];
	private var achievementIndex:Array<Int> = [];
	private var descText:FlxText;

	override function create()
	{
		#if desktop
		DiscordClient.changePresence("Achievements Menu", null, null, null, "icon");
		#end

		persistentUpdate = true;

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.scale.set(1.1, 1.1);
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		Achievements.reloadAchievements();
		for (i in 0...Achievements.loadedAchievements.length)
		{
			var achievement = Achievements.loadedAchievements[i];
			if (!achievement.hidden || Achievements.isAchievementUnlocked(achievement.name))
			{
				options.push(achievement);
				achievementIndex.push(i);
			}
		}

		for (i in 0...options.length)
		{
			var achievement = options[i];
			if (achievement.mod != null)
				Mods.currentModDirectory = achievement.mod;
			else
				Mods.currentModDirectory = '';

			var achieveName:String = achievement.name;
			var optionText:Alphabet = new Alphabet(280, 300, Achievements.isAchievementUnlocked(achieveName) ? achievement.displayName : '?', false);
			optionText.isMenuItem = true;
			optionText.targetY = i - curSelected;
			optionText.snapToPosition();
			grpOptions.add(optionText);

			var icon:AttachedAchievement = new AttachedAchievement(optionText.x - 105, optionText.y, achieveName);
			icon.sprTracker = optionText;
			achievementArray.push(icon);
			add(icon);
		}
		Mods.loadTopMod();

		descText = new FlxText(150, 600, 980, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);
		changeSelection();

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
			persistentUpdate = false;
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		for (i in 0...achievementArray.length)
		{
			achievementArray[i].alpha = 0.6;
			if (i == curSelected)
			{
				achievementArray[i].alpha = 1;
			}
		}
		descText.text = options[curSelected].description;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
	#end
}
