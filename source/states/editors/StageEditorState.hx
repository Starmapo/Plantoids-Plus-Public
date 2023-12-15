package states.editors;

import backend.Song;
import backend.StageData;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FontDef;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxStringUtil;
import objects.Character;
import objects.LoadingScreen;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import openfl.text.TextFormat;
import psychlua.BaseHScript;
import psychlua.BaseLua;
import psychlua.DebugLuaText;
import psychlua.FunkinLua;
import psychlua.IScriptState;
import psychlua.ModchartSprite;
import psychlua.StageEditorHScript;
import psychlua.StageEditorLua;
import sys.FileSystem;
import tea.SScript;

class StageEditorState extends MusicBeatState implements IScriptState
{
	public var stageName(default, set):String;
	public var stageData:StageFile;
	public var luaArray:Array<BaseLua> = [];
	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<BaseHScript> = [];
	#end
	#if LUA_ALLOWED
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	#end
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	var blockPressWhileScrolling:Array<FlxUIDropDownMenu> = [];
	var objectsToKeep:Array<FlxBasic> = [];
	var showChars(get, never):Bool;
	var debugTexts:Array<String> = [];

	var _file:FileReference;

	var camMenu:FlxCamera;

	var camFollow:FlxObject;

	public var boyfriend:Character;
	public var dad:Character;
	public var gf:Character;
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	var pointerGroup:FlxTypedGroup<Pointer>;
	var boyfriendPointer:Pointer;
	var dadPointer:Pointer;
	var gfPointer:Pointer;

	var uiSettingsBox:FlxUITabMenu;
	var stageDropdown:FlxUIDropDownMenu;
	var hideCharsCheckbox:FlxUICheckBox;
	var bfDropdown:FlxUIDropDownMenu;
	var dadDropdown:FlxUIDropDownMenu;
	var gfDropdown:FlxUIDropDownMenu;

	var uiStageBox:FlxUITabMenu;
	var directoryInput:FlxUIInputText;
	var defaultZoomStepper:FlxUINumericStepper;
	var cameraSpeedStepper:FlxUINumericStepper;
	var uiSkinInput:FlxUIInputText;
	var boyfriendXStepper:FlxUINumericStepper;
	var boyfriendYStepper:FlxUINumericStepper;
	var opponentXStepper:FlxUINumericStepper;
	var opponentYStepper:FlxUINumericStepper;
	var girlfriendXStepper:FlxUINumericStepper;
	var girlfriendYStepper:FlxUINumericStepper;
	var cameraBoyfriendXStepper:FlxUINumericStepper;
	var cameraBoyfriendYStepper:FlxUINumericStepper;
	var cameraOpponentXStepper:FlxUINumericStepper;
	var cameraOpponentYStepper:FlxUINumericStepper;
	var cameraGirlfriendXStepper:FlxUINumericStepper;
	var cameraGirlfriendYStepper:FlxUINumericStepper;
	var hideGFCheckbox:FlxUICheckBox;

	var infoText:FlxUIText;
	var loadingScreen:LoadingScreen;
	var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	// The following fields are here due to hardcoded stages requiring them
	public var paused:Bool = false;
	public var songName:String = 'Test';
	public var inCutscene:Bool;
	public var canPause:Bool;
	public var defaultCamZoom:Float = 1;
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;

	override function create()
	{
		Paths.clearStoredMemory();

		PlayState.isStoryMode = false;
		PlayState.SONG = Song.dummy();

		camGame = FlxG.camera;

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;
		FlxG.cameras.add(camMenu, false);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		pointerGroup = new FlxTypedGroup();
		objectsToKeep.push(pointerGroup);

		boyfriendPointer = createPointer(FlxColor.BLUE);
		dadPointer = createPointer(FlxColor.PURPLE);
		gfPointer = createPointer(FlxColor.RED);

		uiSettingsBox = new FlxUITabMenu([{name: 'Settings', label: 'Settings'}], true);
		uiSettingsBox.resize(280, 190);
		uiSettingsBox.x = FlxG.width - uiSettingsBox.width - 15;
		uiSettingsBox.y = 25;
		uiSettingsBox.scrollFactor.set();

		uiStageBox = new FlxUITabMenu([{name: 'Stage', label: 'Stage'}], true);
		uiStageBox.resize(350, 250);
		uiStageBox.x = uiSettingsBox.x - 100;
		uiStageBox.y = uiSettingsBox.y + uiSettingsBox.height;
		uiStageBox.scrollFactor.set();

		addSettingsUI();
		addStageUI();

		uiStageBox.selected_tab = uiSettingsBox.selected_tab = 0;

		// i do this so selecting a dropdown will stop other buttons from updating
		_ui = createUI(null, this);
		_ui.cameras = [camMenu];
		_ui.add(uiStageBox);
		_ui.add(uiSettingsBox);
		add(_ui);
		objectsToKeep.push(_ui);

		loadUIFromData(null);

		infoText = new FlxUIText(5, 0, FlxG.width - 10, '', 16);
		infoText.cameras = [camMenu];
		infoText.setBorderStyle(OUTLINE, FlxColor.BLACK);
		add(infoText);
		objectsToKeep.push(infoText);

		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camMenu];
		add(luaDebugGroup);
		objectsToKeep.push(luaDebugGroup);

