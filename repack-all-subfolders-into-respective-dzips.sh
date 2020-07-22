#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

FOLDER_NAME="${SCRIPT_DIR##*/}";
#echo "FOLDER_NAME is $FOLDER_NAME";

GIBBED_RED_TOOLS_BOOKMARK="${SCRIPT_DIR}/GIBBED_RED_TOOLS_BOOKMARK";
PROTON_DIR_BOOKMARK="${SCRIPT_DIR}/PROTON_DIR_BOOKMARK";
WITCHER2_PFX_DIR_BOOKMARK="${SCRIPT_DIR}/WITCHER2_PFX_DIR_BOOKMARK";
WITCHER2_INSTALL_DIR_BOOKMARK="${SCRIPT_DIR}/WITCHER2_INSTALL_DIR_BOOKMARK";

showHelp='false';
if [[ "-h" == "$1" || "--help" == "$1" ]]; then
	showHelp='true';
elif [[ '' == '$1' && ! -f "$1" ]]; then
	showHelp='true';
fi
if [[ 'true' == "${showHelp}" ]]; then
	echo '-------------------------------------------------------------------------------------------------------------';
	echo 'This script is for creating dzip files from extracted The Witcher 2 assets / mods sources.';
	echo '';
	echo 'IT IS RECOMMENDED TO RUN THE WITCHER 2 LAUNCHER ONCE SO THAT THE PROTON FOLDER';
	echo 'IS CREATED AND IS AVAILABLE';
	echo 'For help setting up The Witcher 2 under Proton, see: https://gaming.stackexchange.com/a/372547/254686';
	echo '';
	echo 'Bash v4.0 or later, gnu core tools, and Gibbed RED Tools are required to run.';
	echo 'On Mac and Linux, Steam and Proton are also required.';
	echo '-------------------------------------------------------------------------------------------------------------';
	echo '';
	echo 'Expected usage':
	echo "   $0 [OPTIONS]";
	echo "   -> if no arguments are provided, user will be prompted for input by the script.";
	echo '';
	echo "   $0 [OPTIONS] [GIBBED_RED_TOOLS_DIR] SOURCES_DIR OUTPUT_DIR";
	echo '   -> script will proceed without prompts.';
	echo '';
	echo 'Arguments:';
	echo '   GIBBED_RED_TOOLS_DIR    Path to Gibbed RED Tools binaries folder. If the tools or a text file named';
	echo '                           GIBBED_RED_TOOLS_BOOKMARK containing the path are in the same folder as this';
	echo '                           script or if you have previously set the path, then this argument can be omitted.';
	echo '';
	echo '   SOURCES_DIR             Path to the folder containing extracted source files to be packed. This path is';
	echo '                           always required regardless of other options.';
	echo '';
	echo "   OUTPUT_DIR              Path where dzip files will be placed after creation. Each dzip file will be";
	echo "                           named based on the folder the contents were found in (e.g. base_scripts, pack0, etc).";
	echo '                           This path is always required regardless of other options.';
	echo '';
	echo 'Options:';
	echo "  -s, --simulate           Print out paths and commands but don't actually extract any archives.";
	echo '';
	echo "  -u, --unmodifed          Repack the existing sources dir AS-IS. Default behavior is that the sources in";
	echo "                           the script's dir are copied on top of the sources dir before repacking begins.";
	echo "                           In other words, this flag disables that default behavior.";
	echo '';
	echo "  -d, --deploy             Deploy repacked files to the installed game's CookedPC folder.";
	echo '';
	echo '-------------------------------------------------------------------------------------------------------------';
	echo 'The Gibbed RED Tools can be found at: https://www.nexusmods.com/witcher2/mods/768';
	echo 'This is the ONLY version that will receive any kind of support whatsoever.';
	echo '';
	echo 'If you are a technical type and do not need any support, there is also the possibility';
	echo 'that you might be able to build from source and run it that way. The original project';
	echo 'which is C#-based can be downloaded from here:';
	echo '     git clone https://github.com/gibbed/Gibbed.RED.git';
	echo '';
	echo 'There is also a fork which looks to have additional changes available here:';
	echo '         git clone https://github.com/yole/Gibbed.RED.git';
	echo '-------------------------------------------------------------------------------------------------------------';
	exit;
fi

SIMULATE_ONLY="false";
UNMODIFIED_SOURCES="false";
DEPLOY_FINAL_FILES="false";

# Handle first option
if [[ "-s" == "$1" || "--simulate" == "$1" ]]; then
	SIMULATE_ONLY="true";
	shift 1;
elif [[ "-u" == "$1" || "--unmodifed" == "$1" ]]; then
	UNMODIFIED_SOURCES="true";
	shift 1;
elif [[ "-d" == "$1" || "--deploy" == "$1" ]]; then
	DEPLOY_FINAL_FILES="true";
	shift 1;
fi

# Handle second option
if [[ "-s" == "$1" || "--simulate" == "$1" ]]; then
	SIMULATE_ONLY="true";
	shift 1;
