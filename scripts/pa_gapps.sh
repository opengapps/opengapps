#!/bin/sh
#This file is part of The PA GApps script of @mfonville.
#
#    The PA GApps scripts are free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    These scripts are distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#

#Check architecture
if { [ "x$1" != "xarm" ] && [ "x$1" != "xarm64" ] && [ "x$1" != "xx86" ]; } || [ "x$2" = "x" ]; then
	echo "Usage: $0 (arm|arm64|x86) API_LEVEL"
	exit 1
fi
DATE=$(date +"%Y%m%d")
TOP=$(realpath .)
ARCH=$1
API=$2
BUILD=$TOP/build
OUT=$TOP/out
SOURCE=$TOP/sources
SCRIPTS=$TOP/scripts

#Calculate platform version
if [ "$API" = "19" ]; then
	PLATFORM="4.4"
elif [ "$API" = "21" ]; then
	PLATFORM="5.0"
elif [ "$API" = "22" ]; then
	PLATFORM="5.1"
else
	echo "ERROR: Unknown API version! Aborting..."
	exit 1
fi

build="$BUILD/$ARCH/$API/"
unsignedzip="$BUILD/$ARCH/$API.zip"
signedzip="$OUT/pa_gapps-$ARCH-$PLATFORM-$DATE.zip"
install -d $build

#####---------CHECK FOR EXISTANCE OF SOME BINARIES---------
command -v install >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but it's not installed.  Aborting." >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "zip is required but it's not installed.  Aborting." >&2; exit 1; }
command -v zipalign >/dev/null 2>&1 || { echo "zipalign is required but it's not installed.  Aborting." >&2; exit 1; }

copy() {
	if [ -d "$1" ]
	then
		for f in $1/*; do
			copy $f "$2/$(basename $f)"
		done
	fi
	if [ -f "$1" ]
	then
  		install -D -p $1 $2
	fi
}
buildfile() {
	#buildfile needs slashes when used, unlike the buildapp
	targetdir=$build$2
	install -d $targetdir
	if [ -f "$SOURCE/$ARCH/$1" ]
	then
		copy "$SOURCE/$ARCH/$1" $targetdir #if we have a file specific to this architecture
	else
		copy "$SOURCE/all/$1" $targetdir #use common file
	fi
}
buildapp() {
	#package $1
	#targetlocation $2
	#unfortunately no getapi here, as long as GMSCore and PlayGames call the subfunctions individually
	buildapk $1 $2
	buildlib $1 $2
}
getapi() {
	#loop over all source-instances and find the highest available acceptable api level
	sourcearch=""
	sourceall=""
	if stat --printf='' $SOURCE/$ARCH/*app/$1 2>/dev/null
	then
		sourcearch="find $SOURCE/$ARCH/*app/$1 -iname '*.apk'"
		sourceall=" & " #glue
	fi
	if stat --printf='' $SOURCE/all/*app/$1 2>/dev/null
	then
		sourceall="$sourceall""find $SOURCE/all/*app/$1 -iname '*.apk'"
	else
		sourceall="" #undo glue
	fi
	if [ "$sourcearch" = "" ] && [ "$sourceall" = "" ]
	then
		echo "ERROR: Package $1 has neither an APK source on $ARCH as all"
		exit 1
	fi
	#sed copies filename to the beginning, to compare version, and later we remove it with cut
	for sourceapk in `{ eval "$sourcearch$sourceall"; }\
			| sed 's!.*/\(.*\)!\1/&!'\
			| sort -r -t/ -k1,1\
			| cut -d/ -f2-`; do
		api=$(basename $(dirname $sourceapk))
		if [ "$api" -le "$API" ]
		then
			break
		fi
		echo "ERROR: No APK found compatible with API level $API for package $1 on $ARCH, lowest found: $api"
		exit 1
	done
	#we will use $sourceapk as returnvalue
}
buildapk() {
	getapi $1
	targetdir=$build$2
	targetapk="$targetdir/$(basename $targetdir).apk"
	if [ -f "$targetapk" ]
		then
		rm "$targetapk"
	fi
	install -d $targetdir
	zip -q -U $sourceapk -O "$targetapk" --exclude lib* ##not sure
}
buildlib() {
	getapi $1
	targetdir=$build$2
	targetapk="$targetdir/$(basename $targetdir).apk"
	if [ "x`unzip -qql $sourceapk lib* | head -n1 | tr -s ' ' | cut -d' ' -f5-`" != "x" ]
		then
		install -d $targetdir/lib/arm
		unzip -q -j -o $sourceapk -d $targetdir/lib/arm lib*
	fi
}

