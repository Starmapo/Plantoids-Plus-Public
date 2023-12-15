luaDebugMode = true
addedBoxes = {}

function onCreate()
	if songPlayedInSession() and not getPropertyFromClass("states.PlayState", "chartingMode") then
		close()
	end
end

function onUpdatePost()
	for k,v in ipairs(addedBoxes) do
		if getProperty(v..".animation.finished") then
			removeLuaSprite(v)
			table.remove(addedBoxes, k)
		end
	end
end

function onEventPushed(name, value1, value2, strumTime)
	if name == "Spawn Character Box" then
		local s = split(value1, ",")
		local tag = s[1].."Box"
		
		makeAnimatedLuaSprite(tag, "charboxes/"..s[1].."CharacterCard")
		addAnimationByPrefix(tag, "anim", tag.."Anim", 24, false)
	end
end

function onEvent(name, value1, value2, strumTime)
	if name == "Spawn Character Box" then
		local s = split(value1, ",")
		local pos = split(value2, ",")
		
		local tag = s[1].."Box"
		local char = s[2] or "dad"
		local side = s[3] or (char == "boyfriend" and "left" or "right")
		
		local posX = side == "left" and -37 or -42
		local posY = -152 + getProperty(char..".y") + (getProperty(char..".height") / 2)
		
		if side == "right" then
			posX = posX + getProperty(char..".x") + getProperty(char..".width")
		elseif side == "left" then
			posX = posX + getProperty(char..".x") - getProperty(tag..".width")
		end
		
		if pos[1] then
			posX = posX + tonumber(pos[1])
		end
		if pos[2] then
			posY = posY + tonumber(pos[2])
		end
		
		setProperty(tag..".x", posX)
		setProperty(tag..".y", posY)
		addLuaSprite(tag, true)
		playAnim(tag, "anim", true)
		
		table.insert(addedBoxes, tag)
	end
end

function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end
