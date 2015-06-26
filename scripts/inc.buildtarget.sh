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
buildtarget() {
clean
#####---------CORE APPLICATIONS---------
#special case:
builddpiapp "com.google.android.gms" "GMSCore" "priv-app/PrebuiltGmsCore"
#only on lollipop extra gestures for AOSP keyboard:
if [ "$API" -gt "19" ]; then
	#Keyboard Lib
	buildfile "$LIBFOLDER/libjni_latinimegoogle.so" "Optional/keybd_lib/$LIBFOLDER/"
fi
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
for app in $gapps; do
	case $app in
		books)	 	buildapp "com.google.android.apps.books" "GApps/books/app/Books";;
		calendargoogle)	buildapp "com.google.android.calendar" "GApps/calendargoogle/app/CalendarGooglePrebuilt";;
		calsync)	buildapp "com.google.android.syncadapters.calendar" "GApps/calsync/app/GoogleCalendarSyncAdapter";;
		cameragoogle)	if [ "$FALLBACKARCH" = "arm" ]; then #this covers both arm and arm64
					buildapp "com.google.android.googlecamera" "GApps/cameragoogle/app/GoogleCamera"
				fi;;
		chrome)		buildapp "com.android.chrome" "GApps/chrome/app/Chrome";;
		clockgoogle)	buildapp "com.google.android.deskclock" "GApps/clockgoogle/app/DeskClockGoogle";;
		cloudprint)	buildapp "com.google.android.apps.cloudprint" "GApps/cloudprint/app/CloudPrint2";;
		docs)		buildapp "com.google.android.apps.docs.editors.docs" "GApps/docs/app/EditorsDocs";;
		drive)		buildapp "com.google.android.apps.docs" "GApps/drive/app/Drive";;
		ears)		if [ "$FALLBACKARCH" = "arm" ]; then #this covers both arm and arm64
					buildapp "com.google.android.ears" "GApps/ears/app/GoogleEars"
				fi;;
		earth)		buildapp "com.google.earth" "GApps/earth/app/GoogleEarth";;
		exchangegoogle)	buildapp "com.google.android.gm.exchange" "GApps/exchangegoogle/app/PrebuiltExchange3Google";;
		faceunlock)	buildfile "$LIBFOLDER/libfacelock_jni.so" "GApps/faceunlock/$LIBFOLDER/"
				buildfile "$LIBFOLDER/libfilterpack_facedetect.so" "GApps/faceunlock/$LIBFOLDER/"
				if [ "$FALLBACKARCH" != "$ARCH" ]; then #on 64 bit, we also need the 32 bit file
					buildfile "lib/libfilterpack_facedetect.so" "GApps/faceunlock/lib/"
				fi
				buildfile "vendor/pittpatt/" "GApps/faceunlock/vendor/pittpatt/"
				buildapp "com.android.facelock" "GApps/faceunlock/app/FaceLock";;
		fitness)	buildapp "com.google.android.apps.fitness" "GApps/fitness/app/FitnessPrebuilt";;
		gmail)		buildapp "com.google.android.gm" "GApps/gmail/app/PrebuiltGmail";;
		googlenow)	buildapp "com.google.android.launcher" "GApps/googlenow/priv-app/GoogleHome";; #moves in android M to /app/
		photos)		buildapp "com.google.android.apps.photos" "GApps/photos/app/Photos";;
		googleplus)	buildapp "com.google.android.apps.plus" "GApps/googleplus/app/PlusOne";;
		googletts)	buildapp "com.google.android.tts" "GApps/googletts/app/GoogleTTS";;
		hangouts)	buildapp "com.google.android.talk" "GApps/hangouts/priv-app/Hangouts";;
		keep)		buildapp "com.google.android.keep" "GApps/keep/app/PrebuiltKeep";;
		keyboardgoogle)	buildapp "com.google.android.inputmethod.latin" "GApps/keyboardgoogle/app/LatinImeGoogle";;
		maps)		buildapp "com.google.android.apps.maps" "GApps/maps/app/Maps";;
#special case:
		messenger) 	builddpiapp "com.google.android.apps.messaging" "Messenger" "app/PrebuiltBugle";;
		movies)		buildapp "com.google.android.videos" "GApps/movies/app/Videos";;
		music)		buildapp "com.google.android.music" "GApps/music/app/Music2";;
		newsstand)	buildapp "com.google.android.apps.magazines" "GApps/newsstand/app/Newsstand";;
		newswidget)	buildapp "com.google.android.apps.genie.geniewidget" "GApps/newswidget/app/PrebuiltNewsWeather";;
#special case:
		playgames) 	builddpiapp "com.google.android.play.games" "PlayGames" "app/PlayGames";;
		search)		buildapp "com.google.android.googlequicksearchbox" "GApps/search/priv-app/Velvet";;
		sheets)		buildapp "com.google.android.apps.docs.editors.sheets" "GApps/sheets/app/EditorsSheets";;
		slides)		buildapp "com.google.android.apps.docs.editors.slides" "GApps/slides/app/EditorsSlides";;
		speech)		buildfile "usr/srec/" "GApps/speech/usr/srec/";;
		street)		buildapp "com.google.android.street" "GApps/street/app/Street";;
		talkback)	buildapp "com.google.android.marvin.talkback" "GApps/talkback/app/talkback";;
		wallet)		if [ "$FALLBACKARCH" = "arm" ]; then #this covers both arm and arm64
					buildapp "com.google.android.apps.walletnfcrel" "GApps/wallet/priv-app/Wallet"
				fi;;
		webviewgoogle)	buildapp "com.google.android.webview" "GApps/webviewgoogle/app/WebViewGoogle";;
		youtube)	buildapp "com.google.android.youtube" "GApps/youtube/app/YouTube";;
		*) 		echo "ERROR! Missing build rule for application with keyword $app";exit 1;;
	esac
done
}
