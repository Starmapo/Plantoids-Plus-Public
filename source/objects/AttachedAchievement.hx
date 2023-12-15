package objects;

import backend.Achievements;

class AttachedAchievement extends FlxSprite
{
	public var sprTracker:FlxSprite;

	var tag:String;

	public function new(x:Float = 0, y:Float = 0, name:String)
	{
		super(x, y);

		antialiasing = ClientPrefs.data.antialiasing;
		changeAchievement(name);
	}

	public function changeAchievement(tag:String)
	{
		this.tag = tag;
		reloadAchievementImage();
	}

	public function reloadAchievementImage()
	{
		final imagePath = (Achievements.isAchievementUnlocked(tag) ? 'achievements/' + Achievements.getExternalName(tag) : 'achievements/lockedachievement');
		final image = Paths.image(imagePath);

		// prevents "missing bitmap" warning from showing up
		if (image != null)
		{
			final res = Math.floor(image.width / 150);
			if (res > 1)
			{
				loadGraphic(image, true, 150, image.height);
				animation.add('ach', [for (i in 0...res) i], 5, true);
				animation.play('ach');
			}
			else
				loadGraphic(image);
		}

		scale.set(0.7, 0.7);
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null)
			setPosition(sprTracker.x - 130, sprTracker.y + 25);

		super.update(elapsed);
	}
}
