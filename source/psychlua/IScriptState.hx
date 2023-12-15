package psychlua;

import flixel.FlxBasic;
import objects.Character;

interface IScriptState extends IMusicBeatState
{
	#if LUA_ALLOWED
	var modchartSprites:Map<String, ModchartSprite>;
	var modchartTexts:Map<String, FlxText>;

	function startLuasNamed(luaFile:String):Bool;
	#end

	#if HSCRIPT_ALLOWED
	var hscriptArray:Array<BaseHScript>;

	function startHScriptsNamed(scriptFile:String):Bool;
	function initHScript(file:String):Void;
	#end

	var variables:Map<String, Dynamic>;

	var boyfriendGroup:FlxSpriteGroup;
	var dadGroup:FlxSpriteGroup;
	var gfGroup:FlxSpriteGroup;

	var dad:Character;
	var gf:Character;
	var boyfriend:Character;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var camOther:FlxCamera;

	var luaArray:Array<BaseLua>;

	function addTextToDebug(text:String, color:FlxColor):Void;
	function getLuaObject(tag:String, text:Bool = true):FlxSprite;
	function addBehindGF(obj:FlxBasic):Void;
	function addBehindBF(obj:FlxBasic):Void;
	function addBehindDad(obj:FlxBasic):Void;
	function initLua(path:String):Void;
	function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic;
	function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic;
	function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic;
	function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void;
	function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void;
	function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void;
}

interface IMusicBeatState extends IFlxState
{
	var controls(get, never):Controls;
}

interface IFlxState extends IFlxBasic
{
	var members(default, null):Array<FlxBasic>;

	function add(basic:FlxBasic):FlxBasic;
	function insert(position:Int, object:FlxBasic):FlxBasic;
	function remove(basic:FlxBasic, splice:Bool = false):FlxBasic;
}
