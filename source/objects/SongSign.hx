package objects;

import backend.UIData;

// i'm making this a class because we are cool!
// also making a spritegroup instead of attached sprites is better
class SongSign extends FlxSpriteGroup
{
	static var maxTextWidth:Int = 201;

	static function scaleSize(text:FlxText)
	{
		return FlxMath.maxInt(Math.floor(text.size * (maxTextWidth / text.width)), 1);
	}

	public var sign:FlxSprite;
	public var album:FlxSprite;
	public var name:FlxText;
	public var composer:FlxText;

	public function new(x:Float = 0, y:Float = 0, ?uiFile:UIFile)
	{
		super(x, y);

		var song = PlayState.SONG;

		sign = new FlxSprite(0, 0, Paths.image(uiFile != null ? uiFile.songSign : UIData.DEFAULT_SONG_SIGN));
		sign.antialiasing = ClientPrefs.data.antialiasing;

		album = new FlxSprite(4, 4, CoolUtil.getImageOrPlaceholder('albumcovers/', Paths.formatToSongPath(song.song), 'placeholder'));
		album.setGraphicSize(87, 87);
		album.updateHitbox();
		album.antialiasing = ClientPrefs.data.antialiasing;

		name = new FlxText(album.width + 6, 4, 0, song.song);
		name.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		if (name.width > maxTextWidth)
			name.size = scaleSize(name);

		var daComposer = '';
		if (song.composer != null && song.composer.length > 0)
		{
			for (i in 0...song.composer.length - 1)
				daComposer += song.composer[i] + '\n';
			daComposer += song.composer[song.composer.length - 1];
		}
		composer = new FlxText(name.x, 6 + name.height, 0, daComposer);
		composer.setFormat('VCR OSD Mono', 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		if (composer.width > maxTextWidth)
			composer.size = scaleSize(composer);

		var textHeight = name.height + composer.height + 10;
		if (textHeight > sign.height)
		{
			sign.setGraphicSize(Std.int(sign.width), Std.int(textHeight));
			sign.updateHitbox();
		}

		add(sign);
		add(album);
		add(name);
		add(composer);

		scrollFactor.set();
	}
}
