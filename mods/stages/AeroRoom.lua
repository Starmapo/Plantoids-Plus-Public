function onCreatePost()
	makeLuaSprite("mirror", "backgrounds/AeroRoom/mirror", 0, -170)
	setGraphicSize("mirror", 725, 725)
	screenCenter("mirror", "x")
	addLuaSprite("mirror")
	
	makeLuaSprite("overlay", "backgrounds/AeroRoom/overlay")
	screenCenter("overlay")
	addLuaSprite("overlay")
	
	setObjectOrder("boyfriendGroup", getObjectOrder("overlay"))
	
	for i = 0, getProperty("playerStrums.length") - 1 do
		if not middlescroll then
			setPropertyFromGroup("playerStrums", i, "x", getPropertyFromGroup("playerStrums", i, "x") - getPropertyFromClass("states.PlayState", "STRUM_X") + getPropertyFromClass("states.PlayState", "STRUM_X_MIDDLESCROLL"))
		end
		setPropertyFromGroup("opponentStrums", i, "alpha", 0)
	end
	runHaxeCode([[
		var i = 0;
		while (i < game.opponentStrums.length)
			FlxTween.cancelTweensOf(game.opponentStrums.members[i++]);
	]])
end