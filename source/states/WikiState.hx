package states;

import backend.Achievements;
import backend.Highscore;
import backend.WeekData;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.util.FlxSpriteUtil;
import haxe.io.Path;
import objects.ScrollBar;
import openfl.geom.Rectangle;
import sys.FileSystem;
import sys.io.File;

class WikiState extends MusicBeatState
{
	public static function formatCharName(char:String)
	{
		return char.replace(' ', '');
	}

	static final scrollBarWidth:Int = 20;
	static final renderWidth:Int = 400;
	static final renderHeight:Int = 500;
	static final descWidth:Int = 576;

	var camIcons:FlxCamera;
	var camOther:FlxCamera;
	var iconsGroup:FlxTypedGroup<CharacterIcon>;
	var bios:Array<Bio> = [];
	var iconsScrollBar:ScrollBar;
	var mousePos:Float;
	var scrollBarPos:Float;
	var iconsHeight:Float;
	var curSelected:Int = -1;
	var iconPanelBG:FlxUI9SliceSprite;
	var iconSelection:FlxSprite;
	var renderBG:FlxUI9SliceSprite;
	var render:FlxSprite;
	var nameText:FlxText;
	var descTextGroup:FlxTypedGroup<FlxText>;
	var linesGroup:FlxTypedGroup<FlxSprite>;
	var wikiLinkButton:FlxUIButton;
	var descScrollBar:ScrollBar;
	var camDesc:FlxCamera;

	override function create()
	{
		persistentUpdate = true;

		FlxG.camera.bgColor = 0xFFFFE97F;
		camIcons = new FlxCamera(14, 14, 200, FlxG.height - 28);
		camIcons.bgColor = 0;
		FlxG.cameras.add(camIcons, false);

		iconPanelBG = new FlxUI9SliceSprite(10, 10, Paths.image('wiki/panelBG'),
			new Rectangle(0, 0, camIcons.width + scrollBarWidth + 12, camIcons.height + 8), [6, 6, 11, 11]);
		add(iconPanelBG);

		iconsGroup = new FlxTypedGroup();
		iconsGroup.cameras = [camIcons];
		add(iconsGroup);

		WeekData.reloadWeekFiles(false);

		for (path in [Paths.getPreloadPath(), Paths.mods()])
			pushBios(path);

		for (mod in Mods.parseList().enabled)
			pushBios(Path.join([Paths.mods(), mod]), mod);

		for (i in 0...bios.length)
		{
			final bio = bios[i];
			Mods.currentModDirectory = bio.mod;

			final icon = new CharacterIcon(0, 200 * i, bio);
			icon.x += (200 - icon.width) / 2;
			icon.y += (200 - icon.width) / 2;
			iconsGroup.add(icon);
		}

		Mods.loadTopMod();

		iconSelection = new FlxSprite().makeGraphic(200, 200, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(iconSelection, 0, 0, iconSelection.width, iconSelection.height, 10, 10, FlxColor.WHITE);
		iconSelection.alpha = 0.5;
		iconSelection.cameras = [camIcons];
		add(iconSelection);

		iconsScrollBar = new ScrollBar(camIcons.x + camIcons.width + 4, camIcons.y, iconsGroup.length * 200, camIcons);
		add(iconsScrollBar);

		renderBG = new FlxUI9SliceSprite(FlxG.width - 10, 10, Paths.image('wiki/panelBG'), new Rectangle(0, 0, renderWidth + 8, renderHeight + 8),
			[6, 6, 11, 11]);
		renderBG.x -= renderBG.width;
		add(renderBG);

		render = new FlxSprite();
		render.antialiasing = ClientPrefs.data.antialiasing;
		add(render);

		nameText = new FlxText(iconPanelBG.x + iconPanelBG.width + 10, 10);
		nameText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(nameText);

		descTextGroup = new FlxTypedGroup();
		add(descTextGroup);

		linesGroup = new FlxTypedGroup();
		linesGroup.add(createLine(nameText.x));
		add(linesGroup);

		final camY = Std.int(nameText.y + nameText.height + 18);
		camDesc = new FlxCamera(Std.int(nameText.x), camY, descWidth, FlxG.height - camY - 4);
		camDesc.bgColor = 0;
		FlxG.cameras.add(camDesc, false);
		descTextGroup.cameras = [camDesc];

		descScrollBar = new ScrollBar(camDesc.x + camDesc.width + 4, camDesc.y, 0, camDesc);
		add(descScrollBar);

		wikiLinkButton = new FlxUIButton(renderBG.x, renderBG.y + renderBG.height + 50, 'Advendure Wiki Page', goToPage);
		wikiLinkButton.label.size = 32;
		wikiLinkButton.resize(renderBG.width, 120);
		wikiLinkButton.autoCenterLabel();
		wikiLinkButton.color = FlxColor.GREEN;
		wikiLinkButton.label.color = 0xFFFF00F2;
		add(wikiLinkButton);

		updateSelection(0, false);

		camOther = new FlxCamera();
		camOther.bgColor = 0;
		FlxG.cameras.add(camOther, false);
		CustomFadeTransition.nextCamera = camOther;

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.mouse.justPressed && !CoolUtil.mouseOverlaps(iconsScrollBar))
		{
			for (i in 0...iconsGroup.length)
			{
				if (CoolUtil.mouseOverlaps(iconsGroup.members[i], camIcons))
				{
					updateSelection(i);
					break;
				}
			}
		}

		if (controls.UI_UP_P && curSelected > 0)
			moveSelection(-1);
		if (controls.UI_DOWN_P && curSelected < bios.length - 1)
			moveSelection(1);

		if (controls.ACCEPT)
			goToPage();

		if (controls.BACK)
		{
			persistentUpdate = false;
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new MainMenuState());
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (!FlxG.mouse.visible)
			FlxG.mouse.visible = true;

		super.update(elapsed);
	}

