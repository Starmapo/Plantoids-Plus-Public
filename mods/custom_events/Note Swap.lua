-- Event notes hooks
alreadySwapped = false;

function onEvent(name, value1, value2)
	if name == "Note Swap" and not middlescroll then
		local strumLength = getProperty("playerStrums.length")
		for i = 0, strumLength - 1 do
			j = (i + strumLength)

			iPos = _G['defaultPlayerStrumX'..i];
			jPos = _G['defaultOpponentStrumX'..i];
			if alreadySwapped then
				iPos = _G['defaultOpponentStrumX'..i];
				jPos = _G['defaultPlayerStrumX'..i];
			end
			noteTweenX('note'..i..'TwnX', i, iPos, 0.001, 'quadInOut');
			noteTweenX('note'..j..'TwnX', j, jPos, 0.001, 'quadInOut');
		end
		alreadySwapped = not alreadySwapped;
	end
end