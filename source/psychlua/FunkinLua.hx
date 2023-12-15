package psychlua;

import backend.Highscore;
import backend.Song;
import backend.WeekData;
import cutscenes.DialogueBoxPsych;
import cutscenes.DialogueCharacter;
import flixel.FlxBasic;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxSave;
import objects.StrumNote;
import psychlua.LuaUtils.LuaTweenOptions;
import states.FreeplayState;
import states.MainMenuState;
import states.StoryMenuState;
import substates.GameOverSubstate;
import substates.PauseSubState;
#if sys
import sys.FileSystem;
#end
#if !(MODS_ALLOWED)
import openfl.utils.Assets;
#end

class FunkinLua extends BaseLua
{
	public static var Function_Stop(get, set):Dynamic;

	static function get_Function_Stop()
	{
		return BaseLua.Function_Stop;
	}

	static function set_Function_Stop(value)
	{
		return BaseLua.Function_Stop = value;
	}

	public static var Function_Continue(get, set):Dynamic;

	static function get_Function_Continue()
	{
		return BaseLua.Function_Continue;
	}

	static function set_Function_Continue(value)
	{
		return BaseLua.Function_Continue = value;
	}

	public static var Function_StopLua(get, set):Dynamic;

	static function get_Function_StopLua()
	{
		return BaseLua.Function_StopLua;
	}

	static function set_Function_StopLua(value)
	{
		return BaseLua.Function_StopLua = value;
	}

	public static var Function_StopHScript(get, set):Dynamic;

	static function get_Function_StopHScript()
	{
		return BaseLua.Function_StopHScript;
	}

	static function set_Function_StopHScript(value)
	{
		return BaseLua.Function_StopHScript = value;
	}

	public static var Function_StopAll(get, set):Dynamic;

	static function get_Function_StopAll()
	{
		return BaseLua.Function_StopAll;
	}

	static function set_Function_StopAll(value)
	{
		return BaseLua.Function_StopAll = value;
	}

	public var camTarget:FlxCamera;

	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	public function new(scriptName:String)
	{
		super(scriptName);
	}

