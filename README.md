# Friday Night Funkin' - VS Plantoids+

The official repository for the VS Plantoids+ mod.

## Special Features

VS Plantoids+ is a modified version of Psych Engine, but it has its own special values and things developers are able to play with, which does not affect vanilla Psych and is purely for mod compatibility with the engine. All these values are optional and are not required for the engine to work, if they are empty, they will use their base psych versions and/or their default values.

### Story Menu

#### Menu Characters

- **'image_plantoidsplus'** is the value for the image used when the menu character is seen on PPlus, this can be used to allow the character to have the wireframe style PPlus has on the week select menu. (Note: a separate spritesheet is required in order to work properly)

#### Week Files

- **'weekBackground_plantoidsplus'** is the value used for the week Background when the week is seen on PPlus, usually a black and gray styled version of the select bg.
- **'ui_background_color'** is the value used to define the normally black UI's color, causing it to shift to that color when the week is being viewed.

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/38c35366-c058-45fb-b360-cf47bab34c80)

### Freeplay Menu

- The Freeplay Menu comes with a unique appearance style in the form of potted plants, there is a placeholder one in case a song doesn't have an associated pot. To add a freeplay pot, add its image to 'images/freeplaypots' with the file name being the song's name (I.E. "manifest-(aero-mix)")

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/ab246f78-3053-4d1d-b743-d3b4270f4407)

### Gameplay

#### Character Files

- **'arrowsName'** is a value that allows the character's specific arrow skin to be changed, if this is left empty, the character will use the chart's arrow skin instead. If a character changes and they have a different 'arrowsName' value, their note skin will be changed when the character changes, allowing for dynamic form-matching note skin changes.

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/35c566f0-7fb1-4c77-84e1-bb9abfcaae81)

#### Charts

- You can now credit the composer(s) of a song through the chart editor under the "Data" tab. Their name(s) will be on the sign that appears at the beginning of the song. To include multiple artists, simply place a comma between each one, for example: "composer 1,composer 2".
- **Album Covers** are displayed on the beginning sign, by default they use a placeholder featuring "Silly Guy" from FNFever. To add a custom album, add its image to 'images/albumcovers' with the file name being the song name (I.E. "ski-hee")

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/bb24245a-1bfd-43fd-8247-f5ac51641415)

- **'uiSkin'** is an additional value which can be used to set a song's UI skin, a special feature included in PPlus. This system is very flexible, please see our official UI skins for examples of what you can do.

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/80639c8e-0a21-45fd-8d7e-d75e740afe29)

### Character Encylopedia

Included with Plantoids Plus is a Character Encylopedia including bios and art for all the characters included in Plantoids Plus. This functions off of its own unique system that uses .txt files.

**"wikiBios.txt"** is a required file in order to display your character's bio, and defines things such as the bar and name color, the display name, how you unlock the character (song, week or achievement) along with the name of what you need to beat/get, and a link to the Advendure-pedia (or Funkipedia Mods) page.

Each line in "wikiBios.txt" has the following values, separated by a colon (`:`):

1. The character's name. It can include spaces.
2. The hex color for the name and paragraph-separating lines. Optional, but recommended. If excluded, defaults to white (#FFFFFF).
3. Optional, the unlock condition for this bio. If the player hasn't unlocked it, its icon and render will be blacked out, its name will be hidden, and its description will be replaced by a guide on how to unlock it. If you exclude this, the bio will be unlocked from the start. Can be one of 3 values:
   - `week`: Complete the specified week.
   - `song`: Complete the specified song.
   - `achievement`: Earn the specified achievement.
4. Optional (unless you specified an unlock condition), the name of the thing you have to complete/earn to unlock it. Has no effect if the unlock condition is excluded. Depending on the condition, you should put:
   - `week`: The filename for the week. (i.e. `week1`)
   - `song`: The name of the song, ideally the unformatted version. (i.e. `Mirror Matching`, instead of `mirror-matching`)
   - `achievement`: The filename for the achievement. (i.e. `aero_fc`)
5. Optional, the name of the character's page on the [Advendure Wiki](https://advendure-plantoids.fandom.com/wiki/Advendure_Wiki). If it isn't blank, a button will appear under the character's render which will take you to the page. If you put `\f` before it, it will instead lead to the [Funkipedia Mods Wiki](https://fridaynightfunking.fandom.com/wiki/Funkipedia_Mods_Wiki). Note that it won't check if the respective page actually exists on the wiki.

A character bio is written in a .txt file with the name you gave to the character's entry in 'wikiBios.txt' (i.e 'Ada.txt'). Keep in mind spaces aren't included in these (i.e. 'LirazAndLeto.txt'). These bios can be written however you want, if you want to create a paragraph-separating line, make a new line and add \<line> then create a new line after that. The engine will automatically make the line itself.

In 'images/wiki' there are two sub folders, 'icons' which houses the character's icon (functions like an icon set, but only one icon is present, so 150x150 instead of 300x150 and so on) which does not include spaces. (i.e 'LirazAndLeto.png') and the 'renders' folder which houses the character's render artwork (can be any size) which also doesn't include spaces (i.e 'TheTogitosRender.png').

It is important to note that there are no placeholder files for wiki renders, only add bios if you have all the assets required.

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/d64c5800-bf22-4306-bcee-bc6e3ae030bd)

### Achievements

Plantoids Plus also comes with a custom Achievement System, and comes with a rather simple to use system.

**'achievementList.txt'** contains the full list of visible achievements. each line is an achievement, with each entry being named their respective .json file. This is mandatory for usage of the achievement system.

An achievement is stored in a .json file, and contains the following values:

- **'displayName'** - the public name of the achievement
- **'description'** - the description of the achievement (usually explaining how to get it)
- **'unlockCondition'** - the action required to unlock the achievement (\<condition>:<name of song/week>)
  - 'song' for song completion
  - 'week' for week completion
  - 'song_fc' for a full combo on a song
  - 'week_fc' for a full combo on a week in story mode
  - 'song_death' upon dying in a song (primarily used for joke achievements, like Hot's gameover achievement)

The achievement's icon (displayed in a 300x150 set of 2) is stored in 'achievements/' and is named after its respective achievement.json (i.e aero.json -> aero.png)

If the mod contains a custom 'lockedachievement.png', its achievements will use that instead of the default one. This is completely optional.

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/58f5c2ca-cd62-471f-ad4e-074c0d001d52)

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/68924497-9a7e-48ac-b673-745bee89aac6)

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/1f629e86-444b-4659-8461-1d6ae7e03059)

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/ba08a58e-ddb0-400c-8c4f-1ef652361ac2)

### Lua Functions

Some new Lua functions have been added:

- **precacheDialogue(dialogueFile:String)**: Allows you to precache a dialogue cutscene's assets, those being the speech bubble, the dialogue sounds, and the dialogue characters. Note that this is only useful when the dialogue isn't started on the first frame.
- **songPlayedInSession()**: Returns whether the current song has been already played in this session. Will return `false` only the first time it's being played.

### Examples

To see official examples of how this system works, we suggest looking for any mod that has a pixel Taih in the bottom right corner of it's 'pack.png'. For names, we suggest checking out \[VS Vigor], \[VS Lucia] and \[VS Angel], as they are made by PPlus team members in some way.

![image](https://github.com/Starmapo/Plantoids-Plus/assets/46505816/2f0b2c54-44db-4fe1-a289-a89196ac5d54)

## Mod Compatibility

VS Plantoids+ is meant to be compatible with all Psych Engine v0.7 mods, and simply expands the capabilities.

If you find a mod intended for v0.7 that doesn't work right in this engine, please create a new issue with details.
