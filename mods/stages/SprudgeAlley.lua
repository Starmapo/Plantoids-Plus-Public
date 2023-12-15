function onCreate()
	--bars (tight)
	
	bars_tight = {"layerSky", "layerBuildingsFar", "layerFloorFar", "layerLight", "layerShadow", "layerWall", "layerFloor", "layerHat"}
	local barsTight, n
	for bars, tight in ipairs(bars_tight) do
		makeLuaSprite(tight, "backgrounds/SprudgeAlley/"..tight, -450, -80)
		scaleObject(tight, 0.9, 0.9)
		barsTight = 0.2 + (bars / 9)
		setScrollFactor(tight, barsTight, barsTight)
		addLuaSprite(tight, false)
	end
	
	close(true)
end