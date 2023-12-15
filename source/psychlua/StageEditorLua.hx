package psychlua;

import states.MainMenuState;
import states.editors.StageEditorState;

class StageEditorLua extends BaseLua
{
	override function preset()
	{
		super.preset();

		final game:StageEditorState = cast game;

		// Lua shit
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);
		set('inStageEditor', true);

		// Song/Week shit
		set('curBpm', 100);
		set('bpm', 100);
		set('scrollSpeed', 1);
		set('crochet', (60 / 100) * 1000);
		set('stepCrochet', (60 / 100) * 1000 / 4);
		set('songLength', 1000);
		set('songName', '');
		set('songPath', '');
		set('startedCountdown', false);
		set('curStage', game.stageName);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', 0);

		set('difficultyName', 'Normal');
		set('difficultyPath', 'normal');
		set('weekRaw', 0);
		set('week', '');
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', true);

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
		set('healthGainMult', 1);
		set('healthLossMult', 1);
		set('playbackRate', 1);
		set('instakillOnMiss', false);
		set('botPlay', false);
		set('practice', false);

		for (i in 0...4)
		{
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', game.stageData.boyfriend[0]);
		set('defaultBoyfriendY', game.stageData.boyfriend[1]);
		set('defaultOpponentX', game.stageData.opponent[0]);
		set('defaultOpponentY', game.stageData.opponent[1]);
		set('defaultGirlfriendX', game.stageData.girlfriend[0]);
		set('defaultGirlfriendY', game.stageData.girlfriend[1]);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		// Replace these functions to return default or null values
		for (func in ["getScore", "getMisses", "getHits", "getSoundVolume", "getSoundTime"])
			Lua_helper.add_callback(lua, func, function()
			{
				return 0;
			});
		for (func in ["triggerEvent", "startCountdown", "endSong", "restartSong", "exitSong"])
			Lua_helper.add_callback(lua, func, function()
			{
				return true;
			});
		for (func in [
			"luaSoundExists",
			"startDialogue",
			"startVideo",
			"precacheDialogue",
			"closeCustomSubstate",
			"insertToCustomSubstate"
		])
			Lua_helper.add_callback(lua, func, function()
			{
				return false;
			});

		Lua_helper.add_callback(lua, "getHealth", function()
		{
			return 1;
		});
		Lua_helper.add_callback(lua, "cameraSetTarget", function(target:String)
		{
			return target == 'dad';
		});
		Lua_helper.add_callback(lua, "getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null)
		{
			return defaultValue;
		});
		Lua_helper.add_callback(lua, "getSongPosition", function()
		{
			return -5000;
		});

		// These don't return anything, so just leave them blank
		for (func in [
			"loadSong", "startTween", "doTweenX", "doTweenY", "doTweenAngle", "doTweenAlpha", "doTweenZoom", "doTweenColor", "noteTweenX", "noteTweenY",
			"noteTweenAngle", "noteTweenDirection", "noteTweenAlpha", "cancelTween", "runTimer", "cancelTimer", "addScore", "addMisses", "addHits",
			"setScore", "setMisses", "setHits", "setHealth", "addHealth", "addCharacterToList", "precacheImage", "precacheSound", "precacheMusic",
			"cameraShake", "cameraFlash", "cameraFade", "setRatingPercent", "setRatingName", "setRatingFC", "setHealthBarColors", "setTimeBarColors",
			"playMusic", "playSound", "stopSound", "pauseSound", "resumeSound", "soundFadeIn", "soundFadeOut", "soundFadeCancel", "setSoundVolume",
			"setSoundTime", "initSaveData", "flushSaveData", "setDataFromSave", "musicFadeIn", "musicFadeOut", "openCustomSubstate"
		])
			Lua_helper.add_callback(lua, func, function() {});
	}
}
