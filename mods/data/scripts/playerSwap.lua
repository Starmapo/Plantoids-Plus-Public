function onCountdownStarted()
	local playerX = nil
	for i = 0, getProperty("playerStrums.length") - 1 do
		playerX = getPropertyFromGroup("playerStrums", i, "x")
		setPropertyFromGroup("playerStrums", i, "x", getPropertyFromGroup("opponentStrums", i, "x"))
		setPropertyFromGroup("opponentStrums", i, "x", playerX)
	end
	
	setProperty("healthBar.leftToRight", true)
	local leftColor = getProperty("healthBar.leftBar.color")
	setProperty("healthBar.leftBar.color", getProperty("healthBar.rightBar.color"))
	setProperty("healthBar.rightBar.color", leftColor)
	setProperty("iconP1.flipX", true)
	setProperty("iconP2.flipX", true)
end

barCenter = nil
iconOffset = 26
doubleIconOffset = iconOffset * 2
function onUpdatePost(e)
	barCenter = getProperty("healthBar.barCenter")
	setProperty("iconP1.x", barCenter - (150 * getProperty("iconP1.scale.x")) / 2 - doubleIconOffset)
	setProperty("iconP2.x", barCenter + (150 * getProperty("iconP2.scale.x") - 150) / 2 - iconOffset)
end