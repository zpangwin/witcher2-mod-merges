
## Description

This repo is for storing the changes I want in my local Witcher 2 mod.

There are a lot of nice mods out there but most of them only provide a binary... this is bad for several reasons

* Creates extra work before merging / add'l modifications can occur

* Many additional files that were NOT changed are bundled into the dzip file, which depending on what patch version of the game the mod was made from, could actually be reverting patch changes from the game.

I wanted to make a repo that *only* stores the files that are actually modified and perhaps a build script to overlay them in on top of extracted vanilla files and repack everything.

This would ensure that the latest versions are used wherever possible. This should make it easier to compare against smaller mods that are making simple changes and to only track what has changed from vanilla.

I am planning to use the excellent EMC mod as a base since it is both open-source and already encorporates a large number of the changes I am looking for.

## Notes

I will be merging only the actual changes in this repo.


The method I will be using to generate the merged archives is:

1. Extracting all base game archives (See section `Extracting multiple dzips files` for automating this step)
2. Copying any changes from this repo/merged mod sources over top of the extracted base game files
3. Removing any base game folders which were extracted but NOT modified by changes in this repo (e.g. most of the stuff outside of base_scripts and pack0)
4. Repacking the extracted and modified sources back into dzip files (See section `Repacking multiple folders back into their respective dzips files` for automating this step)
5. Make backups of original game dzip files
6. Copy repacked dzip files into game's CookedPC folder replacing the originals (but not their backups).


## Extracting multiple dzips files

If you want to unpack multiple dzips files, you can automate most of the work described in the next section by running the included script.

If you are on Mac/Linux, you should still read the next section to understand the required setup and make sure you have satisfied all the dependencies before running the script.

Otherwise, you can run the script from terminal. Here are samples showing different ways to run it (I recommend the last option).

```
cd "${thisRepoDir}"

# show help
./bulk-extract-sources.sh --help

# simulate an interactively (you will be prompted for paths to dzip folder and output folder)
# symlinks/folders will be created during --simulate but no archives will be extracted
./bulk-extract-sources.sh --simulate

# run interactively (you will be prompted for paths to dzip folder and output folder)
# symlinks/folders will be created during AND archives will be extracted
./bulk-extract-sources.sh

# 100% automated - symlinks/folders will be created during AND archives will be extracted
./bulk-extract-sources.sh "/path/to/dzip/folder" "/path/to/output/folder"
```

Here is an example:

```
gameCompatDir="/gaming/steam/steamapps/compatdata/20920/pfx/drive_c/temp";
gameInstallDir="/gaming/steam/steamapps/common/the witcher 2"

$ ls "${gameInstallDir}/CookedPC"| grep dzip
abetterui.dzip
alchemy_suit.dzip
arena.dzip
base_scripts.dzip
darkdiff.dzip
dlc_finishers.dzip
elf_flotsam.dzip
hairdresser.dzip
harpy_feathers.dzip
krbr.dzip
magical_suit.dzip
merchant.dzip
pack0.dzip
roche_jacket.dzip
succubuss.dzip
summer.dzip
swordsman_suit.dzip
troll.dzip
tutorial.dzip
winter.dzip

$ cd "${thisRepo}"

$ ./bulk-extract-sources.sh "${gameInstallDir}/CookedPC" "${gameInstallDir}/CookedPC-Extracts"

$ ls "${gameInstallDir}/CookedPC-Extracts"
abetterui     darkdiff       harpy_feathers  pack0         swordsman_suit
alchemy_suit  dlc_finishers  krbr            roche_jacket  troll
arena         elf_flotsam    magical_suit    succubuss     tutorial
base_scripts  hairdresser    merchant        summer        winter
```


## Extracting individual dzips files