#THE NEXT CHAPTER WE WILL LATER SPLIT OUT PER DIFFERENT TYPE OF PACKAGE

#####---------FIRST THE SPECIAL CASES---------
#GMSCore
buildapk "com.google.android.gms.0" "GMSCore/0/priv-app/PrebuiltGmsCore"
#buildapk "com.google.android.gms.2" "GMSCore/4/priv-app/PrebuiltGmsCore" #not available
buildapk "com.google.android.gms.4" "GMSCore/4/priv-app/PrebuiltGmsCore"
buildapk "com.google.android.gms.6" "GMSCore/6/priv-app/PrebuiltGmsCore"
buildapk "com.google.android.gms.8" "GMSCore/8/priv-app/PrebuiltGmsCore"
buildlib "com.google.android.gms.0" "GMSCore/common/priv-app/PrebuiltGmsCore"

#PlayGames
buildapk "com.google.android.play.games.0" "PlayGames/0/app/PlayGames"
buildapk "com.google.android.play.games.2" "PlayGames/2/app/PlayGames"
buildapk "com.google.android.play.games.4" "PlayGames/4/app/PlayGames"
buildapk "com.google.android.play.games.6" "PlayGames/6/app/PlayGames"
buildapk "com.google.android.play.games.8" "PlayGames/8/app/PlayGames"
buildlib "com.google.android.play.games.0" "PlayGames/common/app/PlayGames"

#Keyboard Lib
buildfile "lib/libjni_latinimegoogle.so" "Optional/keybd_lib/lib/"
#####---------CORE APPLICATIONS---------
buildfile "etc/" "Core/required/etc/"
buildfile "framework" "Core/required/framework/"
buildapp "com.google.android.syncadapters.contacts" "Core/required/app/GoogleContactsSyncAdapter"
buildapp "com.google.android.backuptransport" "Core/required/priv-app/GoogleBackupTransport"
buildapp "com.google.android.feedback" "Core/required/priv-app/GoogleFeedback"
buildapp "com.google.android.gsf" "Core/required/priv-app/GoogleServicesFramework"
buildapp "com.google.android.gsf.login" "Core/required/priv-app/GoogleLoginService"
buildapp "com.google.android.onetimeinitializer" "Core/required/priv-app/GoogleOneTimeInitializer"
buildapp "com.google.android.partnersetup" "Core/required/priv-app/GooglePartnerSetup"
buildapp "com.google.android.setupwizard" "Core/required/priv-app/SetupWizard"
buildapp "com.android.vending" "Core/required/priv-app/Phonesky"

