package objects;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;

class HealthBar extends FlxSpriteGroup
{
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;
	public var bg:FlxSprite;
	public var valueFunction:Void->Float = function() return 0;
	public var percent(default, set):Float = 0;
	public var bounds:Dynamic = {min: 0, max: 1};
	public var leftToRight(default, set):Bool = true;
	public var barCenter(default, null):Float = 0;

	// you might need to change this if you want to use a custom bar
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = FlxPoint.get(3, 3);
	public var barScale(default, set):Bool = true;

	public function new(x:Float, y:Float, image:String = 'healthBar', valueFunction:Void->Float = null, boundX:Float = 0, boundY:Float = 1,
			bgUnder:Bool = false)
	{
		super(x, y);

		if (valueFunction != null)
			this.valueFunction = valueFunction;
		setBounds(boundX, boundY);

		bg = new FlxSprite().loadGraphic(Paths.image(image));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		barWidth = Std.int(bg.width - 6);
		barHeight = Std.int(bg.height - 6);

		leftBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
		// leftBar.color = FlxColor.WHITE;
		leftBar.antialiasing = antialiasing = ClientPrefs.data.antialiasing;

		rightBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
		rightBar.color = FlxColor.BLACK;
		rightBar.antialiasing = ClientPrefs.data.antialiasing;

		if (bgUnder)
			add(bg);
		add(leftBar);
		add(rightBar);
		if (!bgUnder)
			add(bg);
		regenerateClips();
	}

	override function update(elapsed:Float)
	{
		var value:Null<Float> = FlxMath.remapToRange(FlxMath.bound(valueFunction(), bounds.min, bounds.max), bounds.min, bounds.max, 0, 100);
		percent = (value != null ? value : 0);
		super.update(elapsed);
	}

	public function setBounds(min:Float, max:Float)
	{
		bounds.min = min;
		bounds.max = max;
	}

	public function setColors(left:FlxColor, right:FlxColor)
	{
		leftBar.color = left;
		rightBar.color = right;
	}

	public function updateBar()
	{
		if (leftBar == null || rightBar == null)
			return;

		leftBar.setPosition(bg.x, bg.y);
		rightBar.setPosition(bg.x, bg.y);
		if (!barScale)
		{
			rightBar.x = leftBar.x += barOffset.x;
			rightBar.y = leftBar.y += barOffset.y;
		}

		var leftSize:Float = 0;
		if (leftToRight)
			leftSize = FlxMath.lerp(0, barWidth, percent / 100);
		else
			leftSize = FlxMath.lerp(0, barWidth, 1 - percent / 100);

		leftBar.clipRect.width = leftSize;
		leftBar.clipRect.height = barHeight;
		if (barScale)
		{
			leftBar.clipRect.x = barOffset.x;
			leftBar.clipRect.y = barOffset.y;
		}
		else
			leftBar.clipRect.setPosition(0, 0);

		rightBar.clipRect.width = barWidth - leftSize;
		rightBar.clipRect.height = barHeight;
		if (barScale)
		{
			rightBar.clipRect.x = barOffset.x + leftSize;
			rightBar.clipRect.y = barOffset.y;
		}
		else
			rightBar.clipRect.setPosition(leftSize, 0);

		barCenter = leftBar.x + leftSize + barOffset.x;

		leftBar.clipRect = leftBar.clipRect;
		rightBar.clipRect = rightBar.clipRect;
	}

	public function regenerateClips()
	{
		if (leftBar != null)
		{
			if (barScale)
				leftBar.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			else
				leftBar.scale.set(1, 1);
			leftBar.updateHitbox();
			FlxDestroyUtil.put(leftBar.clipRect);
			leftBar.clipRect = FlxRect.get(0, 0, Std.int(leftBar.width), Std.int(leftBar.height));
		}
		if (rightBar != null)
		{
			if (barScale)
				rightBar.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			else
				rightBar.scale.set(1, 1);
			rightBar.updateHitbox();
			FlxDestroyUtil.put(rightBar.clipRect);
			rightBar.clipRect = FlxRect.get(0, 0, Std.int(rightBar.width), Std.int(rightBar.height));
		}
		updateBar();
	}

	override function destroy()
	{
		super.destroy();
		barOffset = FlxDestroyUtil.put(barOffset);
	}

	private function set_percent(value:Float)
	{
		var doUpdate:Bool = false;
		if (value != percent)
			doUpdate = true;
		percent = value;

		if (doUpdate)
			updateBar();
		return value;
	}

	private function set_leftToRight(value:Bool)
	{
		leftToRight = value;
		updateBar();
		return value;
	}

	private function set_barWidth(value:Int)
	{
		barWidth = value;
		regenerateClips();
		return value;
	}

	private function set_barHeight(value:Int)
	{
		barHeight = value;
		regenerateClips();
		return value;
	}

	function set_barScale(value:Bool)
	{
		barScale = value;
		regenerateClips();
		return value;
	}
}