		loadingScreen = new LoadingScreen();
		loadingScreen.cameras = [camMenu];
		add(loadingScreen);
		objectsToKeep.push(loadingScreen);

		stageName = stageDropdown.list[0].name;

		FlxG.mouse.visible = true;

		super.create();

		cleanup();

		Paths.clearUnusedMemory();
	}

	override function update(elapsed:Float)
	{
		callOnScripts('onUpdate', [elapsed]);

		var blockInput:Bool = false;

		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				ClientPrefs.toggleVolumeKeys(false);
				blockInput = true;
				break;
			}
		}

		if (!blockInput)
		{
			ClientPrefs.toggleVolumeKeys(true);
			for (dropDownMenu in blockPressWhileScrolling)
			{
				if (dropDownMenu.dropPanel.visible)
				{
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				MusicBeatState.switchState(new MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.mouse.visible = false;
				return;
			}

			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
			{
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT)
					addToCam *= 4;

				if (FlxG.keys.pressed.I)
					camFollow.y -= addToCam;
				else if (FlxG.keys.pressed.K)
					camFollow.y += addToCam;

				if (FlxG.keys.pressed.J)
					camFollow.x -= addToCam;
				else if (FlxG.keys.pressed.L)
					camFollow.x += addToCam;

				updateInfoText();
			}
		}

		super.update(elapsed);

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);

		callOnScripts('onUpdatePost', [elapsed]);
	}

	override function destroy()
	{
		destroyScripts();

		super.destroy();
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUIInputText.CHANGE_EVENT)
		{
			final text:String = data;
			if (sender == directoryInput)
			{
				stageData.directory = text;
			}
			else if (sender == uiSkinInput)
			{
				stageData.stageUI = text;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT)
		{
			final value:Float = data;
			if (sender == defaultZoomStepper)
			{
				stageData.defaultZoom = value;
				updateZoom();
			}
			else if (sender == cameraSpeedStepper)
			{
				stageData.camera_speed = value;
			}
			else if (sender == boyfriendXStepper || sender == boyfriendYStepper)
			{
				final i = (sender == boyfriendXStepper ? 0 : 1);
				stageData.boyfriend[i] = value;
				updateBFPosition();
			}
			else if (sender == opponentXStepper || sender == opponentYStepper)
			{
				final i = (sender == opponentXStepper ? 0 : 1);
				stageData.opponent[i] = value;
				updateDadPosition();
			}
			else if (sender == girlfriendXStepper || sender == girlfriendYStepper)
			{
				final i = (sender == girlfriendXStepper ? 0 : 1);
				stageData.girlfriend[i] = value;
				updateGFPosition();
			}
			else if (sender == cameraBoyfriendXStepper || sender == cameraBoyfriendYStepper)
			{
				final i = (sender == cameraBoyfriendXStepper ? 0 : 1);
				stageData.camera_boyfriend[i] = value;
				updateBFPointer();

				updateInfoText();
			}
			else if (sender == cameraOpponentXStepper || sender == cameraOpponentYStepper)
			{
				final i = (sender == cameraOpponentXStepper ? 0 : 1);
				stageData.camera_opponent[i] = value;
				updateDadPointer();

				updateInfoText();
			}
			else if (sender == cameraGirlfriendXStepper || sender == cameraGirlfriendYStepper)
			{
				final i = (sender == cameraGirlfriendXStepper ? 0 : 1);
				stageData.camera_girlfriend[i] = value;
				updateGFPointer();

				updateInfoText();
			}
		}
	}

	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}

	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}

	public function addTextToDebug(text:String, color:FlxColor)
	{
		if (debugTexts.contains(text))
			return;

		debugTexts.push(text);

		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = psychlua.FunkinLua.Function_Continue;

		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = new Array();
		if (excludeValues == null)
			excludeValues = new Array();
		excludeValues.push(psychlua.FunkinLua.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for (i in 0...len)
		{
			var script = hscriptArray[i];
			if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try
			{
				var callValue = script.call(funcToCall, args);
				if (!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if (e != null)
						addTextToDebug('ERROR (${script.origin}: ${callValue.calledFunction}) - '
							+ e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
				}
				else
				{
					myValue = callValue.returnValue;
					if ((myValue == FunkinLua.Function_StopHScript || myValue == FunkinLua.Function_StopAll)
						&& !excludeValues.contains(myValue)
						&& !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if (myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}
		#end

		return returnVal;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [FunkinLua.Function_Continue];

		var len:Int = luaArray.length;
		var i:Int = 0;
		while (i < len)
		{
			var script = luaArray[i];
			if (exclusions.contains(script.scriptName))
			{
				i++;
				continue;
			}

			var myValue:Dynamic = script.call(funcToCall, args);
			if ((myValue == FunkinLua.Function_StopLua || myValue == FunkinLua.Function_StopAll)
				&& !excludeValues.contains(myValue)
				&& !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if (myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if (!script.closed)
				i++;
			else
				len--;
		}
		#end
		return returnVal;
	}

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [psychlua.FunkinLua.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if (result == null || excludeValues.contains(result))
			result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		#if LUA_ALLOWED
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		if (variables.exists(tag))
			return variables.get(tag);
		#end
		return null;
	}

	#if HSCRIPT_ALLOWED
	public function initHScript(file:String)
	{
		try
		{
			var newScript = new StageEditorHScript(null, file);
			if (newScript.parsingException != null)
			{
				addTextToDebug('ERROR ON LOADING ($file): ${newScript.parsingException.message}', FlxColor.RED);
				newScript.destroy();
				return;
			}

			hscriptArray.push(newScript);
			if (newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if (!callValue.succeeded)
				{
					for (e in callValue.exceptions)
						if (e != null)
							addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);

					newScript.destroy();
					hscriptArray.remove(newScript);
					trace('failed to initialize sscript interp!!! ($file)');
				}
				else
					trace('initialized sscript interp successfully: $file');
			}
		}
		catch (e)
		{
			addTextToDebug('ERROR ($file) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
			var newScript = cast(SScript.global.get(file), StageEditorHScript);
			if (newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function initLua(path:String)
	{
		#if LUA_ALLOWED
		new StageEditorLua(path);
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in hscriptArray)
		{
			if (exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if LUA_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		if (exclusions == null)
			exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	function addSettingsUI()
	{
		var tab = new FlxUI(uiSettingsBox);
		tab.name = "Settings";

		final stages = StageData.getStageList();

		stageDropdown = new FlxUIDropDownMenu(10, 20, FlxUIDropDownMenu.makeStrIdLabelArray(stages), function(stage:String)
		{
			if (stageName != stage)
			{
				loadingScreen.show(function()
				{
					stageName = stage;
				});
			}
		});
		pushUIElement(stageDropdown);

		var reloadStageButton = new FlxUIButton(stageDropdown.x + stageDropdown.width + 10, 20, 'Reload Stage', function()
		{
			loadingScreen.show(function()
			{
				reloadStage();
			});
		});
		tab.add(reloadStageButton);

		var saveStageButton = new FlxUIButton(stageDropdown.x, stageDropdown.y + stageDropdown.header.background.height + 10, 'Save Stage', function()
		{
			saveStage();
		});
		tab.add(saveStageButton);

		hideCharsCheckbox = new FlxUICheckBox(saveStageButton.x + saveStageButton.width + 10, saveStageButton.y, null, null, 'Hide Characters', function()
		{
			gfPointer.visible = dadPointer.visible = boyfriendPointer.visible = dad.visible = boyfriend.visible = showChars;
			if (gf != null)
				gf.visible = showChars;
		});
		tab.add(hideCharsCheckbox);

		final characters = Character.getCharacterList();
		final characterLabels = FlxUIDropDownMenu.makeStrIdLabelArray(characters);

		bfDropdown = new FlxUIDropDownMenu(saveStageButton.x, saveStageButton.y + saveStageButton.height + 20, characterLabels, function(char:String)
		{
			if (boyfriend.curCharacter != char)
			{
				loadingScreen.show(function()
				{
					PlayState.SONG.player1 = char;
					reloadBF();
				});
			}
		});
		bfDropdown.selectedId = PlayState.SONG.player1;
		pushUIElement(bfDropdown);

		dadDropdown = new FlxUIDropDownMenu(bfDropdown.x + bfDropdown.width + 10, bfDropdown.y, characterLabels, function(char:String)
		{
			if (dad.curCharacter != char)
			{
				loadingScreen.show(function()
				{
					PlayState.SONG.player2 = char;
					reloadDad();
				});
			}
		});
		dadDropdown.selectedId = PlayState.SONG.player2;
		pushUIElement(dadDropdown);

		gfDropdown = new FlxUIDropDownMenu(bfDropdown.x, bfDropdown.y + bfDropdown.header.background.height + 20, characterLabels, function(char:String)
		{
			if (gf.curCharacter != char)
			{
				loadingScreen.show(function()
				{
					PlayState.SONG.gfVersion = char;
					reloadGF();
				});
			}
		});
		gfDropdown.selectedId = PlayState.SONG.gfVersion;
		pushUIElement(gfDropdown);

		tab.add(new FlxUIText(stageDropdown.x, stageDropdown.y - 15, 0, 'Stage:'));
		tab.add(new FlxUIText(bfDropdown.x, bfDropdown.y - 15, 0, 'Boyfriend:'));
		tab.add(new FlxUIText(dadDropdown.x, dadDropdown.y - 15, 0, 'Opponent:'));
		tab.add(new FlxUIText(gfDropdown.x, gfDropdown.y - 15, 0, 'Girlfriend:'));

		tab.add(gfDropdown);
		tab.add(dadDropdown);
		tab.add(bfDropdown);
		tab.add(stageDropdown);

		uiSettingsBox.addGroup(tab);
	}

	function addStageUI()
	{
		var tab = new FlxUI(uiStageBox);
		tab.name = "Stage";

		directoryInput = new FlxUIInputText(10, 30);
		directoryInput.customFilterPattern = ~/[:"]*/g;
		tab.add(directoryInput);
		pushUIElement(directoryInput);

		defaultZoomStepper = new FlxUINumericStepper(directoryInput.x + directoryInput.width + 10, directoryInput.y, 0.05, 1, 0.05, 5, 2);
		tab.add(defaultZoomStepper);
		pushUIElement(defaultZoomStepper);

		cameraSpeedStepper = new FlxUINumericStepper(defaultZoomStepper.x + defaultZoomStepper.width + 20, defaultZoomStepper.y, 0.05, 1, 0.05, 10, 2);
		tab.add(cameraSpeedStepper);
		pushUIElement(cameraSpeedStepper);

		uiSkinInput = new FlxUIInputText(directoryInput.x, directoryInput.y + directoryInput.height + 20);
		tab.add(uiSkinInput);
		pushUIElement(uiSkinInput);

		boyfriendXStepper = new FlxUINumericStepper(uiSkinInput.x + uiSkinInput.width + 10, uiSkinInput.y, 10, PlayState.DEFAULT_BF_X, -9000, 9000);
		tab.add(boyfriendXStepper);
		pushUIElement(boyfriendXStepper);

		boyfriendYStepper = new FlxUINumericStepper(boyfriendXStepper.x + boyfriendXStepper.width + 10, boyfriendXStepper.y, 10, PlayState.DEFAULT_BF_Y,
			-9000, 9000);
		tab.add(boyfriendYStepper);
		pushUIElement(boyfriendYStepper);

		opponentXStepper = new FlxUINumericStepper(uiSkinInput.x, uiSkinInput.y + uiSkinInput.height + 20, 10, PlayState.DEFAULT_DAD_X, -9000, 9000);
		tab.add(opponentXStepper);
		pushUIElement(opponentXStepper);

		opponentYStepper = new FlxUINumericStepper(opponentXStepper.x + opponentXStepper.width + 10, opponentXStepper.y, 10, PlayState.DEFAULT_DAD_Y, -9000,
			9000);
		tab.add(opponentYStepper);
		pushUIElement(opponentYStepper);

		girlfriendXStepper = new FlxUINumericStepper(opponentYStepper.x + opponentYStepper.width + 10, opponentYStepper.y, 10, PlayState.DEFAULT_GF_X, -9000,
			9000);
		tab.add(girlfriendXStepper);
		pushUIElement(girlfriendXStepper);

		girlfriendYStepper = new FlxUINumericStepper(girlfriendXStepper.x + girlfriendXStepper.width + 10, girlfriendXStepper.y, 10, PlayState.DEFAULT_GF_Y,
			-9000, 9000);
		tab.add(girlfriendYStepper);
		pushUIElement(girlfriendYStepper);

		cameraBoyfriendXStepper = new FlxUINumericStepper(opponentXStepper.x, opponentXStepper.y + opponentXStepper.height + 20, 10, 0, -9000, 9000);
		tab.add(cameraBoyfriendXStepper);
		pushUIElement(cameraBoyfriendXStepper);

		cameraBoyfriendYStepper = new FlxUINumericStepper(cameraBoyfriendXStepper.x + cameraBoyfriendXStepper.width + 10, cameraBoyfriendXStepper.y, 10, 0,
			-9000, 9000);
		tab.add(cameraBoyfriendYStepper);
		pushUIElement(cameraBoyfriendYStepper);

		cameraOpponentXStepper = new FlxUINumericStepper(cameraBoyfriendYStepper.x + cameraBoyfriendYStepper.width + 30, cameraBoyfriendYStepper.y, 10, 0,
			-9000, 9000);
		tab.add(cameraOpponentXStepper);
		pushUIElement(cameraOpponentXStepper);

		cameraOpponentYStepper = new FlxUINumericStepper(cameraOpponentXStepper.x + cameraOpponentXStepper.width + 10, cameraOpponentXStepper.y, 10, 0, -9000,
			9000);
		tab.add(cameraOpponentYStepper);
		pushUIElement(cameraOpponentYStepper);

		cameraGirlfriendXStepper = new FlxUINumericStepper(cameraBoyfriendXStepper.x, cameraBoyfriendYStepper.y + cameraBoyfriendYStepper.height + 20, 10, 0,
			-9000, 9000);
		tab.add(cameraGirlfriendXStepper);
		pushUIElement(cameraGirlfriendXStepper);

		cameraGirlfriendYStepper = new FlxUINumericStepper(cameraGirlfriendXStepper.x + cameraGirlfriendXStepper.width + 10, cameraGirlfriendXStepper.y, 10,
			0, -9000, 9000);
		tab.add(cameraGirlfriendYStepper);
		pushUIElement(cameraGirlfriendYStepper);

		hideGFCheckbox = new FlxUICheckBox(cameraGirlfriendYStepper.x + cameraGirlfriendYStepper.width + 25, cameraGirlfriendYStepper.y, null, null,
			'Hide Girlfriend', function()
		{
			stageData.hide_girlfriend = hideGFCheckbox.checked;
			reloadGF();
		});
		tab.add(hideGFCheckbox);
		pushUIElement(hideGFCheckbox);

		tab.add(new FlxUIText(directoryInput.x, directoryInput.y - 15, 0, 'Asset directory:'));
		tab.add(new FlxUIText(defaultZoomStepper.x, defaultZoomStepper.y - 15, 0, 'Default zoom:'));
		tab.add(new FlxUIText(cameraSpeedStepper.x, cameraSpeedStepper.y - 15, 0, 'Camera speed:'));
		tab.add(new FlxUIText(uiSkinInput.x, uiSkinInput.y - 15, 0, 'UI skin:'));
		tab.add(new FlxUIText(boyfriendXStepper.x, boyfriendXStepper.y - 15, 0, 'Boyfriend X/Y:'));
		tab.add(new FlxUIText(opponentXStepper.x, opponentXStepper.y - 15, 0, 'Opponent X/Y:'));
		tab.add(new FlxUIText(girlfriendXStepper.x, girlfriendXStepper.y - 15, 0, 'Girlfriend X/Y:'));
		tab.add(new FlxUIText(cameraBoyfriendXStepper.x, cameraBoyfriendXStepper.y - 15, 0, 'Boyfriend Camera Offset X/Y:'));
		tab.add(new FlxUIText(cameraOpponentXStepper.x, cameraOpponentXStepper.y - 15, 0, 'Opponent Camera Offset X/Y:'));
		tab.add(new FlxUIText(cameraGirlfriendXStepper.x, cameraGirlfriendXStepper.y - 15, 0, 'Girlfriend Camera Offset X/Y:'));

		uiStageBox.addGroup(tab);
	}

	function createPointer(color:FlxColor)
	{
		final pointer = new Pointer(color);
		pointerGroup.add(pointer);
		return pointer;
	}

	function destroyObjects(keepDefaultObjects = false)
	{
		var keep = objectsToKeep.copy();
		if (keepDefaultObjects)
			keep = keep.concat([gfGroup, dadGroup, boyfriendGroup, camFollow]);

		var i = members.length - 1;
		while (i >= 0)
		{
			final obj = members[i--];
			if (obj != null && !objectsToKeep.contains(obj))
				removeAndDestroy(obj);
		}
	}

	function destroyScripts()
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			var lua = luaArray[0];
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray.resize(0);
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if (script != null)
			{
				script.call('onDestroy');
				script.destroy();
			}
		hscriptArray.resize(0);
		#end

		final maps:Array<Map<String, Dynamic>> = [modchartSprites, modchartTexts, variables];
		for (map in maps)
		{
			for (_ => obj in map)
			{
				if (obj != null)
				{
					if (Std.isOfType(obj, FlxBasic))
						remove(obj, true);

					if (Std.isOfType(obj, IFlxDestroyable))
						obj.destroy();
				}
			}
			map.clear();
		}
	}

	function formatPoint(point:FlxPoint)
	{
		return formatPosition(point.x, point.y);
	}

	function formatPosition(x:Float, y:Float)
	{
		function round(n:Float)
		{
			return FlxMath.roundDecimal(n, 2);
		}

		return '(${round(x)}, ${round(y)})';
	}

	function getBFCameraPosition()
	{
		final point = boyfriend.getMidpoint(FlxPoint.weak());

		point.x -= 100;
		point.y -= 100;

		point.x -= (boyfriend.cameraPosition[0] - stageData.camera_boyfriend[0]);
		point.y += (boyfriend.cameraPosition[1] + stageData.camera_boyfriend[1]);

		return point;
	}

	function getDadCameraPosition()
	{
		final point = dad.getMidpoint(FlxPoint.weak());

		point.x += 150;
		point.y -= 100;

		point.x += (dad.cameraPosition[0] + stageData.camera_opponent[0]);
		point.y += (dad.cameraPosition[1] + stageData.camera_opponent[1]);

		return point;
	}

	function getGFCameraPosition()
	{
		final point = FlxPoint.weak();

		if (gf != null)
		{
			gf.getMidpoint(point);

			point.x += (gf.cameraPosition[0] + stageData.camera_girlfriend[0]);
			point.y += (gf.cameraPosition[1] + stageData.camera_girlfriend[1]);
		}

		return point;
	}

	function onSaveCancel(_):Void
	{
		if (_file != null)
		{
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
		}
	}

	function onSaveError(event:IOErrorEvent):Void
	{
		if (_file != null)
		{
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
			addTextToDebug("Problem saving file: " + event.text, FlxColor.RED);
		}
	}

	function onSaveComplete(_):Void
	{
		if (_file != null)
		{
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
			addTextToDebug("Successfully saved file.", FlxColor.WHITE);
		}
	}

	function pushUIElement(spr:FlxSprite)
	{
		if (Std.isOfType(spr, FlxUIInputText))
		{
			final text:FlxUIInputText = cast spr;
			blockPressWhileTypingOn.push(cast text);
		}
		else if (Std.isOfType(spr, FlxUINumericStepper))
		{
			final stepper:FlxUINumericStepper = cast spr;
			@:privateAccess
			blockPressWhileTypingOn.push(cast stepper.text_field);
		}
		else if (Std.isOfType(spr, FlxUIDropDownMenu))
		{
			final menu:FlxUIDropDownMenu = cast spr;
			blockPressWhileScrolling.push(cast menu);
		}
	}

	function removeAndDestroy(basic:FlxBasic)
	{
		if (basic != null)
		{
			remove(basic, true);
			basic.destroy();
		}
	}

	function reloadBF()
	{
		if (boyfriend != null)
		{
			boyfriendGroup.remove(boyfriend, true);
			boyfriend.destroy();
		}

		boyfriend = new Character(0, 0, PlayState.SONG.player1, true);
		boyfriend.startPos();
		boyfriendGroup.add(boyfriend);

		boyfriend.visible = showChars;

		updateBFPointer();
	}

	function reloadChars()
	{
		reloadGF();
		reloadDad();
		reloadBF();
	}

	function reloadDad()
	{
		if (dad != null)
		{
			dadGroup.remove(dad, true);
			dad.destroy();
		}

		dad = new Character(0, 0, PlayState.SONG.player2);
		dad.startPos(true);
		dadGroup.add(dad);

		dad.visible = showChars;

		updateDadPointer();
	}

	function reloadGF()
	{
		if (gf != null)
		{
			gfGroup.remove(gf, true);
			gf.destroy();
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, PlayState.SONG.gfVersion);
			gf.startPos();
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);

			gf.visible = showChars;
		}
		else
			gf = null;

		updateGFPointer();
	}

	function reloadStage()
	{
		destroyScripts();

		destroyObjects();

		stages.resize(0);

		inCutscene = false;
		canPause = false;
		debugTexts.resize(0);

		gf = null;
		dad = null;
		boyfriend = null;

		remove(pointerGroup, true);

		stageData = StageData.getStageFile(stageName) ?? StageData.dummy();

		if (stageData.directory == null)
		{
			stageData.directory = '';
		}
		if (stageData.stageUI == null)
		{
			stageData.stageUI = stageData.isPixelStage ? 'pixel' : '';
		}
		if (stageData.camera_boyfriend == null)
		{
			stageData.camera_boyfriend = [0, 0];
		}
		if (stageData.camera_opponent == null)
		{
			stageData.camera_opponent = [0, 0];
		}
		if (stageData.camera_girlfriend == null)
		{
			stageData.camera_girlfriend = [0, 0];
		}
		if (stageData.camera_speed == null)
		{
			stageData.camera_speed = 1;
		}

		if (stageData.directory.length > 0)
			Paths.setCurrentLevel(stageData.directory);
		else
			Paths.setCurrentLevel('shared');

		updateZoom();

		gfGroup = new FlxSpriteGroup();
		dadGroup = new FlxSpriteGroup();
		boyfriendGroup = new FlxSpriteGroup();

		updateGFPosition();
		updateDadPosition();
		updateBFPosition();

		StageData.addHardcodedStage(stageName);

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		// STAGE SCRIPTS
		#if LUA_ALLOWED
		startLuasNamed('stages/' + stageName + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + stageName + '.hx');
		#end

		reloadChars();

		stagesFunc(function(stage:BaseStage) stage.createPost());

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		FlxG.camera.follow(camFollow);

		final camPos = FlxPoint.get(stageData.camera_girlfriend[0], stageData.camera_girlfriend[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		FlxG.camera.snapToTarget();

		callOnScripts('onCreatePost');

		add(pointerGroup);

		reloadStageUI();
		updateInfoText();
	}

	function reloadStageUI()
	{
		directoryInput.text = stageData.directory;
		defaultZoomStepper.value = stageData.defaultZoom;
		cameraSpeedStepper.value = stageData.camera_speed;
		uiSkinInput.text = stageData.stageUI;
		boyfriendXStepper.value = stageData.boyfriend[0];
		boyfriendYStepper.value = stageData.boyfriend[1];
		opponentXStepper.value = stageData.opponent[0];
		opponentYStepper.value = stageData.opponent[1];
		girlfriendXStepper.value = stageData.girlfriend[0];
		girlfriendYStepper.value = stageData.girlfriend[1];
		cameraBoyfriendXStepper.value = stageData.camera_boyfriend[0];
		cameraBoyfriendYStepper.value = stageData.camera_boyfriend[1];
		cameraOpponentXStepper.value = stageData.camera_opponent[0];
		cameraOpponentYStepper.value = stageData.camera_opponent[1];
		cameraGirlfriendXStepper.value = stageData.camera_girlfriend[0];
		cameraGirlfriendYStepper.value = stageData.camera_girlfriend[1];
		hideGFCheckbox.checked = (stageData.hide_girlfriend == true);
	}

	function saveStage()
	{
		var json:Dynamic = {
			defaultZoom: stageData.defaultZoom,
			boyfriend: stageData.boyfriend,
			girlfriend: stageData.girlfriend,
			opponent: stageData.opponent
		};

		if (!FlxStringUtil.isNullOrEmpty(stageData.directory))
		{
			json.directory = stageData.directory;
		}
		if (!FlxStringUtil.isNullOrEmpty(stageData.stageUI))
		{
			json.stageUI = stageData.stageUI;
		}
		if (stageData.hide_girlfriend)
		{
			json.hide_girlfriend = stageData.hide_girlfriend;
		}
		final defaultOffset = [0.0, 0.0];
		if (!FlxArrayUtil.equals(stageData.camera_boyfriend, defaultOffset))
		{
			json.camera_boyfriend = stageData.camera_boyfriend;
		}
		if (!FlxArrayUtil.equals(stageData.camera_opponent, defaultOffset))
		{
			json.camera_opponent = stageData.camera_opponent;
		}
		if (!FlxArrayUtil.equals(stageData.camera_girlfriend, defaultOffset))
		{
			json.camera_girlfriend = stageData.camera_girlfriend;
		}
		if (stageData.camera_speed != 1)
		{
			json.camera_speed = stageData.camera_speed;
		}

		var data = haxe.Json.stringify(json, "\t");
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, stageName + ".json");
		}
	}

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if (!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getPreloadPath(scriptFile);

		if (FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad))
				return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}
	#end

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if (!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getPreloadPath(luaFile);

		if (FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);
		if (openfl.Assets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if (script.scriptName == luaToLoad)
					return false;

			initLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	function updateBFPointer()
	{
		boyfriendPointer.updatePosition(getBFCameraPosition());
	}

	function updateBFPosition()
	{
		boyfriendGroup.setPosition(stageData.boyfriend[0], stageData.boyfriend[1]);
	}

	function updateDadPointer()
	{
		dadPointer.updatePosition(getDadCameraPosition());
	}

	function updateDadPosition()
	{
		dadGroup.setPosition(stageData.opponent[0], stageData.opponent[1]);
	}

	function updateGFPointer()
	{
		gfPointer.visible = (gf != null && showChars);

		if (gf != null)
		{
			gfPointer.updatePosition(getGFCameraPosition());
		}
	}

	function updateGFPosition()
	{
		gfGroup.setPosition(stageData.girlfriend[0], stageData.girlfriend[1]);
	}

	function updateInfoText()
	{
		var text = 'Camera Position: ${formatPosition(camFollow.x, camFollow.y)}'
			+ '\nBoyfriend Camera Position: ${formatPoint(boyfriendPointer.position)}'
			+ '\nOpponent Camera Position: ${formatPoint(dadPointer.position)}';

		if (gf != null)
		{
			text += '\nGirlfriend Camera Position: ${formatPoint(gfPointer.position)}';
		}

		infoText.text = text;
		infoText.y = FlxG.height - infoText.height - 5;
	}

	function updatePresence()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Stage Editor", "Stage: " + stageName, null, null, null, 'icon_editor');
		#end
	}

	function updateZoom()
	{
		FlxG.camera.zoom = defaultCamZoom = stageData.defaultZoom;
	}

	function get_camGame()
	{
		return FlxG.camera;
	}

	function get_showChars()
	{
		return !hideCharsCheckbox.checked;
	}

	function set_stageName(value:String)
	{
		if (stageName != value)
		{
			stageName = value;

			PlayState.SONG.stage = stageName;
			reloadStage();

			updatePresence();
		}

		return value;
	}
}

class Pointer extends FlxSprite
{
	public var position = FlxPoint.get();

	public function new(color:FlxColor)
	{
		super(Paths.image('stage_cross'));
		this.color = color;
	}

	override function destroy()
	{
		super.destroy();
		position = FlxDestroyUtil.put(position);
	}

	public function updatePosition(value:FlxPoint)
	{
		position.copyFrom(value);

		setPosition(position.x - (width / 2), position.y - (height / 2));

		value.putWeak();
	}
}
