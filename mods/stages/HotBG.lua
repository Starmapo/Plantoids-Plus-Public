function onCreate()
	makeLuaSprite("hotbg", "He_is_looking_respectfully", -80, 0)
	setScrollFactor("hotbg", 0.6, 0.77)
	addLuaSprite("hotbg", false)
	
	addLuaScript("data/scripts/playerSwap")
end

function onCreatePost()
	makeLuaSprite("bbtop", nil, 0, 0)
	makeGraphic("bbtop", screenWidth, math.floor(screenHeight / 6), "000000")
	setScrollFactor("bbtop", 0, 0)
	setObjectCamera("bbtop", "hud")
	makeLuaSprite("bbbot", nil, 0, math.floor((screenHeight / 6) * 5))
	makeGraphic("bbbot", screenWidth, math.floor(screenHeight / 6), "000000")
	setScrollFactor("bbbot", 0, 0)
	setObjectCamera("bbbot", "hud")
	addLuaSprite("bbtop", false)
	addLuaSprite("bbbot", false)
end

function charnote(ch, dir)
	local t = dir < 0 and 0.7 or 0.4
	setProperty(ch..".y", 190)
	setProperty(ch..".x", 50)
	doTweenY(ch, ch, 170, t, "expoout")
end

function onBeatHit()
	charnote("boyfriend", -1)
	charnote("dad", -1)
end

function goodNoteHit(_, dir)
	charnote("boyfriend", dir)
end

function opponentNoteHit(_, dir)
	charnote("dad", dir)
end

function noteMissPress(dir)
	charnote("boyfriend", dir)
end

noteMiss = goodNoteHit