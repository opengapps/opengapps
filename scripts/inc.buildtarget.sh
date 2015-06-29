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
buildapp "com.google.android.gms" "Core/gms" "priv-app/PrebuiltGmsCore"
#only on lollipop extra gestures for AOSP keyboard:
if [ "$API" -gt "19" ]; then
	#Keyboard Lib
	buildfile "$LIBFOLDER/libjni_latinimegoogle.so" "Optional/keybd_lib/$LIBFOLDER/"
fi
buildfile "etc/" "Core/framework/common/etc/"
buildfile "framework" "Core/framework/common/framework/"
buildapp "com.google.android.syncadapters.contacts" "Core/contacts" "app/GoogleContactsSyncAdapter"
buildapp "com.google.android.backuptransport" "Core/backuptransport" "priv-app/GoogleBackupTransport"
buildapp "com.google.android.feedback" "Core/feedback" "priv-app/GoogleFeedback"
buildapp "com.google.android.gsf" "Core/gsf" "priv-app/GoogleServicesFramework"
buildapp "com.google.android.gsf.login" "Core/login" "priv-app/GoogleLoginService"
buildapp "com.google.android.onetimeinitializer" "Core/onetimeinitializer" "priv-app/GoogleOneTimeInitializer"
buildapp "com.google.android.partnersetup" "Core/partnersetup" "priv-app/GooglePartnerSetup"
buildapp "com.google.android.setupwizard" "Core/setupwizard" "priv-app/SetupWizard"
buildapp "com.android.vending" "Core/vending" "priv-app/Phonesky"

#####---------GENERIC PACKAGES---------
for app in $gapps; do
	case $app in
		books)	 	buildapp "com.google.android.apps.books" "GApps/$app" "app/Books";;
		calendargoogle)	buildapp "com.google.android.calendar" "GApps/$app" "app/CalendarGooglePrebuilt";;
		calsync)	buildapp "com.google.android.syncadapters.calendar" "GApps/$app" "app/GoogleCalendarSyncAdapter";;
		cameragoogle)	if [ "$FALLBACKARCH" = "arm" ]; then #this covers both arm and arm64
					buildapp "com.google.android.googlecamera" "GApps/$app" "app/GoogleCamera"
				fi;;
		chrome)		buildapp "com.android.chrome" "GApps/$app" "app/Chrome";;
		clockgoogle)	buildapp "com.google.android.deskclock" "GApps/$app" "app/DeskClockGoogle";;
		cloudprint)	buildapp "com.google.android.apps.cloudprint" "GApps/$app" "app/CloudPrint2";;
		docs)		buildapp "com.google.android.apps.docs.editors.docs" "GApps/$app" "app/EditorsDocs";;
		drive)		buildapp "com.google.android.apps.docs" "GApps/$app" "app/Drive";;
		ears)		if [ "$FALLBACKARCH" = "arm" ]; then #this covers both arm and arm64
					buildapp "com.google.android.ears" "GApps/$app" "app/GoogleEars"
				fi;;
		earth)		buildapp "com.google.earth" "GApps/$app" "app/GoogleEarth";;
		exchangegoogle)	buildapp "com.google.android.gm.exchange" "GApps/$app" "app/PrebuiltExchange3Google";;
		faceunlock)	buildfile "$LIBFOLDER/libfacelock_jni.so" "GApps/$app/common/$LIBFOLDER/"
				buildfile "$LIBFOLDER/libfilterpack_facedetect.so" "GApps/$app/common/$LIBFOLDER/"
				if [ "$FALLBACKARCH" != "$ARCH" ]; then #on 64 bit, we also need the 32 bit file
					buildfile "lib/libfilterpack_facedetect.so" "GApps/$app/common/lib/"
				fi
				buildfile "vendor/pittpatt/" "GApps/$app/common/vendor/pittpatt/"
				buildapp "com.android.facelock" "GApps/$app" "app/FaceLock";;
		fitness)	buildapp "com.google.android.apps.fitness" "GApps/$app" "app/FitnessPrebuilt";;
		gmail)		buildapp "com.google.android.gm" "GApps/$app" "app/PrebuiltGmail";;
		googlenow)	buildapp "com.google.android.launcher" "GApps/$app" "priv-app/GoogleHome";; #moves in android M to /app/
		photos)		buildapp "com.google.android.apps.photos" "GApps/$app" "app/Photos";;
		googleplus)	buildapp "com.google.android.apps.plus" "GApps/$app" "app/PlusOne";;
		googletts)	buildapp "com.google.android.tts" "GApps/$app" "app/GoogleTTS";;
		hangouts)	buildapp "com.google.android.talk" "GApps/$app" "priv-app/Hangouts";;
		keep)		buildapp "com.google.android.keep" "GApps/$app" "app/PrebuiltKeep";;
		keyboardgoogle)	buildapp "com.google.android.inputmethod.latin" "GApps/$app" "app/LatinImeGoogle";;
		maps)		buildapp "com.google.android.apps.maps" "GApps/$app" "app/Maps";;
		messenger) 	buildapp "com.google.android.apps.messaging" "GApps/$app" "app/PrebuiltBugle";;
		movies)		buildapp "com.google.android.videos" "GApps/$app" "app/Videos";;
		music)		buildapp "com.google.android.music" "GApps/$app" "app/Music2";;
		newsstand)	buildapp "com.google.android.apps.magazines" "GApps/$app" "app/Newsstand";;
		newswidget)	buildapp "com.google.android.apps.genie.geniewidget" "GApps/$app" "app/PrebuiltNewsWeather";;
		playgames) 	buildapp "com.google.android.play.games" "GApps/$app" "app/PlayGames";;
		search)		buildapp "com.google.android.googlequicksearchbox" "GApps/$app" "priv-app/Velvet";;
		sheets)		buildapp "com.google.android.apps.docs.editors.sheets" "GApps/$app" "app/EditorsSheets";;
		slides)		buildapp "com.google.android.apps.docs.editors.slides" "GApps/$app" "app/EditorsSlides";;
		speech)		buildfile "usr/srec/" "GApps/$app/common/usr/srec/";;
		street)		buildapp "com.google.android.street" "GApps/$app" "app/Street";;
		talkback)	buildapp "com.google.android.marvin.talkback" "GApps/$app" "app/talkback";;
		wallet)		if [ "$FALLBACKARCH" = "arm" ]; then #this covers both arm and arm64
					buildapp "com.google.android.apps.walletnfcrel" "GApps/$app" "priv-app/Wallet"
				fi;;
		webviewgoogle)	buildapp "com.google.android.webview" "GApps/$app" "app/WebViewGoogle";;
		youtube)	buildapp "com.google.android.youtube" "GApps/$app" "app/YouTube";;
		*) 		echo "ERROR! Missing build rule for application with keyword $app";exit 1;;
	esac
done
}
