#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

FOLDER_NAME="${SCRIPT_DIR##*/}";
#echo "FOLDER_NAME is $FOLDER_NAME";

GIBBED_RED_TOOLS_BOOKMARK="${SCRIPT_DIR}/GIBBED_RED_TOOLS_BOOKMARK";
PROTON_DIR_BOOKMARK="${SCRIPT_DIR}/PROTON_DIR_BOOKMARK";
WITCHER2_PFX_DIR_BOOKMARK="${SCRIPT_DIR}/WITCHER2_PFX_DIR_BOOKMARK";

showHelp='false';
if [[ "-h" == "$1" || "--help" == "$1" ]]; then
	showHelp='true';
elif [[ '' == '$1' && ! -f "$1" ]]; then
	showHelp='true';
fi
if [[ 'true' == "${showHelp}" ]]; then
	echo '---------------------------------------------------------------------------------';
	echo 'This script is for extracting dzip files from The Witcher 2 base game and mods.';
	echo '';
	echo 'IT IS RECOMMENDED TO RUN THE WITCHER 2 LAUNCHER ONCE SO THAT THE PROTON FOLDER';
	echo 'IS CREATED AND IS AVAILABLE';
	echo 'For help setting up The Witcher 2 under Proton, see: https://gaming.stackexchange.com/a/372547/254686';
	echo '';
	echo 'Bash v4.0 or later, gnu core tools, and Gibbed RED Tools are required to run.';
	echo 'On Mac and Linux, Steam and Proton are also required.';
	echo '---------------------------------------------------------------------------------';
	echo '';
	echo 'Expected usage':
	echo "   $0 [OPTIONS]";
	echo "   -> if no arguments are provided, user will be prompted for input by the script.";
	echo '';
	echo "   $0 [OPTIONS] [GIBBED_RED_TOOLS_DIR] DZIP_DIR OUTPUT_DIR";
	echo '   -> script will proceed without prompts.';
	echo '';
	echo 'Arguments:';
	echo '   GIBBED_RED_TOOLS_DIR    Path to Gibbed RED Tools binaries folder. If the tools or a text file named';
	echo '                           GIBBED_RED_TOOLS_BOOKMARK containing the path are in the same folder as this';
	echo '                           script or if you have previously set the path, then this argument can be omitted.';
	echo '';
	echo '   DZIP_DIR                Path to the folder containing dzip files to be extracted. This path is';
	echo '                           always required regardless of other options.';
	echo '';
	echo "   OUTPUT_DIR              Path where dzip files will be extracted under. Each dzip file's contents";
	echo "                           will be nested under a folder with the same name as the dzip file.";
	echo '                           This path is always required regardless of other options.';
	echo '';
	echo 'Options:';
	echo "  -s, --simulate           Print out paths and commands but don't actually extract any archives.";
	echo '';
	echo '---------------------------------------------------------------------------------';
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
	echo '---------------------------------------------------------------------------------';
	exit;
fi

SIMULATE_ONLY="false";
if [[ "-s" == "$1" || "--simulate" == "$1" ]]; then
	SIMULATE_ONLY="true";
	shift 1;
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

witcher2ProtonPrefix='';
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

	if [[ -z "${witcher2ProtonPrefix}" && -f "${WITCHER2_PFX_DIR_BOOKMARK}" ]]; then
		tempLocation="$(head -1 "${WITCHER2_PFX_DIR_BOOKMARK}")";
		if [[ -n "${tempLocation}" && -d "${tempLocation}" && -f "${tempLocation}/dist/bin/wine64" ]]; then
			witcher2ProtonPrefix="${tempLocation}";
		fi
	fi

	if [[ '' == "${protonWineBinPath}" || '' == "${protonDir}" || '' == "${witcher2ProtonPrefix}" ]]; then
		# 1. Steam on linux will by default have a config file in home dir that contains a list of user-defined steam library folders
		#	Finding the file allows use to automatically search and find the latest installed proton version without bothering the user for it.
		#
		#   If you are reading this and wish to hard-code values to avoid the search below,
		#	then set the following variables before the start of this IF block:
		#		protonDir={steamLibDir}/steamapps/common/Proton x.x
		#		protonWineBinPath=${protonDir}/dist/bin/wine64
		#		witcher2ProtonPrefix={steamLibDir}/steamapps/compatdata/20920/pfx
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
			if [[ '' == "${witcher2ProtonPrefix}" ]]; then
				for steamDownloadDir in "${steamLibraryDirsArray[@]}"; do
					#echo "steamDownloadDir in array is $steamDownloadDir";
					 gameCompatDir="$(dirname "${steamDownloadDir}")/compatdata/20920/pfx";
					 if [[ -d "${gameCompatDir}" ]]; then
					 	witcher2ProtonPrefix="${gameCompatDir}";
					 	if [[ -n "${WITCHER2_PFX_DIR_BOOKMARK}" ]]; then
					 		echo "${witcher2ProtonPrefix}" > "${WITCHER2_PFX_DIR_BOOKMARK}";
					 	fi
					 	break;
					fi;
				done
				echo "witcher2ProtonPrefix: ${witcher2ProtonPrefix}";
			fi
			if [[ '' == "${witcher2ProtonPrefix}" ]]; then
				echo 'ERROR: witcher2ProtonPrefix does not exist. Run The Witcher 2 under Proton once so that Steam will generate this folder.';
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
fi