#####---------GENERIC PACKAGES---------
buildapp "com.google.android.apps.books" "GApps/books/app/Books"
buildapp "com.google.android.calendar" "GApps/calendargoogle/app/CalendarGooglePrebuilt"
buildapp "com.google.android.syncadapters.calendar" "GApps/calsync/app/GoogleCalendarSyncAdapter"
buildapp "com.google.android.googlecamera" "GApps/cameragoogle/app/GoogleCamera"
buildapp "com.android.chrome" "GApps/chrome/app/Chrome"
buildapp "com.google.android.apps.cloudprint" "GApps/cloudprint/app/CloudPrint2"
buildapp "com.google.android.apps.docs.editors.docs" "GApps/docs/app/EditorsDocs"
buildapp "com.google.android.apps.docs" "GApps/drive/app/Drive"
buildapp "com.google.android.ears" "GApps/ears/app/GoogleEars"
buildapp "com.google.earth" "GApps/earth/app/GoogleEarth"
buildapp "com.google.android.gm.exchange" "GApps/exchangegoogle/app/PrebuiltExchange3Google"
#FaceLock with libs
buildfile "lib/libfacelock_jni.so" "GApps/faceunlock/lib/"
buildfile "vendor/pittpatt/" "GApps/faceunlock/vendor/pittpatt/"
buildapp "com.android.facelock" "GApps/faceunlock/app/FaceLock/"
#End of FaceLock
buildapp "com.google.android.gm" "GApps/gmail/app/PrebuiltGmail"
buildapp "com.google.android.launcher" "GApps/googlenow/priv-app/GoogleHome"
buildapp "com.google.android.apps.plus" "GApps/googleplus/app/PlusOne"
buildapp "com.google.android.tts" "GApps/googletts/app/GoogleTTS"
buildapp "com.google.android.talk" "GApps/hangouts/priv-app/Hangouts"
buildapp "com.google.android.keep" "GApps/keep/app/PrebuiltKeep"
buildapp "com.google.android.inputmethod.latin" "GApps/keyboardgoogle/app/LatinImeGoogle"
buildapp "com.google.android.apps.maps" "GApps/maps/app/Maps"
buildapp "com.google.android.apps.messaging" "GApps/messenger/app/PrebuiltBugle"
buildapp "com.google.android.videos" "GApps/movies/app/Videos"
buildapp "com.google.android.music" "GApps/music/app/Music2"
buildapp "com.google.android.apps.magazines" "GApps/newsstand/app/Newsstand"
buildapp "com.google.android.apps.genie.geniewidget" "GApps/newswidget/app/PrebuiltNewsWeather"
buildapp "com.google.android.googlequicksearchbox" "GApps/search/priv-app/Velvet"
buildapp "com.google.android.apps.docs.editors.sheets" "GApps/sheets/app/EditorsSheets"
buildapp "com.google.android.apps.docs.editors.slides" "GApps/slides/app/EditorsSlides"
#Speech
buildfile "usr/srec/" "GApps/speech/usr/srec/"
#End of Speech
buildapp "com.google.android.street" "GApps/street/app/Street"
buildapp "com.google.android.marvin.talkback" "GApps/talkback/app/talkback"
buildapp "com.google.android.apps.walletnfcrel" "GApps/wallet/priv-app/Wallet"
buildapp "com.google.android.youtube" "GApps/youtube/app/YouTube"
#####---------ALIGN THE APKS---------
for f in `find $build -name '*.apk'`; do
        mv $f $f.orig
        zipalign 4 $f.orig $f
        rm $f.orig
done