	override function preset()
	{
		super.preset();

		final game:PlayState = cast game;

		// Lua shit
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);
		set('inStageEditor', false);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);

		set('difficultyName', Difficulty.getString());
		set('difficultyPath', Paths.formatToSongPath(Difficulty.getString()));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', PlayState.SONG.needsVoices);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// PlayState cringe ass nae nae bullcrap
		set('score', 0);
		set('misses', 0);
		set('hits', 0);
		set('combo', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('version', MainMenuState.psychEngineVersion.trim());

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		// Gameplay settings
		set('healthGainMult', game.healthGain);
		set('healthLossMult', game.healthLoss);
		set('playbackRate', game.playbackRate);
		set('instakillOnMiss', game.instakillOnMiss);
		set('botPlay', game.cpuControlled);
		set('practice', game.practiceMode);

		for (i in 0...4)
		{
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', game.BF_X);
		set('defaultBoyfriendY', game.BF_Y);
		set('defaultOpponentX', game.DAD_X);
		set('defaultOpponentY', game.DAD_Y);
		set('defaultGirlfriendX', game.GF_X);
		set('defaultGirlfriendY', game.GF_Y);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		for (name => func in customFunctions)
		{
			if (func != null)
				Lua_helper.add_callback(lua, name, func);
		}

		Lua_helper.add_callback(lua, "loadSong", function(?name:String = null, ?difficultyNum:Int = -1)
		{
			if (name == null || name.length < 1)
				name = PlayState.SONG.song;
			if (difficultyNum == -1)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			game.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if (game.vocals != null)
			{
				game.vocals.pause();
				game.vocals.volume = 0;
			}
			FlxG.camera.followLerp = 0;
		});

		Lua_helper.add_callback(lua, "startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null)
			{
				if (values != null)
				{
					var myOptions:LuaTweenOptions = LuaUtils.getLuaTween(options);
					game.modchartTweens.set(tag, FlxTween.tween(penisExam, values, duration, {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,

						onUpdate: function(twn:FlxTween)
						{
							if (myOptions.onUpdate != null)
								game.callOnLuas(myOptions.onUpdate, [tag, vars]);
						},
						onStart: function(twn:FlxTween)
						{
							if (myOptions.onStart != null)
								game.callOnLuas(myOptions.onStart, [tag, vars]);
						},
						onComplete: function(twn:FlxTween)
						{
							if (myOptions.onComplete != null)
								game.callOnLuas(myOptions.onComplete, [tag, vars]);
							if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD)
								game.modchartTweens.remove(tag);
						}
					}));
				}
				else
				{
					luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
				}
			}
			else
			{
				luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		Lua_helper.add_callback(lua, "doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
		});
		Lua_helper.add_callback(lua, "doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
		});
		Lua_helper.add_callback(lua, "doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});
		Lua_helper.add_callback(lua, "doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});
		Lua_helper.add_callback(lua, "doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			oldTweenFunction(tag, vars, {zoom: value}, duration, ease, 'doTweenZoom');
		});
		Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null && penisExam.color != null)
			{
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				game.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.modchartTweens.remove(tag);
						game.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			}
			else
			{
				luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		// Tween shit, but for strums
		Lua_helper.add_callback(lua, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[Std.int(note % game.strumLineNotes.length)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[Std.int(note % game.strumLineNotes.length)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[Std.int(note % game.strumLineNotes.length)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[Std.int(note % game.strumLineNotes.length)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[Std.int(note % game.strumLineNotes.length)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			LuaUtils.cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = game.strumLineNotes.members[Std.int(note % game.strumLineNotes.length)];

			if (testicle != null)
			{
				game.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						game.callOnLuas('onTweenCompleted', [tag]);
						game.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "cancelTween", function(tag:String)
		{
			LuaUtils.cancelTween(tag);
		});

		Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1)
		{
			LuaUtils.cancelTimer(tag);
			game.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				if (tmr.finished)
				{
					game.modchartTimers.remove(tag);
				}

				final args:Array<Dynamic> = [tag, tmr.loops, tmr.loopsLeft];
				game.callOnLuas('onTimerCompleted', args);
				// trace('Timer Completed: ' + tag);
			}, loops));
		});
		Lua_helper.add_callback(lua, "cancelTimer", function(tag:String)
		{
			LuaUtils.cancelTimer(tag);
		});

		// stupid bietch ass functions
		Lua_helper.add_callback(lua, "addScore", function(value:Int = 0)
		{
			game.songScore += value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "addMisses", function(value:Int = 0)
		{
			game.songMisses += value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "addHits", function(value:Int = 0)
		{
			game.songHits += value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setScore", function(value:Int = 0)
		{
			game.songScore = value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setMisses", function(value:Int = 0)
		{
			game.songMisses = value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setHits", function(value:Int = 0)
		{
			game.songHits = value;
			game.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "getScore", function()
		{
			return game.songScore;
		});
		Lua_helper.add_callback(lua, "getMisses", function()
		{
			return game.songMisses;
		});
		Lua_helper.add_callback(lua, "getHits", function()
		{
			return game.songHits;
		});

		Lua_helper.add_callback(lua, "setHealth", function(value:Float = 0)
		{
			game.health = value;
		});
		Lua_helper.add_callback(lua, "addHealth", function(value:Float = 0)
		{
			game.health += value;
		});
		Lua_helper.add_callback(lua, "getHealth", function()
		{
			return game.health;
		});

		// precaching
		Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String)
		{
			var charType:Int = 0;
			switch (type.toLowerCase())
			{
				case 'dad':
					charType = 1;
				case 'gf' | 'girlfriend':
					charType = 2;
			}
			game.addCharacterToList(name, charType);
		});
		Lua_helper.add_callback(lua, "precacheImage", function(name:String, ?allowGPU:Bool = true)
		{
			game.precacheImage(name, allowGPU);
		});
		Lua_helper.add_callback(lua, "precacheSound", function(name:String)
		{
			Paths.sound(name);
		});
		Lua_helper.add_callback(lua, "precacheMusic", function(name:String)
		{
			Paths.music(name);
		});

		// others
		Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic)
		{
			var value1:String = arg1;
			var value2:String = arg2;
			game.triggerEvent(name, value1, value2, Conductor.songPosition);
			// trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
			return true;
		});

		Lua_helper.add_callback(lua, "startCountdown", function()
		{
			game.startCountdown();
			return true;
		});
		Lua_helper.add_callback(lua, "endSong", function()
		{
			game.KillNotes();
			game.endSong();
			return true;
		});
		Lua_helper.add_callback(lua, "restartSong", function(?skipTransition:Bool = false)
		{
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		Lua_helper.add_callback(lua, "exitSong", function(?skipTransition:Bool = false)
		{
			if (skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			PlayState.cancelMusicFadeTween();
			if (FlxTransitionableState.skipNextTransIn)
				CustomFadeTransition.nextCamera = null;
			else
				CustomFadeTransition.nextCamera = game.camOther;

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			#if desktop DiscordClient.resetClientID(); #end

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			game.transitioning = true;
			FlxG.camera.followLerp = 0;
			Mods.loadTopMod();
			return true;
		});
		Lua_helper.add_callback(lua, "getSongPosition", function()
		{
			return Conductor.songPosition;
		});
		Lua_helper.add_callback(lua, "songPlayedInSession", function()
		{
			return PlayState.playedSongs.contains(PlayState.instance.songName);
		});

		Lua_helper.add_callback(lua, "cameraSetTarget", function(target:String)
		{
			var isDad:Bool = false;
			if (target == 'dad')
			{
				isDad = true;
			}
			game.moveCamera(isDad);
			return isDad;
		});
		Lua_helper.add_callback(lua, "cameraShake", function(camera:String, intensity:Float, duration:Float)
		{
			LuaUtils.cameraFromString(camera).shake(intensity, duration);
		});

		Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});
		Lua_helper.add_callback(lua, "cameraFade", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, false, null, forced);
		});
		Lua_helper.add_callback(lua, "setRatingPercent", function(value:Float)
		{
			game.ratingPercent = value;
		});
		Lua_helper.add_callback(lua, "setRatingName", function(value:String)
		{
			game.ratingName = value;
		});
		Lua_helper.add_callback(lua, "setRatingFC", function(value:String)
		{
			game.ratingFC = value;
		});

		Lua_helper.add_callback(lua, "luaSoundExists", function(tag:String)
		{
			return game.modchartSounds.exists(tag);
		});

		Lua_helper.add_callback(lua, "setHealthBarColors", function(left:String, right:String)
		{
			game.healthBar.setColors(CoolUtil.colorFromString(left), CoolUtil.colorFromString(right));
		});
		Lua_helper.add_callback(lua, "setTimeBarColors", function(left:String, right:String)
		{
			game.timeBar.setColors(CoolUtil.colorFromString(left), CoolUtil.colorFromString(right));
		});

		Lua_helper.add_callback(lua, "startDialogue", function(dialogueFile:String, music:String = null)
		{
			var path:String;
			#if MODS_ALLOWED
			path = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
			if (!FileSystem.exists(path))
			#end
			path = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

			luaTrace('startDialogue: Trying to load dialogue: ' + path);

			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if (shit.dialogue.length > 0)
				{
					game.startDialogue(shit, music);
					luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				}
				else
				{
					luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
				}
			}
		else
		{
			luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
			if (game.endingSong)
			{
				game.endSong();
			}
			else
			{
				game.startCountdown();
			}
		}
			return false;
		});
		Lua_helper.add_callback(lua, "startVideo", function(videoFile:String)
		{
			#if VIDEOS_ALLOWED
			if (FileSystem.exists(Paths.video(videoFile)))
			{
				game.startVideo(videoFile);
				return true;
			}
			else
			{
				luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			}
			return false;
			#else
			if (game.endingSong)
			{
				game.endSong();
			}
			else
			{
				game.startCountdown();
			}
			return true;
			#end
		});
		Lua_helper.add_callback(lua, "precacheDialogue", function(dialogueFile:String)
		{
			var path:String;
			path = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
			if (!FileSystem.exists(path))
				path = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

			if (FileSystem.exists(path))
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if (shit.dialogue.length > 0)
				{
					var state = MusicBeatState.getState();
					state.precacheImage('speech_bubble');
					Paths.sound('dialogue');
					Paths.sound('dialogueClose');

					var loadedChars:Array<String> = [];
					var loadedSounds:Array<String> = ['dialogue'];
					for (dialogue in shit.dialogue)
					{
						var char = dialogue.portrait;
						if (!loadedChars.contains(char))
						{
							var dialogueChar = new DialogueCharacter(0, 0, char);
							state.precacheGraphic(dialogueChar.graphic);
							dialogueChar.destroy();
							loadedChars.push(char);
						}

						if (dialogue.sound != null && dialogue.sound.length > 0 && !loadedSounds.contains(dialogue.sound))
						{
							Paths.sound(dialogue.sound);
							loadedSounds.push(dialogue.sound);
						}
					}

					return true;
				}
			}
			return false;
		});

		Lua_helper.add_callback(lua, "playMusic", function(sound:String, volume:Float = 1, loop:Bool = false, pitch:Float = 1)
		{
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
			if (pitch != 1)
				FlxG.sound.music.pitch = pitch;
		});
		Lua_helper.add_callback(lua, "playSound", function(sound:String, volume:Float = 1, ?tag:String = null, pitch:Float = 1)
		{
			if (tag != null && tag.length > 0)
			{
				tag = tag.replace('.', '');
				if (game.modchartSounds.exists(tag))
				{
					game.modchartSounds.get(tag).stop();
				}
				var sound = FlxG.sound.play(Paths.sound(sound), volume, false, function()
				{
					game.modchartSounds.remove(tag);
					game.callOnLuas('onSoundFinished', [tag]);
				});
				if (sound != null)
				{
					sound.pitch = pitch;
					game.modchartSounds.set(tag, sound);
				}
				return;
			}
			var sound = FlxG.sound.play(Paths.sound(sound), volume);
			if (sound != null)
				sound.pitch = pitch;
		});
		Lua_helper.add_callback(lua, "stopSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).stop();
				game.modchartSounds.remove(tag);
			}
		});
		Lua_helper.add_callback(lua, "pauseSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).pause();
			}
		});
		Lua_helper.add_callback(lua, "resumeSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).play();
			}
		});
		Lua_helper.add_callback(lua, "soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}
		});
		Lua_helper.add_callback(lua, "soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeOut(duration, toValue);
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).fadeOut(duration, toValue);
			}
		});
		Lua_helper.add_callback(lua, "soundFadeCancel", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music.fadeTween != null)
				{
					FlxG.sound.music.fadeTween.cancel();
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound.fadeTween != null)
				{
					theSound.fadeTween.cancel();
					game.modchartSounds.remove(tag);
				}
			}
		});
		Lua_helper.add_callback(lua, "getSoundVolume", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					return FlxG.sound.music.volume;
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).volume;
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "setSoundVolume", function(tag:String, value:Float)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.volume = value;
				}
			}
			else if (game.modchartSounds.exists(tag))
			{
				game.modchartSounds.get(tag).volume = value;
			}
		});
		Lua_helper.add_callback(lua, "getSoundTime", function(tag:String)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				return game.modchartSounds.get(tag).time;
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "setSoundTime", function(tag:String, value:Float)
		{
			if (tag != null && tag.length > 0 && game.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = game.modchartSounds.get(tag);
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if (wasResumed)
						theSound.play();
				}
			}
		});

		// Save data management
		Lua_helper.add_callback(lua, "initSaveData", function(name:String, ?folder:String = 'psychenginemods')
		{
			if (!PlayState.instance.modchartSaves.exists(name))
			{
				var save:FlxSave = new FlxSave();
				// folder goes unused for flixel 5 users. @BeastlyGhost
				save.bind(name, CoolUtil.getSavePath() + '/' + folder);
				PlayState.instance.modchartSaves.set(name, save);
				return;
			}
			onLuaLog('initSaveData: Save file already initialized: ' + name);
		});
		Lua_helper.add_callback(lua, "flushSaveData", function(name:String)
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				PlayState.instance.modchartSaves.get(name).flush();
				return;
			}
			onError('flushSaveData: Save file not initialized: ' + name);
		});
		Lua_helper.add_callback(lua, "getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null)
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				var saveData = PlayState.instance.modchartSaves.get(name).data;
				if (Reflect.hasField(saveData, field))
					return Reflect.field(saveData, field);
				else
					return defaultValue;
			}
			onError('getDataFromSave: Save file not initialized: ' + name);
			return defaultValue;
		});
		Lua_helper.add_callback(lua, "setDataFromSave", function(name:String, field:String, value:Dynamic)
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				Reflect.setField(PlayState.instance.modchartSaves.get(name).data, field, value);
				return;
			}
			onError('setDataFromSave: Save file not initialized: ' + name);
		});

		Lua_helper.add_callback(lua, "musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1)
		{
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			warnDeprecated('musicFadeIn is deprecated! Use soundFadeIn instead.');
		});
		Lua_helper.add_callback(lua, "musicFadeOut", function(duration:Float, toValue:Float = 0)
		{
			FlxG.sound.music.fadeOut(duration, toValue);
			warnDeprecated('musicFadeOut is deprecated! Use soundFadeOut instead.');
		});

		CustomSubstate.implement(this);
	}

	override function onLoadError(msg)
	{
		luaTrace('$scriptName\n$msg', true, false, FlxColor.RED);
	}

	override function onError(error, important = false)
	{
		luaTrace(error, important, false, FlxColor.RED);
	}

	override function onLuaLog(log)
	{
		luaTrace(log);
	}

	override function warnDeprecated(error)
	{
		luaTrace(error, false, true);
	}

	override function stop()
	{
		#if LUA_ALLOWED
		PlayState.instance.luaArray.remove(this);
		#end
		super.stop();
	}

	override function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any
	{
		return LuaUtils.getVarInArray(instance, variable, allowMaps);
	}

	override function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
	{
		return LuaUtils.setVarInArray(instance, variable, value, allowMaps);
	}

	override function getTargetInstance()
	{
		return LuaUtils.getTargetInstance();
	}

	override function addObject(obj:FlxBasic, front:Bool = false)
	{
		final game:PlayState = cast game;
		if (front)
			LuaUtils.getTargetInstance().add(obj);
		else
		{
			if (!game.isDead)
				game.insert(game.members.indexOf(LuaUtils.getLowestCharacterGroup()), obj);
			else
				GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
		}
	}

	override function initHaxeModule(?file:String)
	{
		hscript = new HScript(this, file);
	}

	function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String)
	{
		#if LUA_ALLOWED
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		if (target != null)
		{
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					PlayState.instance.modchartTweens.remove(tag);
					PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
				}
			}));
		}
		else
		{
			luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
		}
		#end
	}

	public static function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE)
	{
		#if LUA_ALLOWED
		if (ignoreCheck || getBool('luaDebugMode'))
		{
			if (deprecated && !getBool('luaDeprecatedWarnings'))
			{
				return;
			}
			PlayState.instance.addTextToDebug(text, color);
			trace(text);
		}
		#end
	}

	#if LUA_ALLOWED
	public static function getBool(variable:String)
	{
		return BaseLua.getBool(variable);
	}
	#end

	public static function getBuildTarget():String
	{
		return BaseLua.getBuildTarget();
	}
}