When you want to extract a single dzip file, this can be done with the `Gibbed.RED.Unpack.exe` tool from [Gibbed RED Tools](https://www.nexusmods.com/witcher2/mods/768). On Windows, you can either drag the dzip file onto this exe or open a command prompt and pass the appropriate paths (dzip path followed by output folder path; see help output at bottom of this section for more info).

On Linux/Mac, if you are planning to play the game under Proton (and you will need to do so if you want to use Mods as the Native version has issues with mods) then you will need to have Steam installed and enable Proton anyway. After you have run the game once, steam will create a proton (wine) prefix folder for the game under the compatdata folder. You can create a temp folder  (or symlinks) under this so can copy the Gibbed RED Tools files and whatever dzips you want to work with there. That will allow us to call the tool from Proton (wine) and to reference everything in terms of Windows paths.

The default location of the compdata folder is under `~/.local/share/Steam/steamapps` but this might change if you have added additional steam library folders. It will be under the same base path as wherever you told steam to install The Witcher 2. For the game's steam id, if you have protontricks installed then you can find this easily by running `protontricks -s witcher` or by visiting the store page in your browser and getting the id from the URL (spoiler: the steam app id for TW2 is 20920).

Once all that is taken care of, you can launch it from the terminal. Remember to adjust paths from my sample so they match with the files on your system.

Terminal:

```
# 1) WINEPREFIX - find your {steamLibraryDir}/compatdata/20920/pfx and use this path.
#	this tells wine (proton) where all the windows paths are relative to
#	meaning "C:/temp" points to "{steamLibraryDir}/compatdata/20920/pfx/drive_c/temp"
#
# 2) Use whatever version of proton you have installed, but use the wine64 binary under that install
#
# 3) after wine64 you will have C:/path/to/Gibbed.RED.Unpack.exe C:/path/to/some.dzip C:/path/to/extract/to
#		you will need to create/copy things to these paths ahead of time or else create symlinks such as
#			ln -s "/gaming/steam/steamapps/common/the witcher 2/CookedPC" "{steamLibraryDir}/compatdata/20920/pfx/drive_c/temp/CookedPC"
#
# 4) Put everything together and pass it to wine
/usr/bin/env WINEPREFIX="/gaming/steam/steamapps/compatdata/20920/pfx" "/gaming/steam/steamapps/common/Proton 5.0/dist/bin/wine64" "C:/temp/tools/Gibbed.RED.Unpack.exe" "C:/temp/CookedPC/base_scripts.dzip" "C:/temp/output/base_scripts"
```

Gibbed.RED.Unpack.exe without arguments, you will get the following output

```
Usage: Gibbed.RED.Unpack.exe [OPTIONS]+ input_dzip [output_dir]

Options:
  -o, --overwrite            overwrite existing files
      --cdkey=VALUE          cdkey for use with DLC archives
                               (in format #####-#####-#####-#####)
  -e, --extension=VALUE      only extract files of this extension
  -h, --help                 show this message and exit
```

Using the steam version of the game, I actually got errors when I tried to extract dlcs with --cdkey parameter. It seemed to extract them fine without this, although I did notice that the summer/items/def_shops.xml had some corruption (first half of the first was fine but second half was a binary blob instead of xml). My guess is that this is either due to an issue with the tool or with running it under wine.


## Repacking multiple folders back into their respective dzips files

If you want to repack multiple folders into their respective dzips files, you can automate most of the work described in the next section by running the included script.

If you are on Mac/Linux, you should still read the next section to understand the required setup and make sure you have satisfied all the dependencies before running the script.

Otherwise, you can run the script from terminal. Here are samples showing different ways to run it (I recommend the last option).

```
cd "${thisRepoDir}"

# show help
./repack-all-subfolders-into-respective-dzips.sh --help

# simulate an interactively (you will be prompted for paths to parent folder containing sources and output folder where dzips will be created)
# symlinks/folders will be created during --simulate but loose files will NOT be repacked into dzip archives
./repack-all-subfolders-into-respective-dzips.sh --simulate

# run interactively (you will be prompted for paths to parent folder containing sources and output folder where dzips will be created)
# symlinks/folders will be created during AND loose files will be repacked into dzip archives
./repack-all-subfolders-into-respective-dzips.sh

# 100% automated - symlinks/folders will be created during AND loose files will be repacked into dzip archives
./repack-all-subfolders-into-respective-dzips.sh "/path/to/parent-folder-containing-sources" "/path/to/folder-where-dzips-will-be-created"
```

Here is an example:

```
gameCompatDir="/gaming/steam/steamapps/compatdata/20920/pfx/drive_c/temp";

$ ls "/gaming/MyMods/MyNewMod/sources"
base_scripts  pack0

$ cd "${thisRepo}"

$ ./repack-all-subfolders-into-respective-dzips.sh "/gaming/MyMods/MyNewMod/sources" "/gaming/MyMods/MyNewMod/repack"

$ ls "/gaming/MyMods/MyNewMod/repack"
base_scripts.dzip  pack0.dzip

```


## Repacking individual folders back into dzips files

When you want to repack a folder back into a single dzip file, this can be done with the `Gibbed.RED.Pack.exe` tool from [Gibbed RED Tools](https://www.nexusmods.com/witcher2/mods/768). On Windows, you can either drag the dzip file onto this exe or open a command prompt and pass the appropriate paths (folder path containing sources followed by output dzip file path; see help output at bottom of this section for more info).

On Linux/Mac, if you are planning to play the game under Proton (and you will need to do so if you want to use Mods as the Native version has issues with mods) then you will need to have Steam installed and enable Proton anyway. After you have run the game once, steam will create a proton (wine) prefix folder for the game under the compatdata folder. You can create a temp folder  (or symlinks) under this so can copy the Gibbed RED Tools files and whatever dzips you want to work with there. That will allow us to call the tool from Proton (wine) and to reference everything in terms of Windows paths.

The default location of the compdata folder is under `~/.local/share/Steam/steamapps` but this might change if you have added additional steam library folders. It will be under the same base path as wherever you told steam to install The Witcher 2. For the game's steam id, if you have protontricks installed then you can find this easily by running `protontricks -s witcher` or by visiting the store page in your browser and getting the id from the URL (spoiler: the steam app id for TW2 is 20920).

Once all that is taken care of, you can launch it from the terminal. Remember to adjust paths from my sample so they match with the files on your system.

Terminal:

```
# 1) WINEPREFIX - find your {steamLibraryDir}/compatdata/20920/pfx and use this path.
#	this tells wine (proton) where all the windows paths are relative to
#	meaning "C:/temp" points to "{steamLibraryDir}/compatdata/20920/pfx/drive_c/temp"
#
# 2) Use whatever version of proton you have installed, but use the wine64 binary under that install
#
# 3) after wine64 you will have C:/path/to/Gibbed.RED.Pack.exe C:/path/to/dir-containing-source-files C:/path/to/new-file-to-create.dzip
#		you will need to create/copy things to these paths ahead of time or else create symlinks such as
#			ln -s "/gaming/Mods/MyNewMod/CookedPC" "{steamLibraryDir}/compatdata/20920/pfx/drive_c/temp/ModSource"
#
# 4) Put everything together and pass it to wine
/usr/bin/env WINEPREFIX="/gaming/steam/steamapps/compatdata/20920/pfx" "/gaming/steam/steamapps/common/Proton 5.0/dist/bin/wine64" "C:/temp/tools/Gibbed.RED.Pack.exe" "C:/temp/ModSource/base_scripts" "C:/temp/repack/MyNewMod/base_scripts.dzip"
```

Gibbed.RED.Pack.exe without arguments, you will get the following output

```
Usage: Gibbed.RED.Pack.exe [OPTIONS]+ [output_dzip] input_dir+

Options:
  -v, --verbose              be verbose
  -f, --future               set file times to be in the far future
  -h, --help                 show this message and exit
```


## Mods Used

* [696-Enhanced Mod Compilation by QuietusPlus](https://www.nexusmods.com/witcher2/mods/696) \[Full Version\] | [Github](https://github.com/QuietusPlus)
* [115-Weight Watchers by Bill Jahnel](https://www.nexusmods.com/witcher2/mods/115)
* [695-Empty Hand -Dice Poker Cheat by DarkLive](https://www.nexusmods.com/witcher2/mods/695)
* [Script edit for better market prices by menyalin](https://forums.nexusmods.com/index.php?/topic/388386-market-price-mod/page-7#entry32440680)
* [867-BUGFIX Malgets notes in mysterious shop by Infintini](https://www.nexusmods.com/witcher2/mods/867)
* [823-Story Ability Bug Fixes by Midnight Voyager](https://www.nexusmods.com/witcher2/mods/823)
* [Fix for 823-Story Ability Bug Fixes breaking "Resistance To Magic" by gsuskryst](https://forums.nexusmods.com/index.php?/topic/5578077-story-ability-bug-fixes/#entry70586933)
* Additional story ability fixes in the QAddAbilityToPlayer function in quest_functions.ws, as originally suggested by menyalin [here](https://forums.nexusmods.com/index.php?/topic/3652060-broken-story-abilities-half-pirouette-etc-fixing/) and clarified by Kalessin42 [here](https://forums.nexusmods.com/index.php?/topic/5578077-story-ability-bug-fixes/#entry65086196)
* [886-Walls have ears and Suspect Thorak no longer fail after returning from the mist by Klubargutan](https://www.nexusmods.com/witcher2/mods/886)
* [763-Radovid Persuasion Fix by Tgirgis](https://www.nexusmods.com/witcher2/mods/763)
* [908-The Scent of Incense Fix by Divius](https://www.nexusmods.com/witcher2/mods/908)
* [887-Draugirs now correctly drop trophies fix by Klubargutan](https://www.nexusmods.com/witcher2/mods/887)
* [885-Wild Hunt journal entries fix and ability to discuss the Wild Hunt poem with Dandelion on Iorveths path by Klubargutan](https://www.nexusmods.com/witcher2/mods/885)
* [832-Meliteles Heart - Combat Stats Fixes by AWP3RATOR](https://www.nexusmods.com/witcher2/mods/832) - clean version of mod 799-Melitele's Heart As It Was MEANT to BE by thebunnyrules; does not break tutorial or add extra undocumented shit like thebunnyrules version























