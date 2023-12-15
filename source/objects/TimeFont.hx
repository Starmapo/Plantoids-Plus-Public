package objects;

class TimeFont extends FlxTypedSpriteGroup<TimeLetter>
{
	public var text(default, set):String = '';

	var image:String;

	public function new(x:Float = 0, y:Float = 0, image:String, text:String = '')
	{
		super(x, y);
		this.image = image;
		this.text = text;
	}

	function reloadLetters()
	{
		forEach(function(spr) spr.destroy());
		clear();

		var curX:Float = 0;
		for (i in 0...text.length)
		{
			var letter = new TimeLetter(curX, 0, image, text.charAt(i));
			add(letter);
			curX += letter.width + 2;
		}
		screenCenter(X);
	}

	function updateLetters()
	{
		for (i in 0...length)
			members[i].changeLetter(text.charAt(i));
	}

	function set_text(value:String)
	{
		if (value == null)
			value = '';
		if (text != value)
		{
			var lastText = text;
			text = value;
			if (lastText.length != text.length)
				reloadLetters();
			else
				updateLetters();
		}
		return text;
	}
}

class TimeLetter extends FlxSprite
{
	public function new(x:Float = 0, y:Float = 0, image:String, letter:String)
	{
		super(x, y);
		loadGraphic(Paths.image(image), true, 47, 53);
		for (i in 0...10)
			animation.add(Std.string(i), [i], 0, false);
		animation.add(':', [10], 0, false);

		scale.scale(0.5);
		antialiasing = ClientPrefs.data.antialiasing;
		changeLetter(letter);
	}

	public function changeLetter(letter:String)
	{
		animation.play(letter);
		updateHitbox();
	}
}
