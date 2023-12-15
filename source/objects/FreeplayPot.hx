package objects;

import backend.Highscore;
import states.FreeplayState.SongMetadata;

class FreeplayPot extends FlxSpriteGroup
{
	var pot:FlxSprite;
	var text:Alphabet;
	var icon:HealthIcon;

	public function new(i:Int, song:SongMetadata)
	{
		super();

		final songName = Paths.formatToSongPath(song.songName);

		var potImage = 'freeplaypots/$songName';
		var hasPot = true;

		if (!Paths.fileExists('images/' + potImage + '.png', IMAGE))
		{
			potImage = 'FreeplayPotUnknown';
			hasPot = false;
		}

		if (Paths.fileExists('images/' + potImage + '-played.png', IMAGE) && Highscore.hasBeatenSong(songName))
			potImage += '-played';

		pot = new FlxSprite().loadGraphic(Paths.image(potImage));
		pot.setGraphicSize(0, FlxG.height);
		pot.updateHitbox();
		pot.antialiasing = ClientPrefs.data.antialiasing;
		add(pot);

		if (!hasPot)
		{
			final textScale = 0.7;

			text = new Alphabet(0, 0, song.songName, true);
			text.setScale(Math.min(textScale, pot.width / text.width), textScale);
			text.x = (pot.width / 2) - (text.width / 2);
			text.y = 430;
			add(text);
		}

		icon = new HealthIcon(song.songCharacter);
		icon.offset.set();
		icon.x = 250 - (icon.width / 2);
		icon.y = 255 - (icon.height / 2);
		icon.scrollFactor.set(1, 1);
		add(icon);

		screenCenter();
		x += 700 * i;
	}
}
