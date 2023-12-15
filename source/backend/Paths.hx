package backend;

import flash.media.Sound;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.io.Path;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Paths
{
	public static final SOUND_EXT = #if web "mp3" #else "ogg" #end;
	public static final VIDEO_EXT = "mp4";
	public static final BF_DIFFICULTIES = ['bfhard', 'itbf'];

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					// remove the key from all cache maps
					FlxG.bitmap._cache.remove(key);
					openfl.Assets.cache.removeBitmapData(key);
					currentTrackedAssets.remove(key);

					// and get rid of the object
					obj.persist = false; // make sure the garbage collector actually clears it up
					obj.destroyOnNoUse = true;
					obj.destroy();
				}
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				// trace('test: ' + dumpExclusions, key);
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	static public var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, ?modsAllowed:Bool = false):String
	{
		#if MODS_ALLOWED
		if (modsAllowed)
		{
			var modded:String = modFolders(file);
			if (FileSystem.exists(modded))
				return modded;
		}
		#end

		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, 'week_assets', currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String, ?level:String)
	{
		if (level == null)
			level = library;
		var returnPath = '$library:assets/$level/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String):Any
	{
		// we're not even compiling to html but fuck it
		#if html5
		var path = 'songs:assets/songs/${formatToSongPath(song)}/Voices${Difficulty.getSongSuffix()}.$SOUND_EXT';
		if (OpenFLAssets.exists(path))
			return path;
		else
			return 'songs:assets/songs/${formatToSongPath(song)}/Voices.$SOUND_EXT';
		#else
		final songKey:String = '${formatToSongPath(song)}/Voices';
		final songAndSuffix = songKey + Difficulty.getSongSuffix();

		if (fileExists('songs/$songAndSuffix.$SOUND_EXT', SOUND))
			return returnSound('songs', songAndSuffix);
		else
			return returnSound('songs', songKey);
		#end
	}

	inline static public function inst(song:String):Any
	{
		#if html5
		var path = 'songs:assets/songs/${formatToSongPath(song)}/Inst${Difficulty.getSongSuffix()}.$SOUND_EXT';
		if (OpenFLAssets.exists(path))
			return path;
		else
			return 'songs:assets/songs/${formatToSongPath(song)}/Inst.$SOUND_EXT';
		#else
		final songKey:String = '${formatToSongPath(song)}/Inst';
		final songAndSuffix = songKey + Difficulty.getSongSuffix();

		if (fileExists('songs/$songAndSuffix.$SOUND_EXT', SOUND))
			return returnSound('songs', songAndSuffix);
		else
			return returnSound('songs', songKey);
		#end
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	static public function image(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		var bitmap:BitmapData = null;
		var file:String = null;

		#if MODS_ALLOWED
		file = modsImages(key);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedAssets.get(file);
		}
		else if (FileSystem.exists(file))
			bitmap = BitmapData.fromFile(file);
		else
		#end
		{
			file = getPath('images/$key.png', IMAGE, library);
			if (currentTrackedAssets.exists(file))
			{
				localTrackedAssets.push(file);
				return currentTrackedAssets.get(file);
			}
			else if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);
		}

		if (bitmap != null)
		{
			localTrackedAssets.push(file);
			if (allowGPU && ClientPrefs.data.cacheOnGPU)
			{
				var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
				texture.uploadFromBitmapData(bitmap);
				bitmap.image.data = null;
				bitmap.dispose();
				bitmap.disposeImage();
				bitmap = BitmapData.fromTexture(texture);
			}
			var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
			newGraphic.persist = true;
			newGraphic.destroyOnNoUse = false;
			currentTrackedAssets.set(file, newGraphic);
			return newGraphic;
		}

		trace('oh no its returning null NOOOO ($file)');
		return null;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(key, 'week_assets', currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		#end
		var path:String = getPath(key, TEXT);
		if (OpenFlAssets.exists(path, TEXT))
			return Assets.getText(path);
		return null;
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String = null)
	{
		#if MODS_ALLOWED
		if (!ignoreMods)
		{
			for (mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$key')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + key)) || FileSystem.exists(mods(key)))
				return true;
		}
		#end

		if (OpenFlAssets.exists(getPath(key, type, library, false)))
		{
			return true;
		}
		return false;
	}

	// less optimized but automatic handling
	static public function getAtlas(key:String, ?library:String = null):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(modsXml(key)) || OpenFlAssets.exists(getPath('images/$key.xml', library), TEXT))
		#else
		if (OpenFlAssets.exists(getPath('images/$key.xml', library)))
		#end
		{
			return getSparrowAtlas(key, library);
		}
		return getPackerAtlas(key, library);
	}

	static public function getSparrowAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = image(key, allowGPU);
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if (FileSystem.exists(xml))
		{
			xmlExists = true;
		}

		if (imageLoaded == null)
		{
			imageLoaded = image(key, library, allowGPU);
			// prevents "missing bitmap" warning from showing up
			if (imageLoaded == null)
				return null;
		}

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library, allowGPU), getPath('images/$key.xml', library));
		#end
	}

	static public function getPackerAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = image(key, allowGPU);
		var txtExists:Bool = false;

		var txt:String = modsTxt(key);
		if (FileSystem.exists(txt))
		{
			txtExists = true;
		}

		if (imageLoaded == null)
		{
			imageLoaded = image(key, library, allowGPU);
			if (imageLoaded == null)
				return null;
		}

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, allowGPU), getPath('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String)
	{
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSound(path:String, key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if (FileSystem.exists(file))
		{
			if (!currentTrackedSounds.exists(file))
			{
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if (!currentTrackedSounds.exists(gottenPath))
		{
			#if MODS_ALLOWED
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
			#else
			{
				var folder:String = '';
				if (path == 'songs')
					folder = 'songs:';

				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
			}
			#end
		}
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	public static function getDirectories(folder:String):Array<String>
	{
		#if MODS_ALLOWED
		var directories:Array<String> = [
			mods(folder),
			mods(Path.join([Mods.currentModDirectory, folder])),
			getPreloadPath(folder)
		];

		for (mod in Mods.getGlobalMods())
			directories.push(mods(Path.join([mod, folder])));

		return directories;
		#else
		return [getPreloadPath(folder)];
		#end
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
	{
		return 'mods/' + key;
	}

	inline static public function modsFont(key:String)
	{
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String)
	{
		return modFolders('data/' + key + '.json');
	}

	inline static public function modsVideo(key:String)
	{
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsSounds(path:String, key:String)
	{
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String)
	{
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String)
	{
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String)
	{
		return modFolders('images/' + key + '.txt');
	}

	static public function modFolders(key:String)
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if (FileSystem.exists(fileToCheck))
			{
				return fileToCheck;
			}
		}

		for (mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if (FileSystem.exists(fileToCheck))
				return fileToCheck;
		}
		return 'mods/' + key;
	}
	#end
}