elif [[ "-u" == "$1" || "--unmodifed" == "$1" ]]; then
	UNMODIFIED_SOURCES="true";
	shift 1;
elif [[ "-d" == "$1" || "--deploy" == "$1" ]]; then
	DEPLOY_FINAL_FILES="true";
	shift 1;
fi

# Handle third option
if [[ "-s" == "$1" || "--simulate" == "$1" ]]; then
	SIMULATE_ONLY="true";
	shift 1;
elif [[ "-u" == "$1" || "--unmodifed" == "$1" ]]; then
	UNMODIFIED_SOURCES="true";
	shift 1;
elif [[ "-d" == "$1" || "--deploy" == "$1" ]]; then
	DEPLOY_FINAL_FILES="true";
	shift 1;
fi

# disable mod file copying when in simulate mode
if [[ 'true' == "${SIMULATE_ONLY}" ]]; then
	UNMODIFIED_SOURCES="true";
fi

function alwaysUsePosixPaths() {
	local path="$1";
	if [[ 'true' == "${isWindows}" && $path =~ ^.*\\.*$ ]]; then
		# convert bad input to posix path
		case "${unameOut}" in
			WSL*) path="$(wslpath -a "${path}")" ;;
			CYGWIN*) path="$(cygpath "${path}")" ;;
			MINGW*) path="$(cygpath "${path}")" ;;
			*) path='' ;;
		esac
	fi
	echo "${path}";
}

function runOrSimulate () {
	if [[ "true" == "${SIMULATE_ONLY}" ]]; then
		echo "$@";
	else
		"$@" 2>&1 > /dev/null
	fi
}

# 0. Tooling check
isGnuGrep=$(grep --version 2>/dev/null|grep -ic GNU);
isGnuFind=$(find --version 2>/dev/null|grep -ic GNU);
isGnuSed=$(sed --version 2>/dev/null|grep -ic GNU);
isGnuAwk=$(awk --version 2>/dev/null|grep -ic GNU);
if [[ '0' == "${isGnuGrep}" || '0' == "${isGnuFind}" || '0' == "${isGnuSed}" || '0' == "${isGnuAwk}" ]]; then
	echo "ERROR: Script requires GNU coretools such as find, grep, sed, and awk.";
	echo "Please ensure that GNU coretools are installed and addressable on the PATH variable.";
	echo "  example: export PATH=\"/path/to/gnucoretools/bin:\$PATH\"; $0"
	exit;
fi
isBash4Plus=$(bash --version | grep -Pc 'version ([4-9]|\d{2,})\.');
if [[ '0' == "${isBash4Plus}" ]]; then
	echo "ERROR: Script requires bash version 4.0 or higher."
	exit;
fi

# 0. environment determination / env path setup
isMac='false';
isWindows='false';
windowsPathType='';
unameOut="$(uname -s)";
if [[ '1' == $(grep -ic Microsoft /proc/version) ]]; then
	isWindows='true';
	windowsPathType='wsl';
	unameOut="WSL";
else
	case "${unameOut}" in
		Linux*) windowsPathType='linux' ;;
		Darwin*) isMac='true'; windowsPathType='mac' ;;
		CYGWIN*) isWindows='true'; windowsPathType='cygwin' ;;
		MINGW*) isWindows='true'; windowsPathType='mingw' ;;
		*) windowsPathType='unknown' ;;
	esac
fi

witcher2GameInstallDir='';
witcher2ProtonPrefixDir='';
protonWineBinPath='';
steamLibraryDirsArray=(  );
protonDir='';
allowBetaVersions='false';

