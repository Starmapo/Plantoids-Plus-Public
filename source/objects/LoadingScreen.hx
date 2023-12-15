package objects;

class LoadingScreen extends FlxTypedGroup<FlxSprite>
{
	var nextUpdateFunction:Void->Void;
	var nextUpdateTimer:Int = 0;

	public function new()
	{
		super();

		visible = false;

		var bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

		var text = new FlxText(0, 0, 0, "Loading...", 32);
		text.screenCenter();
		text.scrollFactor.set();
		add(text);
	}

	override function update(elapsed)
	{
		if (nextUpdateFunction != null)
		{
			nextUpdateTimer--;

			if (nextUpdateTimer <= 0)
			{
				nextUpdateFunction();
				nextUpdateFunction = null;
			}
		}

		super.update(elapsed);
	}

	public function show(func:Void->Void)
	{
		visible = true;
		nextUpdateFunction = function()
		{
			func();
			visible = false;
		};
		nextUpdateTimer = 2;
	}
}
