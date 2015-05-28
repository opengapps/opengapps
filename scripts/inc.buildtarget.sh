#This file is part of The Open GApps script of @mfonville.
#
#    The Open GApps scripts are free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    These scripts are distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#


#THE NEXT CHAPTER WE WILL LATER SPLIT OUT PER DIFFERENT TYPE OF PACKAGE
buildtarget() {
clean
#####---------FIRST THE SPECIAL CASES---------
#GMSCore
getversion "com.google.android.gms.0" #universal DPI version is our benchmark
gmsversion="$getversion"
gmstargets=""
for v in $DENSITIES; do
	if comparebaseversion "$gmsversion" "com.google.android.gms.$v"
	then
		gmstargets="$gmstargets $v"
		#the value of $sourceapk has been changed for us by calling the comparebaseversion
		buildapk "com.google.android.gms.$v" "GMSCore/$v/priv-app/PrebuiltGmsCore"
	fi
done
buildapk "com.google.android.gms.0" "GMSCore/0/priv-app/PrebuiltGmsCore"
buildlib "com.google.android.gms.0" "GMSCore/common/priv-app/PrebuiltGmsCore"
echo "Found Google Play Services variants:$gmstargets of universal version $gmsversion"

#Messenger
getversion "com.google.android.apps.messaging.0" #universal DPI version is our benchmark
msgversion=$getversion
msgtargets=""
for v in $DENSITIES; do
	if comparebaseversion $msgversion "com.google.android.apps.messaging.$v"
	then
		msgtargets="$msgtargets $v"
		#the value of $sourceapk has been changed for us by calling the comparebaseversion
		buildapk "com.google.android.apps.messaging.$v" "Messenger/$v/app/PrebuiltBugle"
	fi
done
buildapk "com.google.android.apps.messaging.0" "Messenger/0/app/PrebuiltBugle"
buildlib "com.google.android.apps.messaging.0" "Messenger/common/app/PrebuiltBugle"
echo "Found Google Messenger variants:$msgtargets of universal version $msgversion"

#PlayGames
getversion "com.google.android.play.games.0" #universal DPI version is our benchmark
pgversion=$getversion
pgtargets=""
for v in $DENSITIES; do
	if comparebaseversion $pgversion "com.google.android.play.games.$v"
	then
		pgtargets="$pgtargets $v"
		#the value of $sourceapk has been changed for us by calling the comparebaseversion
		buildapk "com.google.android.play.games.$v" "PlayGames/$v/app/PlayGames"
	fi
done
buildapk "com.google.android.play.games.0" "PlayGames/0/app/PlayGames"
buildlib "com.google.android.play.games.0" "PlayGames/common/app/PlayGames"
echo "Found Google Play Games variants:$pgtargets of universal version $pgversion"

#Keyboard Lib
buildfile "lib/libjni_latinimegoogle.so" "Optional/keybd_lib/lib/"
#####---------CORE APPLICATIONS---------
buildfile "etc/" "Core/required/etc/"
buildfile "framework" "Core/required/framework/"
buildapp "com.google.android.syncadapters.contacts" "Core/required/app/GoogleContactsSyncAdapter"
buildapp "com.google.android.backuptransport" "Core/required/priv-app/GoogleBackupTransport"
buildapp "com.google.android.feedback" "Core/required/priv-app/GoogleFeedback"
buildapp "com.google.android.gsf" "Core/required/priv-app/GoogleServicesFramework"
if [ "$API" -gt "19" ]; then
	buildapp "com.google.android.gsf.login" "Core/required/priv-app/GoogleLoginService"
fi
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
}
