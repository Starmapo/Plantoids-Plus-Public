function onCreate()
	setObjectOrder("gfGroup", getObjectOrder("boyfriendGroup"))
	setObjectOrder("dadGroup", getObjectOrder("boyfriendGroup"))
	
	PlatTiltDir = 4
	DaMoveThingGo = 30
	XDaMoveThingGo = 35

	makeLuaSprite("plat", "backgrounds/AeroTornado/TornadoPlat", 250, 660)
	setScrollFactor("plat", 0.95, 0.95)
	setProperty("plat.origin.y", 120)
	setProperty("plat.angle", 6)

	makeLuaSprite("sky", "backgrounds/AeroTornado/StormSky", -700, -320)
	setScrollFactor("sky", 0.2, 0.7)
	scaleObject("sky", 25, 2.4)

	makeAnimatedLuaSprite("bgThing", "backgrounds/AeroTornado/TornadoBg", -750, -300)
	addAnimationByPrefix("bgThing", "idle", "Tornado bg anim", 12, true)
	setScrollFactor("bgThing", 0.7, 0.6)
	scaleObject("bgThing", 3.5, 3)
	setProperty("bgThing.alpha", 0.6)

	makeAnimatedLuaSprite("fgThing", "backgrounds/AeroTornado/TornadoBg", -1100, -200)
	addAnimationByPrefix("fgThing", "idle", "Tornado bg anim", 12, true)
	setScrollFactor("fgThing", 1.3, 1.2)
	setProperty("fgThing.alpha", 0.2)
	setProperty("fgThing.flipX", true)
	setProperty("fgThing.animation.curAnim.curFrame", 7)
	scaleObject("fgThing", 5, 3)
	
	local function same(n)
		if n == 5 then
			return 4
		end
		return n
	end
	
	if not lowQuality then
		for i = 1, 7 do
			local tight = "BgDebris"..i
			makeLuaSprite(tight, "backgrounds/AeroTornado/Debris"..same(i), -1200, 900)
			scaleObject(tight, 0.82, 0.82)
			setScrollFactor(tight, 0.7, 0.7)
			setProperty(tight..".origin.x", getProperty(tight..".width") / 2)
			setProperty(tight..".origin.y", getProperty(tight..".height") / 2)
			
			local tight = "FgDebris"..i
			makeLuaSprite(tight, "backgrounds/AeroTornado/Debris"..same(i), 2000, 900)
			scaleObject(tight, 1.35, 1.35)
			setScrollFactor(tight, 1.2, 1.2)
			setProperty(tight..".origin.x", getProperty(tight..".width") / 2)
			setProperty(tight..".origin.y", getProperty(tight..".height") / 2)
			setProperty(tight..".alpha", 0.88)
			addLuaSprite(tight, true)
		end
		setProperty("BgDebris5.flipY", true)
		setProperty("FgDebris5.flipY", true)
	end
	
	addLuaSprite("sky", false)
	addLuaSprite("bgThing", false)
	
	if not lowQuality then
		for i = 1, 7 do
			addLuaSprite("BgDebris"..i, false)
			onTweenCompleted((math.random() > 0.5 and "BgDebris" or "FgDebris")..i, "fnuy")
		end
	end
	
	makeLuaSprite("thunderbg", nil, -500, -250)
	makeGraphic("thunderbg", 250, 150, "FFF2AA") --FFE83E
	scaleObject("thunderbg", 10, 10)
	setScrollFactor("thunderbg", 0, 0)
	addLuaSprite("thunderbg")
	setProperty("thunderbg.alpha", 0)
	addLuaSprite("plat", false)
	addLuaSprite("fgThing", true)
	
	onTweenCompleted("PlatTilt")
	onTweenCompleted("DaMoveThing")
	onTweenCompleted("XDaMoveThing")
	
	makeAnimatedLuaSprite("rain", "backgrounds/AeroTornado/RainBg", -700, -320)
	addAnimationByPrefix("rain", "idle", "rainbg", 20, true)
	setScrollFactor("rain", 0.1, 0.1)
	scaleObject("rain", 3, 2)
	addLuaSprite("rain", true)
	setProperty("rain.alpha", 0.3)
	makeLuaSprite("vig", "backgrounds/AeroTornado/Vignette", -700, -320)
	setScrollFactor("vig", 0.1, 0.1)
	scaleObject("vig", 1, 0.8)
	addLuaSprite("vig", true)
	setProperty("vig.alpha", 0.8)
	
	setProperty("bgThing.color", getColorFromHex("596170"))
	setProperty("fgThing.color", getColorFromHex("B1BBCC"))
	setProperty("fgThing.alpha", 0.33)
	
	canThunder = true
	nextThunder = 0
	local function flashThing(n)
		setProperty(n..".color", getColorFromHex("190e00"))
		doTweenColor(n.."flash", n, n == "rain" and "4cffffff" or "ffffff", 2.2, "quartOut")
	end
	local function flashThingAlpha(n)
		setProperty(n..".alpha", 1)
		doTweenAlpha(n.."flashalpha", n, 0, 2.2, "quartOut")
	end
	
	flashThings = {"boyfriend", "gf", "dad", "plat", "rain"}
	for i = 1, 7 do
		table.insert(flashThings, "BgDebris"..i)
		table.insert(flashThings, "FgDebris"..i)
	end
	
	function onBeatHit()
		if canThunder then
			if math.random() < 0.5 then
				playSound("thunder_"..math.random(1, 2))
				for k, v in pairs(flashThings) do
					flashThing(v)
				end
				flashThingAlpha("thunderbg")
				playAnim("boyfriend", "scared", true)
				
				nextThunder = getPropertyFromClass("backend.Conductor", "songPosition") + math.random(4700, 7000)
				canThunder = false
			end
		elseif nextThunder < getSongPosition() then
			canThunder = true
		end
	end