# 1. check locations of (a) tools, (b) dzip folder (CookedPC/Mods), (c) output folder for extracted sources
#	 and prompt user for any missing info
GIBBED_EXTRACT_FILENAME="Gibbed.RED.Unpack.exe";
arg1="$1";
if [[ -n "${arg1}" ]]; then
	# convert any bad input to posix path
	arg1="$(alwaysUsePosixPaths "${arg1}")";
fi

if [[ -n "${arg1}" && -d "${arg1}" && -f "${arg1}/${GIBBED_EXTRACT_FILENAME}" ]]; then
	gibbedRedToolsDir="${arg1}";
	shift 1;
else
	# check the obvious places before prompting user...
	if [[ -n "${GIBBED_RED_TOOLS_BOOKMARK}" && -f "${GIBBED_RED_TOOLS_BOOKMARK}" ]]; then
		bookmarkValue=$(head -1 "${GIBBED_RED_TOOLS_BOOKMARK}");
		if [[ -n "${bookmarkValue}" ]]; then
			# convert any bad input to posix path
			bookmarkValue="$(alwaysUsePosixPaths "${bookmarkValue}")";
			if [[ -n "${bookmarkValue}" && -d "${bookmarkValue}" && -f "${bookmarkValue}/${GIBBED_EXTRACT_FILENAME}" ]]; then
				gibbedRedToolsDir="${bookmarkValue}";
			fi
		fi
	fi

	if [[ -z "${gibbedRedToolsDir}" && -f "${SCRIPT_DIR}/${GIBBED_EXTRACT_FILENAME}" ]]; then
		gibbedRedToolsDir="${SCRIPT_DIR}/${GIBBED_EXTRACT_FILENAME}";
	fi

	if [[ -z "${gibbedRedToolsDir}" && -f "${SCRIPT_DIR}/bin/${GIBBED_EXTRACT_FILENAME}" ]]; then
		gibbedRedToolsDir="${SCRIPT_DIR}/bin/${GIBBED_EXTRACT_FILENAME}";
	fi

	if [[ -z "${gibbedRedToolsDir}" && -f "${SCRIPT_DIR}/Gibbed-RED-Tools/${GIBBED_EXTRACT_FILENAME}" ]]; then
		gibbedRedToolsDir="${SCRIPT_DIR}/Gibbed-RED-Tools/${GIBBED_EXTRACT_FILENAME}";
	fi

	if [[ -z "${gibbedRedToolsDir}" && -f "${SCRIPT_DIR}/Gibbed RED Tools/${GIBBED_EXTRACT_FILENAME}" ]]; then
		gibbedRedToolsDir="${SCRIPT_DIR}/Gibbed RED Tools/${GIBBED_EXTRACT_FILENAME}";
	fi

	if [[ -z "${gibbedRedToolsDir}" && -f "${SCRIPT_DIR}/Gibbed Red Tools-768-/Gibbed RED Tools/${GIBBED_EXTRACT_FILENAME}" ]]; then
		gibbedRedToolsDir="${SCRIPT_DIR}/Gibbed Red Tools-768-/Gibbed RED Tools/${GIBBED_EXTRACT_FILENAME}";
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

			elif [[ ! -f "${typedPath}/${GIBBED_EXTRACT_FILENAME}" ]]; then
				echo "ERROR: Path '${typedPath}' does not contain ${GIBBED_EXTRACT_FILENAME}.";
				echo "Please try again or press Ctrl+C to abort.";
				typedPath="";
			else
				gibbedRedToolsDir="${typedPath}";
			fi
		fi
	done
