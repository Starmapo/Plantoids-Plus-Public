package objects;

import backend.Achievements;

class AchievementPopup extends FlxSpriteGroup
{
	public var onFinish:Void->Void = null;

	var alphaTween:FlxTween;

	public function new(name:String, ?camera:FlxCamera = null)
	{
		super();
		ClientPrefs.saveSettings();

		var id:Int = Achievements.getAchievementIndex(name);
		var achievement = Achievements.loadedAchievements[id];

		var achievementBorder:FlxSprite = new FlxSprite(60, 50).makeGraphic(430, 130, FlxColor.WHITE);
		achievementBorder.scrollFactor.set();

		var achievementBG:FlxSprite = new FlxSprite(achievementBorder.x + 5,
			achievementBorder.y + 5).makeGraphic(Std.int(achievementBorder.width - 10), Std.int(achievementBorder.height - 10), FlxColor.BLACK);
		achievementBG.scrollFactor.set();

		var achievementIcon = new AttachedAchievement(achievementBG.x + 10, achievementBG.y + 10, name);
		achievementIcon.scrollFactor.set();
		achievementIcon.scale.scale(2 / 3);
		achievementIcon.updateHitbox();

		var achievementName:FlxText = new FlxText(achievementIcon.x + achievementIcon.width + 20, achievementIcon.y + 16, 280, achievement.displayName, 16);
		achievementName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementName.scrollFactor.set();

		var achievementText:FlxText = new FlxText(achievementName.x, achievementName.y + 32, 280, achievement.description, 16);
		achievementText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementText.scrollFactor.set();

		add(achievementBorder);
		add(achievementBG);
		add(achievementName);
		add(achievementText);
		add(achievementIcon);

		var cam:Array<FlxCamera> = camera != null ? [camera] : null;
		cameras = cam;

		alpha = 0;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {
			onComplete: function(twn:FlxTween)
			{
				alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
					startDelay: 2.5,
					onComplete: function(twn:FlxTween)
					{
						alphaTween = null;
						if (onFinish != null)
							onFinish();
					}
				});
			}
		});
	}

	override function destroy()
	{
		if (alphaTween != null)
			alphaTween.cancel();

		super.destroy();
	}
}
