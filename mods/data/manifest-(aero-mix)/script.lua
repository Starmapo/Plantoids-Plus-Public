function onCreate()
	precacheImage('blinds');
	setPropertyFromClass('substates.GameOverSubstate', 'loopSoundName', 'STORMEDLoop');
	setPropertyFromClass('substates.GameOverSubstate', 'endSoundName', 'STORMEDEnd');
end

function onStepHit()
	if curStep == 1888 then
		makeLuaSprite('image', 'blinds', -400, -120);
		setScrollFactor('image', 1, 1);
		addLuaSprite('image', true);

	end
end