if [[ 'false' == "${isWindows}" ]]; then
	if [[ -z "${protonDir}" && -f "${PROTON_DIR_BOOKMARK}" ]]; then
		tempLocation="$(head -1 "${PROTON_DIR_BOOKMARK}")";
		if [[ -n "${tempLocation}" && -d "${tempLocation}" && -f "${tempLocation}/dist/bin/wine64" ]]; then
			protonDir="${tempLocation}";
			protonWineBinPath="${protonDir}/dist/bin/wine64";
		fi
	fi

	if [[ -z "${witcher2ProtonPrefixDir}" && -f "${WITCHER2_PFX_DIR_BOOKMARK}" ]]; then
		tempLocation="$(head -1 "${WITCHER2_PFX_DIR_BOOKMARK}")";
		if [[ -n "${tempLocation}" && -d "${tempLocation}" && -f "${tempLocation}/dist/bin/wine64" ]]; then
			witcher2ProtonPrefixDir="${tempLocation}";
		fi
	fi

	if [[ -z "${witcher2GameInstallDir}" && -f "${WITCHER2_INSTALL_DIR_BOOKMARK}" ]]; then
		tempLocation="$(head -1 "${WITCHER2_INSTALL_DIR_BOOKMARK}")";
		if [[ -n "${tempLocation}" && -d "${tempLocation}" && -d "${tempLocation}/CookedPC" ]]; then
			witcher2GameInstallDir="${tempLocation}";
		fi
	fi

	if [[ -z "${protonWineBinPath}" || -z "${protonDir}" || -z "${witcher2ProtonPrefixDir}" || -z "${witcher2GameInstallDir}" ]]; then
		# 1. Steam on linux will by default have a config file in home dir that contains a list of user-defined steam library folders
		#	Finding the file allows use to automatically search and find the latest installed proton version without bothering the user for it.
		#
		#   If you are reading this and wish to hard-code values to avoid the search below,
		#	then set the following variables before the start of this IF block:
		#		protonDir={steamLibDir}/steamapps/common/Proton x.x
		#		protonWineBinPath=${protonDir}/dist/bin/wine64
		#		witcher2ProtonPrefixDir={steamLibDir}/steamapps/compatdata/20920/pfx
		#		witcher2GameInstallDir={steamLibDir}/steamapps/common/the witcher 2
		#
		steamConfigFile='';

		# i've seen both of these paths on nix systems before; handle both cases
		if [[ -f "${HOME}/.steam/config/config.vdf" ]]; then
		    steamConfigFile="${HOME}/.steam/config/config.vdf";

		elif [[ -f "${HOME}/.local/share/Steam/config/config.vdf" ]]; then
		    steamConfigFile="${HOME}/local/share/Steam/config/config.vdf";
		fi

		if [[ -d "${HOME}/.local/share/Steam/steamapps/common" ]]; then
			# add default steam install location
			steamLibraryDirsArray+=("${HOME}/.local/share/Steam/steamapps/common");
		fi

		if [[ -n "${steamConfigFile}" ]]; then
			if [[ "" != "${steamConfigFile}" && -f "${steamConfigFile}" ]]; then
			    while IFS= read -r steamDownloadFolder; do
			        if [[ "" == "${steamDownloadFolder}" ]]; then
			            #echo "Skipping empty steamDownloadFolder";
			            continue;
			        fi
			        if [[ -d "${steamDownloadFolder}/steamapps/common" && "0" != $(find "${steamDownloadFolder}/steamapps/common" -mindepth 1 -maxdepth 1 -type d 2>/dev/null|wc -l) ]]; then
			            steamLibraryDirsArray+=("${steamDownloadFolder}/steamapps/common");
			        fi

			    done < <(grep -P '"BaseInstallFolder_\d"' "${steamConfigFile}"|sed -E 's/^\s*"BaseInstallFolder_[0-9][0-9]*"\s+"([^"]+)"\s*$/\1/g')
			fi
			if [[ -z "${witcher2ProtonPrefixDir}" || -z "${witcher2GameInstallDir}" ]]; then
				for steamDownloadDir in "${steamLibraryDirsArray[@]}"; do
					#echo "steamDownloadDir in array is $steamDownloadDir";

					# check for game compat dir
					gameCompatDir="$(dirname "${steamDownloadDir}")/compatdata/20920/pfx";
					if [[ -z "${witcher2ProtonPrefixDir}" && -d "${gameCompatDir}" ]]; then
					 	witcher2ProtonPrefixDir="${gameCompatDir}";
					 	if [[ -n "${WITCHER2_PFX_DIR_BOOKMARK}" ]]; then
					 		echo "${witcher2ProtonPrefixDir}" > "${WITCHER2_PFX_DIR_BOOKMARK}";
					 	fi
				 		if [[ -n "${witcher2ProtonPrefixDir}" && -n "${witcher2GameInstallDir}" ]]; then
					 		break;
					 	fi
					fi;

					# check for game install dir
					if [[ -z "${witcher2GameInstallDir}" && -d "${steamDownloadDir}/common/the witcher 2/CookedPC" ]]; then
						witcher2GameInstallDir="${steamDownloadDir}/common/the witcher 2";
					 	if [[ -n "${WITCHER2_INSTALL_DIR_BOOKMARK}" ]]; then
					 		echo "${witcher2GameInstallDir}" > "${WITCHER2_INSTALL_DIR_BOOKMARK}";
					 	fi
				 		if [[ -n "${witcher2ProtonPrefixDir}" && -n "${witcher2GameInstallDir}" ]]; then
					 		break;
					 	fi
				 	fi
				done
				echo "witcher2GameInstallDir: ${witcher2GameInstallDir}";
				echo "witcher2ProtonPrefixDir: ${witcher2ProtonPrefixDir}";
			fi
			if [[ '' == "${witcher2ProtonPrefixDir}" ]]; then
				echo 'ERROR: witcher2ProtonPrefixDir does not exist. Run The Witcher 2 under Proton once so that Steam will generate this folder.';
				echo 'For help setting up The Witcher 2 under Proton, see https://gaming.stackexchange.com/a/372547/254686';
				exit;
			fi

			if [[ '' == "${protonDir}" ]]; then
				for steamDownloadDir in "${steamLibraryDirsArray[@]}"; do
				    #echo "steamDownloadDir in array is $steamDownloadDir";
					while IFS= read -r -d '' tempProtonDir; do
						#echo "=========="
						if [[ "" == "${tempProtonDir}" ]]; then
							continue;
						fi
						#echo "tempProtonDir: '${tempProtonDir}'";
						#echo "protonDir: '${protonDir}'";

						currProtonName=$(basename "${tempProtonDir}");
						isCurrProtonBeta=$(echo "${currProtonName}"|grep -ic Beta);

						#echo "currProtonName: '${currProtonName}'";
						#echo "isCurrProtonBeta: '${isCurrProtonBeta}'";

						if [[ "false" == "${allowBetaVersions}" && '0' != "${isCurrProtonBeta}" ]]; then
							# if betas are not allowed, then skip
							continue;
						fi

						# if this is the first proton path, we've encountered then set it as the current proton path until something newer is discovered
						if [[ -z "${protonDir}" ]]; then
							protonDir="${tempProtonDir}";
							#echo "protonDir updated to: '${protonDir}'";
							continue;
						fi


						# get old and new proton version for comparison
						currProtonVersion=$(echo "$currProtonName"|sed -E 's/Proton ([1-9]+\.[0-9]+)( Beta)?$/\1/gi');
						prevProtonName=$(basename "${protonDir}");
						prevProtonVersion=$(echo "$prevProtonName"|sed -E 's/Proton ([1-9]+\.[0-9]+)( Beta)?$/\1/gi');

						#echo "currProtonVersion: '${currProtonVersion}'";
						#echo "prevProtonName: '${prevProtonName}'";
						#echo "prevProtonVersion: '${prevProtonVersion}'";

						# handle beta vs stable version. if version is the same then stable should be considered as newer than beta
						if [[ "false" != "${allowBetaVersions}" && "${currProtonVersion}" == "${prevProtonVersion}" ]]; then
							isPrevProtonBeta=$(echo "${prevProtonName}"|grep -ic Beta);
							if [[ "1" == "${isPrevProtonBeta}" && "0" == "${isCurrProtonBeta}" ]]; then
								protonDir="${tempProtonDir}";
								continue;
							fi
						fi

						currMajorVersion=$(echo "$currProtonVersion"|cut -d. -f1);
						prevMajorVersion=$(echo "$prevProtonVersion"|cut -d. -f1);

						#echo "currMajorVersion: '${currMajorVersion}'";
						#echo "prevMajorVersion: '${prevMajorVersion}'";

						# if currVersion is lower than the one we've got, then ignore it and check next path
						if (( $currMajorVersion < $prevMajorVersion )); then
							continue
						fi

						# if it is higher, then update and continue to check next path
						if (( $currMajorVersion > $prevMajorVersion )); then
							protonDir="${tempProtonDir}";
							continue;
						fi

						if [[ "${currMajorVersion}" == "${prevMajorVersion}" ]]; then
							currMinorVersion=$(echo "$currProtonVersion"|cut -d. -f2);
							prevMinorVersion=$(echo "$prevProtonVersion"|cut -d. -f2);

							#echo "currMinorVersion: '${currMinorVersion}'";
							#echo "prevMinorVersion: '${prevMinorVersion}'";

							# there should never be a scenario where the major and minor versions were all equal
							# but if it did happen it would just mean there are 2 copies of the same version
							# so either is fine.
							if (( $currMinorVersion == $prevMinorVersion )); then
								continue;
							fi

							# so only change selected version if the new version is higher than previous
							if (( $currMinorVersion > $prevMinorVersion )); then
								protonDir="${tempProtonDir}";
								continue;
							fi
						fi

					done < <(find "${steamDownloadDir}" -maxdepth 1 -type d -iname 'Proton*' -not \( -iname '*bak' -o -iname '*back*' -o -iname '*orig*' \) -print0)
				done
			fi
			echo "protonDir: '${protonDir}'";
		fi

		if [[ '' != "${protonDir}" && -d "${protonDir}" && -f "${protonDir}/dist/bin/wine64" ]]; then
			protonWineBinPath="${protonDir}/dist/bin/wine64";
		 	if [[ -n "${PROTON_DIR_BOOKMARK}" ]]; then
		 		echo "${protonDir}" > "${PROTON_DIR_BOOKMARK}";
		 	fi
		fi

		echo "Found protonWineBinPath binary as: '${protonWineBinPath}'";
	fi

