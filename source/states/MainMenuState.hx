package states;

import backend.Achievements;
import backend.WeekData;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.input.keyboard.FlxKey;
import lime.app.Application;
import objects.AchievementPopup;
import options.OptionsState;
import states.editors.MasterEditorMenu;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.1h';
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<MainMenuItem>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var optionShit:Array<String> = [
		'story',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'wiki',
		'options'
	];

	var magenta:FlxSprite;
	var bg:FlxSprite;
	var mainMenuArt:FlxSprite;
	var holdTime:Float = 0;

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.camera.bgColor = FlxColor.BLACK;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null, null, null, "icon");
		#end

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scale.set(1.175, 1.175);
		bg.updateHitbox();
		bg.screenCenter(X);
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scale.set(1.175, 1.175);
		magenta.updateHitbox();
		magenta.screenCenter(X);
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		mainMenuArt = new FlxSprite();
		mainMenuArt.scale.scale(0.9);
		mainMenuArt.scrollFactor.set();
		mainMenuArt.antialiasing = ClientPrefs.data.antialiasing;
		add(mainMenuArt);

		var logo = new FlxSprite(10, FlxG.height - 10).loadGraphic(Paths.image('logoPlantoids'));
		logo.scale.set(0.3, 0.3);
		logo.updateHitbox();
		logo.y -= logo.height;
		logo.scrollFactor.set();
		logo.antialiasing = ClientPrefs.data.antialiasing;
		add(logo);

		menuItems = new FlxTypedGroup();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var menuItem = new MainMenuItem();
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/buttons/' + optionShit[i]);
			menuItem.animation.addByNames('idle', [optionShit[i]], 0, false);
			menuItem.animation.addByNames('selected', [optionShit[i] + "_selected"], 0, false);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
		}

		final versionTexts = [
			"VS Plantoids+ v" + Application.current.meta.get('version'),
			"Psych Engine v" + psychEngineVersion,
			"Friday Night Funkin' v0.2.8"
		];
		for (i in 0...versionTexts.length)
		{
			var versionText:FlxText = new FlxText(12, FlxG.height - 4 - 20 * (versionTexts.length - i), 0, versionTexts[i]);
			versionText.scrollFactor.set();
			versionText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			add(versionText);
		}

		changeItem();
		for (menuItem in menuItems)
			menuItem.snapToPosition();

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
		{
			var achieveName = 'friday_night_play';
			if (!Achievements.isAchievementUnlocked(achieveName))
			{ // It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.unlockAchievement(achieveName);
				giveAchievement();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement()
	{
		add(new AchievementPopup('friday_night_play', camAchievement));
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
				holdTime = 0;
			}

			if (controls.UI_UP || controls.UI_DOWN)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeItem((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
				}
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeItem(-1 * FlxG.mouse.wheel);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					if (ClientPrefs.data.flashing)
						FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'wiki':
										MusicBeatState.switchState(new WikiState());
									case 'options':
										LoadingState.loadAndSwitchState(new OptionsState());
										OptionsState.onPlayState = false;
										if (PlayState.SONG != null)
										{
											PlayState.SONG.arrowSkin = null;
											PlayState.SONG.splashSkin = null;
										}
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		magenta.y = bg.y = FlxMath.lerp(bg.y, FlxMath.remapToRange(curSelected, 0, menuItems.length - 1, 0, FlxG.height - bg.height),
			FlxMath.bound(elapsed * 9, 0, 1));

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		mainMenuArt.loadGraphic(Paths.image('mainmenu/art/' + optionShit[curSelected]));
		mainMenuArt.updateHitbox();
		mainMenuArt.x = (FlxG.width / 2 - mainMenuArt.width) / 2;
		mainMenuArt.screenCenter(Y);

		menuItems.forEach(function(spr)
		{
			spr.targetY = spr.ID - curSelected;

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if (menuItems.length > 4)
					add = menuItems.length * 8;
			}
			else
				spr.animation.play('idle');

			spr.updateHitbox();
			spr.centerOrigin();
		});
	}
}

class MainMenuItem extends FlxSprite
{
	public var targetY:Int = 0;

	override function update(elapsed:Float)
	{
		var lerp = FlxMath.bound(elapsed * 9, 0, 1);
		x = FlxMath.lerp(x, getTargetX(), lerp);
		y = FlxMath.lerp(y, getTargetY(), lerp);
		angle = FlxMath.lerp(angle, getTargetAngle(), lerp);

		super.update(elapsed);
	}

	public function snapToPosition()
	{
		x = getTargetX();
		y = getTargetY();
		angle = getTargetAngle();
	}

	function getTargetX()
	{
		var scaledY = targetY * 1.3;
		var targetX = Math.exp(Math.abs(scaledY) * 0.8) * 70;
		targetX += FlxG.width - width - 100;
		if (targetX > FlxG.width * 2)
			targetX = FlxG.width * 2;
		return targetX;
	}

	function getTargetY()
	{
		var scaledY = targetY * 1.3;
		var targetY = (scaledY * 250) + ((FlxG.height - height) / 2);
		return targetY;
	}

	function getTargetAngle()
	{
		return -45 * targetY;
	}
}