#####---------MAKE THE SCRIPTS---------
makegprop(){
echo "# begin addon properties
ro.addon.type=gapps
ro.addon.platform="$(echo $PLATFORM | tr -d ".")"
ro.addon.pa_type=stock
ro.addon.pa_version="$DATE"
# end addon properties" > "$build"g.prop
}
makesizesprop(){
echo "books_size="`du -s --apparent-size "$build"GApps/books | cut -f 1` > "$build"sizes.prop
echo "calendargoogle_size="`du -s --apparent-size "$build"GApps/calendargoogle | cut -f 1` >> "$build"sizes.prop
echo "calsync_size="`du -s --apparent-size "$build"GApps/calsync | cut -f 1` >> "$build"sizes.prop
echo "cameragoogle_size="`du -s --apparent-size "$build"GApps/cameragoogle | cut -f 1` >> "$build"sizes.prop
echo "chrome_size="`du -s --apparent-size "$build"GApps/chrome | cut -f 1` >> "$build"sizes.prop
echo "cloudprint_size="`du -s --apparent-size "$build"GApps/cloudprint | cut -f 1` >> "$build"sizes.prop
echo "docs_size="`du -s --apparent-size "$build"GApps/docs | cut -f 1` >> "$build"sizes.prop
echo "drive_size="`du -s --apparent-size "$build"GApps/drive | cut -f 1` >> "$build"sizes.prop
echo "ears_size="`du -s --apparent-size "$build"GApps/ears | cut -f 1` >> "$build"sizes.prop
echo "earth_size="`du -s --apparent-size "$build"GApps/earth | cut -f 1` >> "$build"sizes.prop
echo "exchangegoogle_size="`du -s --apparent-size "$build"GApps/exchangegoogle | cut -f 1` >> "$build"sizes.prop
echo "faceunlock_size="`du -s --apparent-size "$build"GApps/faceunlock | cut -f 1` >> "$build"sizes.prop
echo "gmail_size="`du -s --apparent-size "$build"GApps/gmail | cut -f 1` >> "$build"sizes.prop
echo "googlenow_size="`du -s --apparent-size "$build"GApps/googlenow | cut -f 1` >> "$build"sizes.prop
echo "googleplus_size="`du -s --apparent-size "$build"GApps/googleplus | cut -f 1` >> "$build"sizes.prop
echo "googletts_size="`du -s --apparent-size "$build"GApps/googletts | cut -f 1` >> "$build"sizes.prop
echo "hangouts_size="`du -s --apparent-size "$build"GApps/hangouts | cut -f 1` >> "$build"sizes.prop
echo "keep_size="`du -s --apparent-size "$build"GApps/keep | cut -f 1` >> "$build"sizes.prop
echo "keyboardgoogle_size="`du -s --apparent-size "$build"GApps/keyboardgoogle | cut -f 1` >> "$build"sizes.prop
echo "maps_size="`du -s --apparent-size "$build"GApps/maps | cut -f 1` >> "$build"sizes.prop
echo "messenger_size="`du -s --apparent-size "$build"GApps/messenger | cut -f 1` >> "$build"sizes.prop
echo "movies_size="`du -s --apparent-size "$build"GApps/movies | cut -f 1` >> "$build"sizes.prop
echo "music_size="`du -s --apparent-size "$build"GApps/music | cut -f 1` >> "$build"sizes.prop
echo "newsstand_size="`du -s --apparent-size "$build"GApps/newsstand | cut -f 1` >> "$build"sizes.prop
echo "newswidget_size="`du -s --apparent-size "$build"GApps/newswidget | cut -f 1` >> "$build"sizes.prop
echo "search_size="`du -s --apparent-size "$build"GApps/search | cut -f 1` >> "$build"sizes.prop
echo "sheets_size="`du -s --apparent-size "$build"GApps/sheets | cut -f 1` >> "$build"sizes.prop
echo "slides_size="`du -s --apparent-size "$build"GApps/slides | cut -f 1` >> "$build"sizes.prop
echo "speech_size="`du -s --apparent-size "$build"GApps/speech | cut -f 1` >> "$build"sizes.prop
echo "street_size="`du -s --apparent-size "$build"GApps/street | cut -f 1` >> "$build"sizes.prop
echo "talkback_size="`du -s --apparent-size "$build"GApps/talkback | cut -f 1` >> "$build"sizes.prop
echo "wallet_size="`du -s --apparent-size "$build"GApps/wallet | cut -f 1` >> "$build"sizes.prop
echo "youtube_size="`du -s --apparent-size "$build"GApps/youtube | cut -f 1` >> "$build"sizes.prop
}
makeinstallerdata(){
echo "# Installation Data for PA Lollipop GApps Installer by @mfonville based on the work of @TKruzze
# Last Updated: "$DATE > "$build"installer.data
echo '# _____________________________________________________________________________________________________________________
#                                             Define Current Package Variables
# List of GApps packages that can be installed with this installer
pkg_names="pico nano micro mini full stock";

# Installer Name (32 chars Total, excluding "")
installer_name="PA Google Stock GApps "'$PLATFORM'" - ";

req_android_version="'$PLATFORM'";
keybd_lib_filename1="libjni_latinimegoogle.so";
keybd_lib_filename2="libjni_latinime.so";
FaceLock_lib_filename="libfacelock_jni.so";

# Google Play Services version sizes' >> "$build"installer.data
gms0=`du -s "$build"GMSCore/0 | cut -f 1`
#missing gms2
gms4=`du -s "$build"GMSCore/4 | cut -f 1`
gms6=`du -s "$build"GMSCore/6 | cut -f 1`
gms8=`du -s "$build"GMSCore/8 | cut -f 1`
gmscommon=`du -s "$build"GMSCore/common | cut -f 1`
echo "gms_0_size="`expr $gms0 + $gmscommon`"; gms_4_size="`expr $gms4 + $gmscommon`"; gms_6_size="`expr $gms6 + $gmscommon`"; gms_8_size="`expr $gms8 + $gmscommon`";

# Google Play Games version sizes" >> "$build"installer.data
pg0=`du -s "$build"PlayGames/0 | cut -f 1`
pg2=`du -s "$build"PlayGames/0 | cut -f 1`
pg4=`du -s "$build"PlayGames/4 | cut -f 1`
pg6=`du -s "$build"PlayGames/6 | cut -f 1`
pg8=`du -s "$build"PlayGames/8 | cut -f 1`
echo "pg_0_size="$pg0"; pg_2_size="$pg2"; pg_4_size="$pg4"; pg_6_size="$pg6"; pg_8_size="$pg8";

# Core & Optional Apps size" >> "$build"installer.data
core=`du -s "$build"Core | cut -f 1`
keybdlib=`du -s "$build"Optional/keybd_lib | cut -f 1`
echo "core_size="$core"; keybd_lib_size="$keybdlib";">> "$build"installer.data

tee >>"$build"installer.data <<'EOF'

# Buffer of extra system space to require for GApps install (9216=9MB)
# This will allow for some ROM size expansion when GApps are restored
buffer_size_kb=9216; small_buffer_size=2048;

# List of GApps files that should NOT be automatically removed as they are also included in (many) ROM's
removal_bypass_list="
";

# Define exit codes (returned upon exit due to an error)
E_ROMVER=20; # Wrong ROM version
E_NOSPACE=70; # Insufficient Space Available in System Partition
E_NONPA=40; # NON-PA GApps Currently Installed
E_64BIT=64 ; # 64-bit Device Detected
#_________________________________________________________________________________________________________________
#                                             GApps List (Applications user can Select/Deselect)
# calsync will be added to GApps Install List as needed during script execution
stock_gapps_list="
cameragoogle
keyboardgoogle
sheets
slides
";

full_gapps_list="
books
chrome
cloudprint
docs
drive
ears
earth
keep
messenger
movies
music
newsstand
newswidget
playgames
talkback
wallet
";

mini_gapps_list="
googleplus
hangouts
maps
street
youtube
";

micro_gapps_list="
calendargoogle
exchangegoogle
faceunlock
gmail
googlenow
googletts
";

nano_gapps_list="
search
speech
";

pico_gapps_list="
";
# _____________________________________________________________________________________________________________________
#                                             Default Stock/AOSP Removal List (Stock GApps Only)
default_aosp_remove_list="
browser
email
gallery
launcher
mms
picotts
";
# _____________________________________________________________________________________________________________________
#                                             Optional Stock/AOSP/ROM Removal List
optional_aosp_remove_list="
basicdreams
calendarstock
camerastock
cmaudiofx
cmaccount
cmeleven
cmfilemanager
cmupdater
cmwallpapers
exchangestock
fmradio
galaxy
holospiral
keyboardstock
livewallpapers
lockclock
noisefield
phasebeam
photophase
phototable
terminal
themes
simtoolkit
studio
sykopath
visualizationwallpapers
whisperpush
";
# _____________________________________________________________________________________________________________________
#                                             Stock/AOSP/ROM File Removal Lists
browser_list="
app/Browser
";

basicdreams_list="
app/BasicDreams
";

# Must be used when GoogleCalendar is installed
calendarstock_list="
app/Calendar
priv-app/Calendar
";

# Must be used when GoogleCamera is installed
camerastock_list="
app/Camera
app/Camera2
priv-app/Camera
priv-app/Camera2
";

cmaccount_list="
priv-app/CMAccount
";

cmaudiofx_list="
priv-app/AudioFX
";

cmeleven_list="
app/Eleven
";

cmfilemanager_list="
app/CMFileManager
";

cmupdater_list="
priv-app/CMUpdater
";

cmwallpapers_list="
app/CMWallpapers
";

email_list="
app/Email
";

exchangestock_list="
app/Exchange2
priv-app/Exchange2
";

fmradio_list="
app/FM2
app/FMRecord
";

galaxy_list="
app/Galaxy4
";

gallery_list="
app/Gallery
priv-app/Gallery
app/Gallery2
priv-app/Gallery2
";

holospiral_list="
app/HoloSpiralWallpaper
";

# Must be used when GoogleKeyboard is installed
keyboardstock_list="
app/LatinIME
";

launcher_list="
app/CMHome
app/CustomLauncher3
app/Launcher2
app/Launcher3
app/LiquidLauncher
app/Paclauncher
app/SlimLauncher
app/Trebuchet
priv-app/CMHome
priv-app/CustomLauncher3
priv-app/Launcher2
priv-app/Launcher3
priv-app/LiquidLauncher
priv-app/Paclauncher
priv-app/SlimLauncher
priv-app/Trebuchet
";

livewallpapers_list="
app/LiveWallpapers
";

lockclock_list="
app/LockClock
";

mms_list="
priv-app/Mms
";

noisefield_list="
app/NoiseField
";

phasebeam_list="
app/PhaseBeam
";

photophase_list="
app/PhotoPhase
";

phototable_list="
app/PhotoTable
";

picotts_list="
app/PicoTts
priv-app/PicoTts
lib/libttscompat.so
lib/libttspico.so
tts
";

simtoolkit_list="
app/Stk
";

studio_list="
app/VideoEditor
";

sykopath_list="
app/Layers
";

terminal_list="
app/Terminal
";

themes_list="
priv-app/ThemeChooser
priv-app/ThemesProvider
";

visualizationwallpapers_list="
app/VisualizationWallpapers
";

whisperpush_list="
app/WhisperPush
";
# _____________________________________________________________________________________________________________________
#                                             Permanently Removed Folders
# Pieces that may be left over from AIO ROM's that can/will interfere with these GApps
other_list="
/system/app/BrowserProviderProxy
/system/app/Gmail
/system/app/GoogleCalendar
/system/app/GoogleCloudPrint
/system/app/GoogleHangouts
/system/app/GoogleKeep
/system/app/GoogleLatinIme
/system/app/GooglePlus
/system/app/PartnerBookmarksProvider
/system/app/QuickSearchBox
/system/app/Vending
/system/priv-app/GmsCore
/system/priv-app/GoogleNow
/system/priv-app/GoogleSearch
/system/priv-app/GoogleHangouts
/system/priv-app/OneTimeInitializer
/system/priv-app/Provision
/system/priv-app/QuickSearchBox
/system/priv-app/Vending
";

# Apps from 'app' that need to be installed in 'priv-app'
privapp_list="
/system/app/GoogleBackupTransport
/system/app/GoogleFeedback
/system/app/GoogleLoginService
/system/app/GoogleOneTimeInitializer
/system/app/GooglePartnerSetup
/system/app/GoogleServicesFramework
/system/app/Hangouts
/system/app/OneTimeInitializer
/system/app/Phonesky
/system/app/PrebuiltGmsCore
/system/app/SetupWizard
/system/app/Velvet
/system/app/Wallet
";

# Stock/AOSP Keyboard lib (and symlink) that are always removed since they're always replaced 
reqd_list="
/system/lib/libjni_latinime.so
/system/lib/libjni_latinimegoogle.so
/system/app/LatinIME/lib/arm/libjni_latinime.so
/system/app/LatinIME/lib/arm/libjni_latinimegoogle.so
";

# Remove talkback from priv-app since it was moved to app in 5.1
obsolete_list="
/system/priv-app/talkback
#";

# Obsolete files from xxxx
#obsolete_list="${obsolete_list}
#";

# Old gaddon.d backup scripts as we'll be replacing with updated version during install
oldscript_list="
/system/etc/g.prop
/system/addon.d/70-gapps.sh
/system/addon.d/71-faceunlock.sh
/system/addon.d/72-keyboards.sh
/system/addon.d/74-googlecamera.sh
/system/addon.d/78-chromebrowser.sh
";

remove_list="${other_list}${privapp_list}${reqd_list}${obsolete_list}${oldscript_list}";
# _____________________________________________________________________________________________________________________
#                                             Installer Error Messages
64bit_compat_msg="INSTALLATION FAILURE: PA GApps are not compatible with 64-bit devices. You will\nneed to find a 64-bit compatible GApps package that will worok with your device.\n";
camera_sys_msg="WARNING: Google Camera has/will not be installed as requested. Google Camera\ncan only be installed during a Clean Install or as an update to an existing\nGApps Installation.\n";
camera_compat_msg="WARNING: Google Camera has/will not be installed as requested. Google Camera is\nNOT compatible with your device if installed in the system partition. Try\ninstalling from the Play Store instead.\n";
faceunlock_msg="NOTE: FaceUnlock can only be installed on devices with a front facing camera.\n";
googlenow_msg="WARNING: Google Now Launcher has/will not be installed as requested. Google \nSearch must be added to the GApps installation if you want to install the Google\nNow Launcher.\n";
keyboard_sys_msg="WARNING: Google Keyboard has/will not be installed as requested. Google Keyboard\ncan only be installed during a Clean Install or as an update to an existing\nGApps Installation.\n";
nokeyboard_msg="NOTE: The Stock/AOSP keyboard was NOT removed as requested to ensure your device\nwas not accidentally left with no keyboard installed. If this was intentional,\nyou can add 'Override' to your gapps-config to override this protection.\n";
nolauncher_msg="NOTE: The Stock/AOSP Launcher was NOT removed as requested to ensure your device\nwas not accidentally left with no Launcher. If this was your intention, you can\nadd 'Override' to your gapps-config to override this protection.\n";
nomms_msg="NOTE: The Stock/AOSP MMS app was NOT removed as requested to ensure your device\nwas not accidentally left with no way to receive text messages. If this WAS\nintentional, add 'Override' to your gapps-config to override this protection.\n";
non_pa_gapps_msg="INSTALLATION FAILURE: PA GApps can only be installed on top of an existing\nPA GApps installation. Since you are currently using another GApps package, you\nwill need to wipe (format) your system partition before installing PA GApps.\n";
rom_version_msg="INSTALLATION FAILURE: This GApps package can only be installed on a $req_android_version.x ROM.\n";
simulation_msg="TEST INSTALL: This was only a simulated install. NO CHANGES WERE MADE TO YOUR\nDEVICE. To complete the installation remove 'Test' from your gapps-config.\n";
system_space_msg="INSTALLATION FAILURE: Your device does not have sufficient space available in\nthe system partition to install this GApps package as currently configured.\nYou will need to switch to a smaller GApps package or use gapps-config to\nreduce the installed size.\n";
del_conflict_msg="!!! WARNING !!! - Duplicate files were noted between your ROM and this GApps\npackage. The duplicate files are shown in the log portion below. Please report\nthis information to the PA GApps developers on GitHub or XDA Forums.\n";
EOF
}

copy "$SCRIPTS/bkup_tail.sh" $build
copy "$SCRIPTS/gapps-remove.txt" $build
makegprop
makesizesprop
makeinstallerdata
install -d "$build"META-INF/com/google/android
echo "# Dummy file; update-binary is a shell script.">"$build"META-INF/com/google/android/updater-script
copy "$SCRIPTS/update-binary" "$build"META-INF/com/google/android/

if [ -f "$unsignedzip" ]
then
	rm "$unsignedzip"
fi
cd $build
zip -q -r -D -X -9 $unsignedzip Core GApps GMSCore Optional PlayGames META-INF bkup_tail.sh g.prop gapps-remove.txt installer.data sizes.prop

install -d $OUT
if [ -f "$signedzip" ]
then
	rm $signedzip
fi

cd $SCRIPTS
./signapk.sh sign $unsignedzip $signedzip
if [ $? -eq 0 ]; then #if signing did succeed
    rm $unsignedzip
else
	echo "ERROR: Creating Flashable ZIP-file failed"
	cd $TOP
	exit 1
fi
cd $TOP
echo "SUCCESS: Built PA GApps with API $API level for $ARCH as $signedzip"