	function updateSelection(id:Int, playSound:Bool = true)
	{
		if (curSelected == id)
			return;

		curSelected = id;

		iconSelection.y = curSelected * 200;

		final bio = bios[curSelected];
		Mods.currentModDirectory = bio.mod;

		final renderPath = 'wiki/renders/' + formatCharName(bio.char) + 'Render';
		if (Paths.fileExists('images/$renderPath.png', IMAGE))
		{
			render.loadGraphic(Paths.image(renderPath));

			if (render.width > renderWidth || render.height > renderHeight)
			{
				final widthScale = (renderWidth / render.width);
				final heightScale = (renderHeight / render.height);

				if (widthScale <= heightScale)
					render.scale.x = render.scale.y = widthScale;
				else
					render.scale.x = render.scale.y = heightScale;
			}
			else
				render.scale.set(1, 1);
			render.updateHitbox();

			render.x = renderBG.x + (renderBG.width / 2) - (render.width / 2);
			render.y = renderBG.y + (renderBG.height / 2) - (render.height / 2);

			render.visible = true;
		}
		else
			render.visible = false;
		render.color = bio.unlocked ? FlxColor.WHITE : FlxColor.BLACK;

		nameText.text = bio.unlocked ? bio.char : '???';
		nameText.color = bio.color;

		final line = linesGroup.members[0];
		line.y = nameText.y + nameText.height + 4;
		line.color = bio.color;
		line.setGraphicSize(Std.int(nameText.width), Std.int(line.height));
		line.updateHitbox();

		descTextGroup.forEach(function(spr) spr.destroy());
		descTextGroup.clear();

		var i = linesGroup.length - 1;
		while (i >= 1)
		{
			final line = linesGroup.members[i--];
			linesGroup.remove(line, true);
			line.destroy();
		}

		var desc = bio.unlocked ? bio.desc : '';
		if (!bio.unlocked && bio.unlockCondition.length > 0)
			desc = 'How to unlock: ' + bio.unlockCondition;

		final splitText = desc.split('<line>');
		var curY:Float = 0;
		var height:Float = 0;
		for (i in 0...splitText.length)
		{
			final descText = new FlxText(0, curY, descWidth, splitText[i].trim());
			descText.setFormat('VCR OSD Mono', 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			descTextGroup.add(descText);

			curY += descText.height + 4;
			height += descText.height + 4;

			if (i < splitText.length - 1)
			{
				final line = createLine(0, curY, Std.int(descText.width), bio.color);
				line.cameras = [camDesc];
				linesGroup.add(line);

				curY += line.height + 4;
				height += line.height + 4;
			}
		}

		camDesc.scroll.y = 0;
		descScrollBar.contentHeight = height;
		descScrollBar.active = descScrollBar.visible = (camDesc.height <= height);

		wikiLinkButton.visible = (bio.wikiPage != null && bio.wikiPage.length > 0 && bio.unlocked);
		if (wikiLinkButton.visible)
		{
			if (bio.wikiPage.startsWith('\\f'))
				wikiLinkButton.label.text = "Funkipedia Mods Wiki Page";
			else
				wikiLinkButton.label.text = "Advendure Wiki Page";
		}

		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	inline function createLine(x:Float = 0, y:Float = 0, width:Int = 1, color:FlxColor = FlxColor.WHITE)
	{
		return new FlxSprite(x, y).makeGraphic(width, 10, color);
	}

	function moveSelection(change:Int)
	{
		updateSelection(curSelected + change);

		final midpoint = iconsGroup.members[curSelected].getMidpoint();
		camIcons.scroll.y = FlxMath.bound(midpoint.y - camIcons.height * 0.5, 0, iconsScrollBar.contentHeight - camIcons.height);
		midpoint.put();

		iconsScrollBar.updateBarPosition();
	}

	function goToPage()
	{
		var page = bios[curSelected].wikiPage;
		if (page != null && page.length > 0)
		{
			var address = "https://advendure-plantoids.fandom.com/wiki/";
			if (page.startsWith('\\f'))
			{
				page = page.substr(2);
				address = "https://fridaynightfunking.fandom.com/wiki/";
			}

			FlxG.openURL(address + page);
		}
	}

	function pushBios(path:String, mod:String = '')
	{
		Mods.currentModDirectory = mod;

		final wikiBios = CoolUtil.coolTextFile(Path.join([path, 'data/wikiBios.txt']));
		for (bio in wikiBios)
		{
			final splitBio = bio.split(':');

			final unlocked = switch (splitBio[2])
			{
				case 'week': StoryMenuState.weekCompleted.exists(splitBio[3]);
				case 'song': Highscore.hasBeatenSong(splitBio[3]);
				case 'achievement': Achievements.isAchievementUnlocked((mod.length > 0 ? mod + ':' : '') + splitBio[3]);
				default: true;
			}

			final descPath = Path.join([path, 'data/bios/' + formatCharName(splitBio[0]) + '.txt']);

			bios.push({
				char: splitBio[0],
				unlocked: unlocked,
				desc: FileSystem.exists(descPath) ? File.getContent(descPath) : '',
				color: CoolUtil.colorFromString(splitBio[1]),
				unlockCondition: switch (splitBio[2])
				{
					case 'week':
						'Complete the week named "' + WeekData.weeksLoaded.get(splitBio[3]).storyName + '".';
					case 'song':
						'Complete the song named "' + splitBio[3] + '".';
					case 'achievement':
						'Earn the achievement named "' + splitBio[3] + '".';
					default:
						splitBio[3];
				},
				wikiPage: splitBio[4],
				mod: mod
			});
		}
	}
}

typedef Bio =
{
	var char:String;
	var unlocked:Bool;
	var desc:String;
	var color:FlxColor;
	var unlockCondition:String;
	var ?wikiPage:String;
	var ?mod:String;
}

class CharacterIcon extends FlxSpriteGroup
{
	public var bio:Bio;
	public var icon:FlxSprite;

	public function new(x:Float = 0, y:Float = 0, bio:Bio)
	{
		super(x, y);
		this.bio = bio;

		icon = new FlxSprite().loadGraphic(CoolUtil.getImageOrPlaceholder('wiki/icons/', WikiState.formatCharName(bio.char), 'Default'));
		icon.antialiasing = ClientPrefs.data.antialiasing;
		if (!bio.unlocked)
			icon.color = FlxColor.BLACK;
		add(icon);
	}
}