elif [[ 'true' == "${isWindows}" && -z "${witcher2GameInstallDir}" ]]; then

	# 1. Steam on 64-bit windows will by default have a config file in "C:/Program Files (x86)/Steam/config" dir that contains a list of
	#	 user-defined steam library folders. Finding the file allows use to automatically search and find the game install dir without
	#	 bothering the user for it.
	#
	#   If you are reading this and wish to hard-code values to avoid the search below,
	#	then set the following variables before the start of this IF block:
	#		witcher2GameInstallDir={steamLibDir}/steamapps/common/the witcher 2
	#
	#	Note: the folder "the witcher 2" is case-sensitive when accessing it from bash, even if windows is case-insenstive
	steamConfigFile='';

	steamInstallDir=$(alwaysUsePosixPaths 'C:\Program Files (x86)\Steam');

	# i've seen both of these paths on nix systems before; handle both cases
	if [[ -f "${steamInstallDir}/config/config.vdf" ]]; then
	    steamConfigFile="${steamInstallDir}/config/config.vdf";
	fi

	if [[ -d "${steamInstallDir}/steamapps/common" ]]; then
		# add default steam install location
		steamLibraryDirsArray+=("${steamInstallDir}/steamapps/common");

	elif [[ -d "${steamInstallDir}/SteamApps/common" ]]; then
		# add default steam install location
		steamLibraryDirsArray+=("${steamInstallDir}/SteamApps/common");
	fi

	for steamDownloadDir in "${steamLibraryDirsArray[@]}"; do
		#echo "steamDownloadDir in array is $steamDownloadDir";

		# handle some case-sensitives that are present in some rare older steam installs
		steamAppsCommon='';
		if [[ -d "${steamDownloadDir}/steamapps/common" ]]; then
			# seet library location
			steamAppsCommon="${steamDownloadDir}/steamapps/common";

		elif [[ -d "${steamDownloadDir}/SteamApps/common" ]]; then
			# seet library location
			steamAppsCommon="${steamDownloadDir}/SteamApps/common";
		fi

		# if commons dir not found, go to next location
		if [[ -z "${steamAppsCommon}" || ! -d "${steamAppsCommon}" ]]; then
			break;
		fi

		# handle some case-sensitives that are present in some rare cases
		gameDir='';
		if [[ -d "${steamAppsCommon}/the witcher 2" ]]; then
			# game install location
			gameDir="${steamAppsCommon}/the witcher 2";

		elif [[ -d "${steamAppsCommon}/The Witcher 2" ]]; then
			# game install location
			gameDir="${steamAppsCommon}/The Witcher 2";
		fi

		# check for game install dir
		if [[ -z "${witcher2GameInstallDir}" && -d "${gameDir}/CookedPC" ]]; then
			witcher2GameInstallDir="${gameDir}";
		 	if [[ -n "${WITCHER2_INSTALL_DIR_BOOKMARK}" ]]; then
		 		echo "${witcher2GameInstallDir}" > "${WITCHER2_INSTALL_DIR_BOOKMARK}";
		 	fi
	 		if [[ -n "${witcher2GameInstallDir}" ]]; then
		 		break;
		 	fi
	 	fi
	done
	echo "witcher2GameInstallDir: ${witcher2GameInstallDir}";
