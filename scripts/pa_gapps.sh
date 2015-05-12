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

#Calculate platform version
if [ "$API" = "19" ]; then
	PLATFORM="4.4"
elif [ "$API" = "21" ]; then
	PLATFORM="5.0"
elif [ "$API" = "22" ]; then
	PLATFORM="5.1"
else
	echo "Unknown API version! Aborting..."
	exit 1
fi

build="$BUILD/$ARCH/$API/"
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
	copy "$SOURCE/$ARCH/$1" $targetdir
}
buildapp() {
	#package $1
	#targetlocation $2
	buildapk $1 $2
	buildlib $1 $2
}
buildapk() {
	source=`find $SOURCE/$ARCH/*app/$1 -iname '*' | sort -r | head -1`
	targetdir=$build$2
	targetapk="$targetdir/$(basename $targetdir).apk"
	if [ -f "$targetapk" ]
		then
		rm "$targetapk"
	fi
	install -d $targetdir
	zip -q -U $source -O "$targetapk" --exclude lib* ##not sure
}
buildlib() {
	source=`find $SOURCE/$ARCH/*app/$1 -iname '*' | sort -r | head -1`
	targetdir=$build$2
	targetapk="$targetdir/$(basename $targetdir).apk"
	if [ "x`unzip -qql $source lib* | head -n1 | tr -s ' ' | cut -d' ' -f5-`" != "x" ]
		then
		install -d $targetdir/lib/arm
		unzip -q -j -o $source -d $targetdir/lib/arm lib*
	fi
}

#####---------FIRST THE SPECIAL CASES---------
#GMSCore
buildapk "com.google.android.gms.0" "GMSCore/0/priv-app/PrebuiltGmsCore"
buildapk "com.google.android.gms.4" "GMSCore/4/priv-app/PrebuiltGmsCore"
buildapk "com.google.android.gms.6" "GMSCore/6/priv-app/PrebuiltGmsCore"
buildapk "com.google.android.gms.8" "GMSCore/8/priv-app/PrebuiltGmsCore"
buildlib "com.google.android.gms.0" "GMSCore/common/priv-app/PrebuiltGmsCore"

#PlayGames
buildapp "com.google.android.play.games.0" "PlayGames/0/app/PlayGames"
buildapp "com.google.android.play.games.4" "PlayGames/4/app/PlayGames"
buildapp "com.google.android.play.games.6" "PlayGames/6/app/PlayGames"
buildapp "com.google.android.play.games.8" "PlayGames/8/app/PlayGames"

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
buildapp "com.google.android.launcher" "GApps/googlenow/app/GoogleHome"
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

