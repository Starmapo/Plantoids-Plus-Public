local allowCountdown = false
ended = 0
function onCreate()
	setPropertyFromClass('substates.GameOverSubstate', 'loopSoundName', 'STORMEDLoop');
	setPropertyFromClass('substates.GameOverSubstate', 'endSoundName', 'STORMEDEnd');
end

function onStartCountdown()
	-- Block the first countdown and start a timer of 0.8 seconds to play the dialogue
	if not allowCountdown and isStoryMode and not seenCutscene and string.lower(difficultyName) ~= "bfhard" then --b fhard
		setProperty('inCutscene', true);
		runTimer('startDialogue', 2);
		
		makeLuaSprite('image', nil, -1000, -120);
		makeGraphic("image", 2560, 1400, "000000")
		setScrollFactor('image', 1, 1);
		addLuaSprite('image', true);

		doTweenAlpha('byebye', 'image', 0, 2);

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

function onEndSong()
	if not (isStoryMode and string.lower(difficultyName) ~= "bfhard") then return Function_Continue end
	makeLuaSprite("endStuff", "epilogues/aeroepilogue", 0, 0)
	setProperty("endStuff.scale.x", screenWidth / getProperty("endStuff.width"))
	setProperty("endStuff.scale.y", screenHeight / getProperty("endStuff.height"))
	setProperty("endStuff.alpha", 0)
	setObjectCamera("endStuff", "hud")
	setObjectOrder("endStuff", getProperty("members.length"))
	addLuaSprite("endStuff", true)
	screenCenter("endStuff")
	
	ended = 1
	doTweenAlpha("fun", "endStuff", 1, 1)
	function onEndSong() end
	return Function_Stop
end

function onUpdate()
	if ended == 1 then
		if ((keyJustPressed("back") or keyJustPressed("pause") or keyJustPressed("accept"))) then
			endSong()
		end
	end
end