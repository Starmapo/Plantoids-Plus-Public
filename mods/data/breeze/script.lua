local allowCountdown = false
function onStartCountdown()
	-- Block the first countdown and start a timer of 0.8 seconds to play the dialogue
	if not allowCountdown and isStoryMode and not seenCutscene and string.lower(difficultyName) ~= "bfhard" then --b fhard
		setProperty('inCutscene', true);
		runTimer('startDialogue', 0.8);
		allowCountdown = true;
		setPropertyFromClass("flixel.FlxG", "camera.scroll.x", getProperty("camFollow.x") - screenWidth / 2)
		setPropertyFromClass("flixel.FlxG", "camera.scroll.y", getProperty("camFollow.y") - screenHeight / 2)
		precacheDialogue('dialogue')
		return Function_Stop;
	end
	return Function_Continue;
end

function onTimerCompleted(tag, loops, loopsLeft)
	if tag == 'startDialogue' then -- Timer completed, play dialogue
		startDialogue('dialogue');
	end
end

function onCreate()
	setPropertyFromClass('substates.GameOverSubstate', 'loopSoundName', 'WindedLoop');
	setPropertyFromClass('substates.GameOverSubstate', 'endSoundName', 'WindedEnd');
end