fi

if [[ 'true' == "${DEPLOY_FINAL_FILES}" && -z "${witcher2GameInstallDir}" ]]; then
	echo "ERROR: Detected --deploy option but witcher2GameInstallDir not found '${witcher2GameInstallDir}'";
	exit
elif [[ 'true' == "${DEPLOY_FINAL_FILES}" && ! -d "${witcher2GameInstallDir}/CookedPC" ]]; then
	echo "ERROR: Detected --deploy option but directory '${witcher2GameInstallDir}/CookedPC' not found / does not exist.";
	exit
fi

# 1. check locations of (a) tools, (b) dzip folder (CookedPC/Mods), (c) output folder for extracted sources
#	 and prompt user for any missing info
GIBBED_PACKER_FILENAME="Gibbed.RED.Pack.exe";
arg1="$1";
if [[ -n "${arg1}" ]]; then
	# convert any bad input to posix path
	arg1="$(alwaysUsePosixPaths "${arg1}")";
fi

if [[ -n "${arg1}" && -d "${arg1}" && -f "${arg1}/${GIBBED_PACKER_FILENAME}" ]]; then
	gibbedRedToolsDir="${arg1}";
	shift 1;
else
	# check the obvious places before prompting user...
	if [[ -n "${GIBBED_RED_TOOLS_BOOKMARK}" && -f "${GIBBED_RED_TOOLS_BOOKMARK}" ]]; then
		bookmarkValue=$(head -1 "${GIBBED_RED_TOOLS_BOOKMARK}");
		if [[ -n "${bookmarkValue}" ]]; then
			# convert any bad input to posix path
			bookmarkValue="$(alwaysUsePosixPaths "${bookmarkValue}")";
			if [[ -n "${bookmarkValue}" && -d "${bookmarkValue}" && -f "${bookmarkValue}/${GIBBED_PACKER_FILENAME}" ]]; then
				gibbedRedToolsDir="${bookmarkValue}";
			fi
		fi
	fi

	if [[ -z "${gibbedRedToolsDir}" && -f "${SCRIPT_DIR}/${GIBBED_PACKER_FILENAME}" ]]; then
		gibbedRedToolsDir="${SCRIPT_DIR}/${GIBBED_PACKER_FILENAME}";
	fi

	if [[ -z "${gibbedRedToolsDir}" && -f "${SCRIPT_DIR}/bin/${GIBBED_PACKER_FILENAME}" ]]; then
		gibbedRedToolsDir="${SCRIPT_DIR}/bin/${GIBBED_PACKER_FILENAME}";
	fi

	if [[ -z "${gibbedRedToolsDir}" && -f "${SCRIPT_DIR}/Gibbed-RED-Tools/${GIBBED_PACKER_FILENAME}" ]]; then
		gibbedRedToolsDir="${SCRIPT_DIR}/Gibbed-RED-Tools/${GIBBED_PACKER_FILENAME}";
	fi

	if [[ -z "${gibbedRedToolsDir}" && -f "${SCRIPT_DIR}/Gibbed RED Tools/${GIBBED_PACKER_FILENAME}" ]]; then
		gibbedRedToolsDir="${SCRIPT_DIR}/Gibbed RED Tools/${GIBBED_PACKER_FILENAME}";
	fi

	if [[ -z "${gibbedRedToolsDir}" && -f "${SCRIPT_DIR}/Gibbed Red Tools-768-/Gibbed RED Tools/${GIBBED_PACKER_FILENAME}" ]]; then
		gibbedRedToolsDir="${SCRIPT_DIR}/Gibbed Red Tools-768-/Gibbed RED Tools/${GIBBED_PACKER_FILENAME}";
	fi
