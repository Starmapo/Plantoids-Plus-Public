package states;

import backend.Highscore;
import backend.Song;
import backend.WeekData;
import flixel.FlxObject;
import flixel.util.FlxSpriteUtil;
import objects.FreeplayPot;
import states.editors.ChartingState;
import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;
#if MODS_ALLOWED
import sys.FileSystem;
#end

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	private static var curSelected:Int = 0;

	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;

	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpPots:FlxTypedGroup<FreeplayPot>;

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var camFollow:FlxObject;
	var sprDifficulty:FlxSprite;
	var upArrow:FlxSprite;
	var downArrow:FlxSprite;
	var tweenDifficulty:FlxTween;
	var tweenBG:FlxTween;
	var difficultyBG:FlxSprite;

	override function create()
	{
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null, null, null, "icon");
		#end

		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i]))
				continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3)
					colors = [146, 113, 253];

				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		FlxG.camera.bgColor = FlxColor.BLACK;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		add(bg);
		bg.screenCenter();

		grpPots = new FlxTypedGroup();
		add(grpPots);

		for (i in 0...songs.length)
		{
			Mods.currentModDirectory = songs[i].folder;
			var pot = new FreeplayPot(i, songs[i]);
			grpPots.add(pot);

			// too laggy with a lot of songs, so i had to recode the logic for it
			pot.visible = pot.active = false;
		}
		WeekData.setDirectoryFromWeek();

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		upArrow = new FlxSprite(0, 490);
		upArrow.antialiasing = ClientPrefs.data.antialiasing;
		upArrow.frames = ui_tex;
		upArrow.animation.addByPrefix('idle', "arrow left");
		upArrow.animation.addByPrefix('press', "arrow push left");
		upArrow.animation.play('idle');
		upArrow.screenCenter(X);
		upArrow.scrollFactor.set();
		upArrow.angle = 90;
		add(upArrow);

		difficultyBG = new FlxSprite();
		difficultyBG.antialiasing = ClientPrefs.data.antialiasing;
		difficultyBG.scrollFactor.set();
		add(difficultyBG);

		sprDifficulty = new FlxSprite();
		sprDifficulty.antialiasing = ClientPrefs.data.antialiasing;
		sprDifficulty.scrollFactor.set();
		add(sprDifficulty);

		downArrow = new FlxSprite(0, upArrow.y + upArrow.width + 85);
		downArrow.antialiasing = ClientPrefs.data.antialiasing;
		downArrow.frames = ui_tex;
		downArrow.animation.addByPrefix('idle', 'arrow right');
		downArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		downArrow.animation.play('idle');
		downArrow.screenCenter(X);
		downArrow.scrollFactor.set();
		downArrow.angle = 90;
		add(downArrow);

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.scrollFactor.set();

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 44, 0xFF000000);
		scoreBG.alpha = 0.6;
		scoreBG.scrollFactor.set();
		add(scoreBG);

		add(scoreText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if (curSelected >= songs.length)
			curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		camFollow = new FlxObject(0, FlxG.height / 2);
		FlxG.camera.follow(camFollow, LOCKON, 0.16 * (60 / FlxG.updateFramerate));
		add(camFollow);

		changeSelection();
		FlxG.camera.snapToTarget();

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		textBG.scrollFactor.set();
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		updateTexts();
		super.create();
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;

	public static var vocals:FlxSound = null;

	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2)
		{ // No decimals, add an empty space
			ratingSplit.push('');
		}

		while (ratingSplit[1].length < 2)
		{ // Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var shiftMult:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftMult = 3;

		if (songs.length > 1)
		{
			if (FlxG.keys.justPressed.HOME)
			{
				curSelected = 0;
				changeSelection();
				holdTime = 0;
			}
			else if (FlxG.keys.justPressed.END)
			{
				curSelected = songs.length - 1;
				changeSelection();
				holdTime = 0;
			}
			if (controls.UI_LEFT_P)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_RIGHT_P)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_LEFT || controls.UI_RIGHT)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_LEFT ? -shiftMult : shiftMult));
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}
		}

		if (controls.UI_DOWN)
			downArrow.animation.play('press')
		else
			downArrow.animation.play('idle');
		downArrow.centerOffsets();
		downArrow.centerOrigin();

		if (controls.UI_UP)
			upArrow.animation.play('press');
		else
			upArrow.animation.play('idle');
		upArrow.centerOffsets();
		upArrow.centerOrigin();

		if (controls.UI_UP_P)
		{
			changeDiff(-1);
			_updateSongLastDifficulty();
		}
		else if (controls.UI_DOWN_P)
		{
			changeDiff(1);
			_updateSongLastDifficulty();
		}

		if (controls.BACK)
		{
			persistentUpdate = false;
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		var isPlayable = songIsPlayable();
		if (FlxG.keys.justPressed.CONTROL)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if (FlxG.keys.justPressed.SPACE)
		{
			if (instPlaying != curSelected && isPlayable)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				PlayState.storyDifficulty = curDifficulty;
				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song));
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				instPlaying = curSelected;
				#end
			}
		}
		else if (controls.ACCEPT)
		{
			if (isPlayable)
			{
				persistentUpdate = false;
				var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
				trace(poop);

				try
				{
					PlayState.SONG = Song.loadFromJson(poop, songLowercase);
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = curDifficulty;

					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					if (colorTween != null)
					{
						colorTween.cancel();
					}
				}
				catch (e:Dynamic)
				{
					trace('ERROR! $e');

					var errorStr:String = e.toString();
					if (errorStr.startsWith('[file_contents,assets/data/'))
						errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length - 1); // Missing chart
					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));

					updateTexts(elapsed);
					super.update(elapsed);
					return;
				}

				// why remove this???
				if (FlxG.keys.pressed.SHIFT)
				{
					LoadingState.loadAndSwitchState(new ChartingState());
				}
				else
				{
					LoadingState.loadAndSwitchState(new PlayState());
				}

				FlxG.sound.music.volume = 0;

				destroyFreeplayVocals();
				#if MODS_ALLOWED
				DiscordClient.loadModRPC();
				#end
			}
		}
		else if (controls.RESET && isPlayable)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
		super.update(elapsed);

		if (FlxG.mouse.visible)
			FlxG.mouse.visible = false;
	}

	public static function destroyFreeplayVocals()
	{
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length - 1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		var diff:String = Difficulty.getString(curDifficulty);
		var newImage = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));
		if (sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);
			sprDifficulty.y = upArrow.y + upArrow.width - 5;
			sprDifficulty.alpha = 0;

			var maxHeight = 67;
			if (sprDifficulty.height > maxHeight)
				sprDifficulty.setGraphicSize(0, maxHeight);
			else
				sprDifficulty.scale.set(1, 1);
			sprDifficulty.updateHitbox();
			sprDifficulty.screenCenter(X);

			difficultyBG.makeGraphic(Std.int(sprDifficulty.width + 10), Std.int(sprDifficulty.height + 10), FlxColor.TRANSPARENT);
			FlxSpriteUtil.drawRoundRect(difficultyBG, 0, 0, difficultyBG.width, difficultyBG.height, 20, 20, FlxColor.BLACK, {color: FlxColor.BLACK});
			difficultyBG.x = sprDifficulty.x - 5;
			difficultyBG.y = sprDifficulty.y - 5;
			difficultyBG.alpha = 0;

			if (tweenDifficulty != null)
				tweenDifficulty.cancel();
			var targetY = upArrow.y + upArrow.width + 28;
			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: targetY, alpha: 1}, 0.07, {
				onComplete: function(twn:FlxTween)
				{
					tweenDifficulty = null;
				}
			});

			if (tweenBG != null)
				tweenBG.cancel();
			tweenBG = FlxTween.tween(difficultyBG, {y: targetY - 5, alpha: 0.8}, 0.07, {
				onComplete: function(twn:FlxTween)
				{
					tweenBG = null;
				}
			});
		}

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		_updateSongLastDifficulty();
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected = Std.int(FlxMath.wrap(curSelected + change, 0, songs.length - 1));

		var newColor:Int = songs[curSelected].color;
		if (newColor != intendedColor)
		{
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween)
				{
					colorTween = null;
				}
			});
		}

		var midpoint = grpPots.members[curSelected].getMidpoint();
		camFollow.x = midpoint.x;
		midpoint.put();

		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();

		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if (savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if (lastDiff > -1)
			curDifficulty = lastDiff;
		else if (Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();

		upArrow.visible = downArrow.visible = (sprDifficulty.visible && Difficulty.list.length > 1);
	}

	inline private function _updateSongLastDifficulty()
	{
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
	}

	var _drawDistance:Int = 1;
	var _lastVisibles:Array<Int> = [];

	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, FlxMath.bound(elapsed * 9.6, 0, 1));
		for (i in _lastVisibles)
			grpPots.members[i].visible = grpPots.members[i].active = false;
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance + 1)));
		for (i in min...max)
		{
			var item = grpPots.members[i];
			item.visible = item.active = true;

			_lastVisibles.push(i);
		}
	}

	function songIsPlayable()
	{
		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);

		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
		return Paths.fileExists('data/$songLowercase/$poop.json', TEXT);
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if (this.folder == null)
			this.folder = '';
	}
}