end

function onTweenCompleted(thing, abc)
	if thing == "PlatTilt" then
		PlatTiltDir = 0 - PlatTiltDir
		doTweenAngle("PlatTilt", "plat", PlatTiltDir, 1.6, "sineInOut")
		doTweenY("GfMove", "gfGroup", 368 + (PlatTiltDir * 4), 1.6, "sineInOut")
		return
	end
	if thing == "DaMoveThing" then
		DaMoveThingGo = 0 - DaMoveThingGo
		doTweenY("DaMoveThing", "dadGroup", 250 + DaMoveThingGo, math.random(145, 170) / 100, "sineInOut")
		return
	end
	if thing == "XDaMoveThing" then
		XDaMoveThingGo = 0 - XDaMoveThingGo
		doTweenX("XDaMoveThing", "dadGroup", -200 + XDaMoveThingGo, math.random(185, 225) / 100, "sineInOut")
		return
	end
	local fno = 78
	if abc == "fnuy" then
		fno = math.random(60, 110)
	end
	if string.sub(thing, 0, 8) == "BgDebris" then
		local num = "FgDebris"..string.sub(thing, 9)
		setProperty(num..".x", 2000)
		local tweentime = math.random(130, 170) / fno
		doTweenX(num, num, -1800, tweentime)
		local yPut = math.random(-300, 1200)
		setProperty(thing..".y", yPut)
		doTweenY("Y"..num, num, yPut, tweentime, "sineInOut")
		doTweenAngle("Rot"..num, num, math.random(-180, 180), tweentime)
	end
	if string.sub(thing, 0, 8) == "FgDebris" then
		local num = "BgDebris"..string.sub(thing, 9)
		setProperty(num..".x", -1800)
		local tweentime = math.random(160, 180) / fno
		local yPut = math.random(-300, 1200)
		setProperty(thing..".y", yPut)
		doTweenX(num, num, 2000, tweentime)
		doTweenY("Y"..num, num, yPut, tweentime, "sineInOut")
		doTweenAngle("Rot"..num, num, math.random(-180, 180), tweentime)
	end
end

function onUpdatePost(elapsed)
	target = "dad"
	if (mustHitSection) then
		target = ""
	end
	cameraSetTarget(target)
end