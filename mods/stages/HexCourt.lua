function onCreate()
	--bars (tight)
	
	bars_tight = {"Sky", "Sun", "Bush", "Wall", "Bar", "Pillar", "Pillar", "Pillar", "Pillar", "Floor", "Ad", "BHoop"} --bhop with an extra o
	local barsTight, n, sName
	local pillars, barsGo = 0, 1
	for bars, tight in ipairs(bars_tight) do
		if tight == "Pillar" then
			sName = "Pillar" .. pillars
			pillars = pillars + 1
		else
			sName = tight
			barsGo = barsGo + 1
		end
		makeAnimatedLuaSprite(sName, "backgrounds/HexCourt/PlantHexStage", -370, -160)
		addAnimationByPrefix(sName, "idle", tight.."0", 24, false)
		scaleObject(sName, (tight == "Sky" or tight == "Bar") and 21 or 1.05, tight == "Sky" and 2.1 or 1.05)
		barsTight = 0.27 + (math.min(barsGo, 4) / 18) + (math.min(barsGo, 5) / 18) + (barsGo / 60)
		setScrollFactor(sName, tight == "Sun" and 0.28 or barsTight, tight == "Sun" and 0.3 or barsTight)
		addLuaSprite(sName, false)
		--debugPrint("add sprite ", sName, " scroll ", barsTight)
	end
	
	setProperty("Pillar0.x", 55 - 370)
	setProperty("Pillar1.x", 628 - 370)
	setProperty("Pillar2.x", 1309 - 370)
	setProperty("Pillar3.x", 1883 - 370)
	setProperty("Pillar2.flipX", true)
	setProperty("Pillar3.flipX", true)
	
	close(true)
end