fi

# if still empty after all that, then prompt the user
if [[ -z "${gibbedRedToolsDir}" ]]; then
	promptText='Please enter the FOLDER path containing your Gibbed RED Tools exes';
	if [[ 'true' == "${isWindows}" ]]; then
		promptText='${promptText}\n(Note: ALL Windows paths must be enclosed within quotes)';
	fi
	while [[ -z "${gibbedRedToolsDir}" ]]; do
		echo "";
		typedPath='';
		printf "${promptText}:\n";
		read typedPath;
		if [[ -n "${typedPath}" ]]; then
			# convert bad input to posix path
			typedPath="$(alwaysUsePosixPaths "${typedPath}")";
			if [[ ! -d "${typedPath}" ]]; then
				echo "ERROR: Path '${typedPath}' is not a valid directory.";
				echo "Please try again or press Ctrl+C to abort.";
				typedPath="";

			elif [[ ! -f "${typedPath}/${GIBBED_PACKER_FILENAME}" ]]; then
				echo "ERROR: Path '${typedPath}' does not contain ${GIBBED_PACKER_FILENAME}.";
				echo "Please try again or press Ctrl+C to abort.";
				typedPath="";
			else
				gibbedRedToolsDir="${typedPath}";
			fi
		fi
	done
fi

# if we got a path path, then bookmark it for next time; otherwise do final error check on gibbed tools path
if [[ -n "${gibbedRedToolsDir}" && -n "${GIBBED_RED_TOOLS_BOOKMARK}" && -d "${gibbedRedToolsDir}" && -f "${gibbedRedToolsDir}/${GIBBED_PACKER_FILENAME}" ]]; then
	echo "${gibbedRedToolsDir}"	>> "${GIBBED_RED_TOOLS_BOOKMARK}";
elif [[ -z "${gibbedRedToolsDir}" ]]; then
	echo 'ERROR: gibbedRedToolsDir undefined.';
	exit;
elif [[ ! -d "${gibbedRedToolsDir}" ]]; then
	echo "ERROR: gibbedRedToolsDir '${gibbedRedToolsDir}' not found.";
	exit;
elif [[ ! -f "${gibbedRedToolsDir}/${GIBBED_PACKER_FILENAME}" ]]; then
	echo "ERROR: gibbedRedToolsDir '${gibbedRedToolsDir}' does not contain ${GIBBED_PACKER_FILENAME}.";
	exit;
fi
#echo '';
#echo "gibbedRedToolsDir: '${gibbedRedToolsDir}' ";

sourceFilesDir="$1";
if [[ -n "${sourceFilesDir}" ]]; then
	# convert any bad input to posix path
	sourceFilesDir="$(alwaysUsePosixPaths "${sourceFilesDir}")";

	if [[ ! -d "${sourceFilesDir}" ]]; then
		echo "ERROR: sourceFilesDir '${sourceFilesDir}' not found.";
		exit;
	fi
fi

echo '';
if [[ -z "${sourceFilesDir}" ]]; then
	promptText='Please enter the FOLDER path containing your dzip files such as CookedPC or a Mod folder';
	if [[ 'true' == "${isWindows}" ]]; then
		promptText='${promptText}\n(Note: ALL Windows paths must be enclosed within quotes): ';
	fi
	while [[ -z "${sourceFilesDir}" ]]; do
		echo "";
		typedPath="";
		printf "${promptText}:\n";
		read typedPath;
		if [[ -n "${typedPath}" ]]; then
			# convert bad input to posix path
			typedPath="$(alwaysUsePosixPaths "${typedPath}")";
			if [[ ! -d "${typedPath}" ]]; then
				echo "ERROR: Path '${typedPath}' is not a valid directory.";
				echo "Please try again or press Ctrl+C to abort.";
				typedPath="";
			else
				sourceFilesDir="${typedPath}";
			fi
		fi
	done
