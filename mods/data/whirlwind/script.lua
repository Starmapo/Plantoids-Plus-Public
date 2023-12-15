local allowCountdown = false
function onStartCountdown()
	-- Block the first countdown and start a timer of 0.8 seconds to play the dialogue
	if not allowCountdown and isStoryMode and not seenCutscene and string.lower(difficultyName) ~= "bfhard" then --b fhard
		setProperty('inCutscene', true);
		runTimer('startDialogue', 0.8);
		allowCountdown = true;
		return Function_Stop;
	end
	return Function_Continue;
end

function onCreate()
	setPropertyFromClass('substates.GameOverSubstate', 'loopSoundName', 'WindedLoop');
	setPropertyFromClass('substates.GameOverSubstate', 'endSoundName', 'WindedEnd');
	makeAnimatedLuaSprite("SpeakersIdle", "aerocutscene/AsmodieFly", 588, 395)
	addAnimationByPrefix("SpeakersIdle", "idle", "speakers")
	addLuaSprite("SpeakersIdle")
	setProperty("SpeakersIdle.visible", false)
	makeLuaSprite("HatFly", "aerocutscene/TaihHat", 700, 310)
	setProperty("HatFly.angle", 45)
	setProperty("HatFly.visible", false)
	addLuaSprite("HatFly", true)
	
	if isStoryMode and string.lower(difficultyName) ~= "bfhard" then
		addCharacterToList("bf-taih-aero-cutscene-idle", "bf")
		addCharacterToList("gf-asmodie-aero-cutscene-idle", "gf")
		addCharacterToList("aero-cutscene-idle", "dad")
		addCharacterToList("bf-taih-aero-cutscene", "bf")
		addCharacterToList("gf-asmodie-aero-cutscene", "gf")
		addCharacterToList("aero-cutscene", "dad")
		precacheImage("backgrounds/AeroTornado/TornadoBg")
		precacheDialogue('dialogueEnd')
	end
end

local isEndSong = 0

function onEndSong()
	if not (isStoryMode and string.lower(difficultyName) ~= "bfhard") then return Function_Continue end
	if isEndSong == 0 then
		isEndSong = 3
		
		startDialogue("dialogueEnd")
		
		triggerEvent("Change Character", "bf", "bf-taih-aero-cutscene-idle")
		triggerEvent("Change Character", "gf", "gf-asmodie-aero-cutscene-idle")
		triggerEvent("Change Character", "dad", "aero-cutscene-idle")

		makeAnimatedLuaSprite("fgThing", "backgrounds/AeroTornado/TornadoBg", -1100, -320)
		addAnimationByPrefix("fgThing", "idle", "Tornado bg anim", 20, true)
		setScrollFactor("fgThing", 1.3, 0)
		setProperty("fgThing.alpha", 0)
		setProperty("fgThing.flipX", true)
		scaleObject("fgThing", 5, 3)
		addLuaSprite("fgThing", true)

		makeLuaSprite("blackThing", "backgrounds/AeroTornado/TornadoBg", -1100, -500)
		makeGraphic("blackThing", 100, 100, "000000")
		setScrollFactor("blackThing", 0, 0)
		setProperty("blackThing.alpha", 0)
		setProperty("blackThing.flipX", true)
		scaleObject("blackThing", 50, 30)
		addLuaSprite("blackThing", true)
		
		return Function_Stop
	end
	if isEndSong == 3 then
		isEndSong = 4
		
		triggerEvent("Change Character", "dad", "aero-cutscene")
		
		triggerEvent("Play Animation", "hey", "dad")
		setProperty("dad.heyTimer", 99)
		setProperty("dad.specialAnim", true)
		doTweenZoom("zoom", "camGame", 0.65, 1.2, "sineIn")
		setProperty("inCutscene", false)
		setProperty("camFollow.x", 500)
		setProperty("camFollow.y", 350)
		playSound("aerotransform")
		
		runTimer("theyStartToFly", 1)
		runTimer("theyFly", 1.3)
		runTimer("hatFly", 1 + 0.4)
		--runTimer("cutEnd", 4.5)
		runTimer("blackScreen", 4)
		
		triggerEvent("Screen Shake", "0.9,0.002", "0.9,0.001")
		
		doTweenAlpha("TornadoFGAppear", "fgThing", 1, 4, "sineIn")
		doTweenAlpha("HudDisappear", "camHUD", 0, 4, "sineIn")
		return Function_Stop
	end
end

function onTimerCompleted(tag, loops, loopsLeft)
	if (tag == "theyStartToFly") then
		triggerEvent("Change Character", "bf", "bf-taih-aero-cutscene")
		triggerEvent("Change Character", "gf", "gf-asmodie-aero-cutscene")
		setProperty("gf.x", getProperty("gf.x") + 60)
		setProperty("gf.y", getProperty("gf.y") - 200)
		setProperty("SpeakersIdle.visible", true)
		triggerEvent("Play Animation", "singUP", "bf")
		triggerEvent("Play Animation", "hey", "gf")
		setProperty("boyfriend.heyTimer", 99)
		setProperty("gf.heyTimer", 99)
		triggerEvent("Screen Shake", "0.3,0.01", "0.3,0.01")
		return
	end
	if (tag == "hatFly") then
		setProperty("HatFly.visible", true)
		doTweenX("HatFlyX", "HatFly", 1900, 1.5, "sineIn")
		doTweenY("HatFlyY", "HatFly", -1600, 2, "quadIn")
		doTweenAngle("HatFlyAng", "HatFly", 600, 2, "sineIn")
	end
	if (tag == "theyFly") then
		doTweenAngle("AsmFlyAng", "gfGroup", 1200, 4, "sineIn")
		doTweenX("AsmFlyX", "gfGroup", 1900, 4, "sineIn")
		doTweenY("AsmFlyY", "gfGroup", -2400, 4, "sineIn")
		doTweenAngle("TaiFlyAng", "boyfriendGroup", 1800, 4, "sineIn")
		doTweenX("TaiFlyX", "boyfriendGroup", 2000, 4, "sineIn")
		doTweenY("TaiFlyY", "boyfriendGroup", -4100, 4, "sineIn")
		doTweenX("SpkFlyX", "SpeakersIdle", 3000, 6, "sineIn")
		doTweenY("SpkFlyY", "SpeakersIdle", -4000, 6, "sineIn")
		doTweenAngle("SpkFlyAng", "SpeakersIdle", 800, 6, "sineIn")
		doTweenY("camUp", "camFollow", -800, 7, "cubeIn")
		doTweenX("camRt", "camFollow", 900, 7, "sineIn")
		doTweenZoom("zoom", "camGame", 0.55, 4, "sineIn")
		triggerEvent("Screen Shake", "3,0.002", "3,0.002")
	end
	if (tag == "blackScreen") then
		doTweenAlpha("BlackAppear", "blackThing", 1, 1.25, "sineIn")
	end
	if tag == 'startDialogue' then -- Timer completed, play dialogue
		startDialogue('dialogue');
	end
end

function onTweenCompleted(n)
	if (n == "BlackAppear") then
		return endSong()
	end
end