fi

# if we got a path path, then bookmark it for next time; otherwise do final error check on gibbed tools path
if [[ -n "${gibbedRedToolsDir}" && -n "${GIBBED_RED_TOOLS_BOOKMARK}" && -d "${gibbedRedToolsDir}" && -f "${gibbedRedToolsDir}/${GIBBED_EXTRACT_FILENAME}" ]]; then
	echo "${gibbedRedToolsDir}"	>> "${GIBBED_RED_TOOLS_BOOKMARK}";
elif [[ -z "${gibbedRedToolsDir}" ]]; then
	echo 'ERROR: gibbedRedToolsDir undefined.';
	exit;
elif [[ ! -d "${gibbedRedToolsDir}" ]]; then
	echo "ERROR: gibbedRedToolsDir '${gibbedRedToolsDir}' not found.";
	exit;
elif [[ ! -f "${gibbedRedToolsDir}/${GIBBED_EXTRACT_FILENAME}" ]]; then
	echo "ERROR: gibbedRedToolsDir '${gibbedRedToolsDir}' does not contain ${GIBBED_EXTRACT_FILENAME}.";
	exit;
fi
#echo '';
#echo "gibbedRedToolsDir: '${gibbedRedToolsDir}' ";

dzipFilesDir="$1";
if [[ -n "${dzipFilesDir}" ]]; then
	# convert any bad input to posix path
	dzipFilesDir="$(alwaysUsePosixPaths "${dzipFilesDir}")";

	if [[ ! -d "${dzipFilesDir}" ]]; then
		echo "ERROR: dzipFilesDir '${dzipFilesDir}' not found.";
		exit;
	else
		dzipCount=$(find "${dzipFilesDir}" -type f -iname '*.dzip'|wc -l);
		if [[ '0' == "${dzipCount}" ]]; then
			echo "ERROR: dzipFilesDir '${dzipFilesDir}' does not contain any dzip files.";
			exit;
		fi
	fi
fi

echo '';
if [[ -z "${dzipFilesDir}" ]]; then
	promptText='Please enter the FOLDER path containing your dzip files such as CookedPC or a Mod folder';
	if [[ 'true' == "${isWindows}" ]]; then
		promptText='${promptText}\n(Note: ALL Windows paths must be enclosed within quotes): ';
	fi
	while [[ -z "${dzipFilesDir}" ]]; do
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
				dzipCount=$(find "${typedPath}" -type f -iname '*.dzip'|wc -l);
				if [[ '0' == "${dzipCount}" ]]; then
					echo "ERROR: folder '${typedPath}' does not contain any dzip files.";
					echo "Please try again or press Ctrl+C to abort.";
				else
					dzipFilesDir="${typedPath}";
				fi
			fi
		fi
	done
fi
#echo '';
#echo "dzipFilesDir: '${dzipFilesDir}' ";

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
			if [[ "${typedPath}" == "${dzipFilesDir}" ]]; then
				echo "ERROR: The outputDir '${typedPath}' cannot be the same folder as dzipFilesDir.";
				echo "Please try again or press Ctrl+C to abort.";
				continue;
			fi

			if [[ "$(realpath "${typedPath}")" == "$(realpath "${dzipFilesDir}")" ]]; then
				echo "ERROR: The outputDir '${typedPath}' cannot point to the same location as dzipFilesDir.";
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


if [[ -z "${dzipFilesDir}" ]]; then
	echo 'ERROR: dzipFilesDir undefined.';
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
echo "dzipFilesDir: '${dzipFilesDir}' ";
echo  "outputDir: '${outputDir}' ...";
echo '==============================================================================';

# 2. Extract dzips