fi
#echo '';
#echo "sourceFilesDir: '${sourceFilesDir}' ";

outputDir="$2";
if [[ -n "${outputDir}" ]]; then
	# convert any bad input to posix path
	outputDir="$(alwaysUsePosixPaths "${outputDir}")";
	mkdir -p "${outputDir}" 2>/dev/null;
	if [[ ! -d "${outputDir}" ]]; then
		echo "ERROR: Unable to create passed outputDir '${outputDir}'.";
		exit;
	fi
fi

echo '';
if [[ -z "${outputDir}" ]]; then
	promptText='Please enter the FOLDER path where you would like the dzip output extracted to';
	if [[ 'true' == "${isWindows}" ]]; then
		promptText='${promptText}\n(Note: ALL Windows paths must be enclosed within quotes): ';
	fi
	while [[ -z "${outputDir}" ]]; do
		echo "";
		typedPath="";
		printf "${promptText}:\n";
		read typedPath;
		if [[ -n "${typedPath}" ]]; then
			# convert bad input to posix path
			typedPath="$(alwaysUsePosixPaths "${typedPath}")";
			if [[ "${typedPath}" == "${sourceFilesDir}" ]]; then
				echo "ERROR: The outputDir '${typedPath}' cannot be the same folder as sourceFilesDir.";
				echo "Please try again or press Ctrl+C to abort.";
				continue;
			fi

			if [[ "$(realpath "${typedPath}")" == "$(realpath "${sourceFilesDir}")" ]]; then
				echo "ERROR: The outputDir '${typedPath}' cannot point to the same location as sourceFilesDir.";
				echo "Please try again or press Ctrl+C to abort.";
				continue;
			fi

			if [[ ! -d "${typedPath}" ]]; then
				mkdir -p "${typedPath}" 2>/dev/null;
			fi
			if [[ ! -d "${typedPath}" ]]; then
				echo "ERROR: Unable to create outputDir '${typedPath}'.";
				echo "Please try again or press Ctrl+C to abort.";
			else
				outputDir="${typedPath}";
			fi
		fi
	done
fi
#echo '';
#echo "outputDir: '${outputDir}' ";


if [[ -z "${sourceFilesDir}" ]]; then
	echo 'ERROR: sourceFilesDir undefined.';
	exit;
fi
if [[ -z "${outputDir}" ]]; then
	echo 'ERROR: outputDir undefined.';
	exit;
fi
if [[ 'false' == "${isWindows}" && -z "${protonWineBinPath}" ]]; then
	echo 'ERROR: Steam Play (aka Proton) or Wine not found. ';
	echo '  -> If Steam is already installed, enable Proton and make sure it is downloaded.';
	echo '     See: https://fosspost.org/tutorials/enable-steam-play-on-linux-to-run-windows-games';
	echo '';
	echo '  -> Otherwise, install Steam + Proton or install wine via your package manager or from winehq.org';
fi

reset;
echo '==============================================================================';
if [[ 'false' == "${isWindows}" ]]; then
	echo "protonWineBinPath: '${protonWineBinPath}'";
fi
echo "gibbedRedToolsDir: '${gibbedRedToolsDir}' ";
echo "sourceFilesDir: '${sourceFilesDir}' ";
echo  "outputDir: '${outputDir}' ...";
echo '==============================================================================';

startDir=$(pwd);


# 2. Copy sources (or not) depending on options
if [[ "true" != "${UNMODIFIED_SOURCES}" && -d "${SCRIPT_DIR}/CookedPC" ]]; then
	cd "${SCRIPT_DIR}/CookedPC";

	while IFS= read -r -d '' relativeDirPathToBeBeRepacked; do
		cp -a -t "${sourceFilesDir}" "${SCRIPT_DIR}/CookedPC/${relativeDirPathToBeBeRepacked:1}";
	done < <(find . -mindepth 1 -maxdepth 1 -type d -not -iname '.git' -print0)
fi

# 3. Extract dzips

