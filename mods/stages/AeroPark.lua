function onCreate()
	--bars (tight)
	
	bars_tight = {"Sky", "BuildingsBack", "Buildings", "Grass", "Fence", "Hills", "Tree", "Sidewalk"}
	local barsTight, n
	for bars, tight in ipairs(bars_tight) do
		makeLuaSprite(tight, "backgrounds/AeroPark/"..tight, -500, (tight == "Fence" or tight == "Grass" or tight == "Hills" or tight == "Sidewalk") and 229 or -320)
		scaleObject(tight, tight == "Sky" and 25 or 0.9, tight == "Sky" and 1.8 or 0.9)
		barsTight = 0.2 + (bars / 9)
		setScrollFactor(tight, barsTight, barsTight)
		if tight ~= "Tree" then
			addLuaSprite(tight, false)
		end
	end
	addLuaSprite("Tree", false)
	
	close(true)
end