# setup wine paths: when we pass the paths to wine, we want the windows app to use
# to use a format like "C:/temp/output"
#
wineToolsDir='';
wineDzipDir='';
wineOutputDir='';
if [[ 'false' == "${isWindows}" ]]; then
	echo "Checking symlinks...";

	mkdir -p "${witcher2ProtonPrefix}/drive_c/temp" 2>/dev/null;
	if [[ ! -d "${witcher2ProtonPrefix}/drive_c/temp" ]]; then
		echo "ERROR: Faild to create temp directory at '${witcher2ProtonPrefix}/drive_c/temp'.";
		exit;
	fi

	if [[ "${gibbedRedToolsDir}" != "${witcher2ProtonPrefix}/drive_c/temp/Gibbed-RED-Tools" ]]; then
		if [[ -L "${witcher2ProtonPrefix}/drive_c/temp/Gibbed-RED-Tools" ]]; then
			rm "${witcher2ProtonPrefix}/drive_c/temp/Gibbed-RED-Tools" 2>/dev/null;
		fi
		ln -sf "${gibbedRedToolsDir}" "${witcher2ProtonPrefix}/drive_c/temp/Gibbed-RED-Tools";
	fi
	wineToolsDir="C:/temp/Gibbed-RED-Tools";

	if [[ "${dzipFilesDir}" != "${witcher2ProtonPrefix}/drive_c/temp/dzips" ]]; then
		if [[ -L "${witcher2ProtonPrefix}/drive_c/temp/dzips" ]]; then
			rm "${witcher2ProtonPrefix}/drive_c/temp/dzips" 2>/dev/null;
		fi
		ln -sf "${dzipFilesDir}" "${witcher2ProtonPrefix}/drive_c/temp/dzips";
	fi
	wineDzipDir="C:/temp/dzips";

	if [[ "${outputDir}" != "${witcher2ProtonPrefix}/drive_c/temp/output" ]]; then
		if [[ -L "${witcher2ProtonPrefix}/drive_c/temp/output" ]]; then
			rm "${witcher2ProtonPrefix}/drive_c/temp/output" 2>/dev/null;
		fi
		ln -sf "${outputDir}" "${witcher2ProtonPrefix}/drive_c/temp/output";
	fi
	wineOutputDir="C:/temp/output";
else
	# windows
	wineToolsDir="${gibbedRedToolsDir}";
	wineDzipDir="${dzipFilesDir}";
	wineOutputDir="${outputDir}";
fi
#echo "wineToolsDir: ${wineToolsDir}";
#echo "wineDzipDir: ${wineDzipDir}";
#echo "wineOutputDir: ${wineOutputDir}";


startDir=$(pwd);

# Change to dzipFilesDir so that we can use "find ." to make the paths all relative
cd "${dzipFilesDir}";

modePrefix='';
if [[ "true" == "${SIMULATE_ONLY}" ]]; then
	modePrefix="echo";
fi

while IFS= read -r -d '' relativeFilePath; do
	#echo "relativeFilePath: ${relativeFilePath}";
	if [[ "" == "${relativeFilePath}" ]]; then
		continue;
	fi
	echo '';

	# set file path to be passed to windows app
	wineFilePath="${wineDzipDir}${relativeFilePath:1}"
	#echo "wineFilePath: ${wineFilePath}";

	# set output dir to be passed to windows app
	relativeOutputPath="${relativeFilePath:1}";
	relativeOutputPath="${relativeOutputPath%.*}";

	actualOutputPath="${outputDir}${relativeOutputPath}";
	wineOutputPath="${wineOutputDir}${relativeOutputPath}";
	#echo "actualOutputPath: ${actualOutputPath}";
	#echo "wineOutputPath: ${wineOutputPath}";

	# make sure output dir exists
	${modePrefix} mkdir -p "${actualOutputPath}" 2>/dev/null;

	fileSize=''
	if [[ 'false' == "${isWindows}" ]]; then
		fileSize="$(du -hs "${relativeFilePath}"|sed -E 's/^(\S+)\s+.*$/\1/g')";
	fi
	echo "Extracting ${relativeFilePath} [${fileSize}] ...";
	if [[ '1' == "$(echo "${fileSize}"|grep -Pc '^([.\d]+G|\d{3,}M)$')" ]]; then
		echo "Note: This file is larger and may take awhile to process. Please be patient.";
	fi

	# invoke windows app to extract dzip files
	if [[ 'false' == "${isWindows}" ]]; then
		# Note: WINEDEBUG=-all is to get rid of wine debug messages/warnings such as "fixme" that just create console noise
		runOrSimulate /usr/bin/env WINEDEBUG=-all WINEPREFIX="${witcher2ProtonPrefix}" "${protonWineBinPath}" "${wineToolsDir}/${GIBBED_EXTRACT_FILENAME}" "${wineFilePath}" "${wineOutputPath}";
	else
		runOrSimulate "${wineToolsDir}/${GIBBED_EXTRACT_FILENAME}" "${wineFilePath}" "${wineOutputPath}";
	fi

done < <(find . -iname '*.dzip' -print0)

# restore startDir
cd "${startDir}";