# setup wine paths: when we pass the paths to wine, we want the windows app to use
# to use a format like "C:/temp/output"
#
wineToolsDir='';
wineSourcesDir='';
wineOutputDir='';
if [[ 'false' == "${isWindows}" ]]; then
	echo "Checking symlinks...";

	mkdir -p "${witcher2ProtonPrefixDir}/drive_c/temp" 2>/dev/null;
	if [[ ! -d "${witcher2ProtonPrefixDir}/drive_c/temp" ]]; then
		echo "ERROR: Faild to create temp directory at '${witcher2ProtonPrefixDir}/drive_c/temp'.";
		exit;
	fi

	if [[ "${gibbedRedToolsDir}" != "${witcher2ProtonPrefixDir}/drive_c/temp/Gibbed-RED-Tools" ]]; then
		if [[ -L "${witcher2ProtonPrefixDir}/drive_c/temp/Gibbed-RED-Tools" ]]; then
			rm "${witcher2ProtonPrefixDir}/drive_c/temp/Gibbed-RED-Tools" 2>/dev/null;
		fi
		ln -sf "${gibbedRedToolsDir}" "${witcher2ProtonPrefixDir}/drive_c/temp/Gibbed-RED-Tools";
	fi
	wineToolsDir="C:/temp/Gibbed-RED-Tools";

	if [[ "${sourceFilesDir}" != "${witcher2ProtonPrefixDir}/drive_c/temp/sources" ]]; then
		if [[ -L "${witcher2ProtonPrefixDir}/drive_c/temp/sources" ]]; then
			rm "${witcher2ProtonPrefixDir}/drive_c/temp/sources" 2>/dev/null;
		fi
		ln -sf "${sourceFilesDir}" "${witcher2ProtonPrefixDir}/drive_c/temp/sources";
	fi
	wineSourcesDir="C:/temp/sources";

	if [[ "${outputDir}" != "${witcher2ProtonPrefixDir}/drive_c/temp/repacks" ]]; then
		if [[ -L "${witcher2ProtonPrefixDir}/drive_c/temp/repacks" ]]; then
			rm "${witcher2ProtonPrefixDir}/drive_c/temp/repacks" 2>/dev/null;
		fi
		ln -sf "${outputDir}" "${witcher2ProtonPrefixDir}/drive_c/temp/repacks";
	fi
	wineOutputDir="C:/temp/repacks";
else
	# windows
	wineToolsDir="${gibbedRedToolsDir}";
	wineSourcesDir="${sourceFilesDir}";
	wineOutputDir="${outputDir}";
fi
#echo "wineToolsDir: ${wineToolsDir}";
#echo "wineSourcesDir: ${wineSourcesDir}";
#echo "wineOutputDir: ${wineOutputDir}";


# Change to sourceFilesDir so that we can use "find ." to make the paths all relative
cd "${sourceFilesDir}";

modePrefix='';
if [[ "true" == "${SIMULATE_ONLY}" ]]; then
	modePrefix="echo";
fi

while IFS= read -r -d '' relativeDirPathToBeBeRepacked; do
	#echo "relativeDirPathToBeBeRepacked: ${relativeDirPathToBeBeRepacked}";
	if [[ "" == "${relativeDirPathToBeBeRepacked}" ]]; then
		continue;
	fi
	echo '';

	# set file path to be passed to windows app
	wineDirPath="${wineSourcesDir}${relativeDirPathToBeBeRepacked:1}"
	#echo "wineDirPath: ${wineDirPath}";

	# set output dir to be passed to windows app
	relativeOutputFilePath="${relativeDirPathToBeBeRepacked:1}.dzip";
	#echo "relativeOutputFilePath: ${relativeOutputFilePath}";

	realOutputFilePath="${outputDir}${relativeOutputFilePath}";
	#echo "realOutputFilePath: ${realOutputFilePath}";

	wineOutputFilePath="${wineOutputDir}${relativeOutputFilePath}";
	#echo "wineOutputFilePath: ${wineOutputFilePath}";

	# make sure output dir exists
	dirSize=''
	if [[ 'false' == "${isWindows}" ]]; then
		dirSize="$(du -hs "${relativeDirPathToBeBeRepacked}"|sed -E 's/^(\S+)\s+.*$/\1/g')";
	fi
	echo "Repacking ${relativeDirPathToBeBeRepacked} [${dirSize}] ...";
	if [[ '1' == "$(echo "${dirSize}"|grep -Pc '^([.\d]+G|\d{3,}M)$')" ]]; then
		echo "Note: This folder is larger and may take awhile to process. Please be patient.";
	fi

	# invoke windows app to extract dzip files
	if [[ 'false' == "${isWindows}" ]]; then
		# Note: WINEDEBUG=-all is to get rid of wine debug messages/warnings such as "fixme" that just create console noise
		runOrSimulate /usr/bin/env WINEDEBUG=-all WINEPREFIX="${witcher2ProtonPrefixDir}" "${protonWineBinPath}" "${wineToolsDir}/${GIBBED_PACKER_FILENAME}" "${wineOutputFilePath}" "${wineDirPath}"
	else
		runOrSimulate "${wineToolsDir}/${GIBBED_PACKER_FILENAME}" "${wineOutputFilePath}" "${wineDirPath}"
	fi
	if [[ -f "${realOutputFilePath}" ]]; then
		runOrSimulate cp -a "${realOutputFilePath}" "${realOutputFilePath}.$(date +'%Y-%m-%d@%H.%M.%S').bak";
		if [[ 'true' == "${DEPLOY_FINAL_FILES}" ]]; then
			runOrSimulate cp -a "${realOutputFilePath}" "${witcher2GameInstallDir}/CookedPC/${relativeOutputFilePath}";
		fi
	fi

done < <(find . -mindepth 1 -maxdepth 1 -type d -print0)

# restore startDir
cd "${startDir}";
