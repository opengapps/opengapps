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
get_supported_variants(){
	case "$1" in
		stock|aroma|fornexus)	supported_variants="pico nano micro mini full stock";;
		full)	supported_variants="pico nano micro mini full";;
		mini)	supported_variants="pico nano micro mini";;
		micro)	supported_variants="pico nano micro";;
		nano)	supported_variants="pico nano";;
		pico)	supported_variants="pico";;
		*)	supported_variants="";;
	esac
}

get_gapps_list(){
	#Compile the list of applications that will have to be build for this variant
	gapps_list="$gappscore"
	for variant in $1; do
		eval "addtogapps=\$gapps$variant"
		gapps_list="$gapps_list $addtogapps"
	done
}

buildtarget() {
clean
for app in $gapps; do
	get_package_info $app
	if [ ! -z $packagename ]; then
		buildapp "$packagename" "$packagetype/$app" "$packagetarget"
	fi
	for file in $packagefiles; do
		buildfile "$packagetype/$app/common" "$file"
	done
done
}

#only on lollipop extra gestures for AOSP keyboard:
#if [ "$API" -gt "19" ]; then
#	#Keyboard Lib
#	buildfile "$LIBFOLDER/libjni_latinimegoogle.so" "Optional/keybd_lib/$LIBFOLDER/"
#fi

get_package_info(){
	packagename=""
	packagetype=""
	packagetarget=""
	packagefiles=""
	case "$1" in
		framework)					packagetype="Core"; packagefiles="etc framework";;
		gmscore)					packagename="com.google.android.gms"; packagetype="Core"; packagetarget="priv-app/PrebuiltGmsCore";;
		googlecontactssync)			packagename="com.google.android.syncadapters.contacts"; packagetype="Core"; packagetarget="app/GoogleContactsSyncAdapter";;
		googlebackuptransport)		packagename="com.google.android.backuptransport"; packagetype="Core"; packagetarget="priv-app/GoogleBackupTransport";;
		googlefeedback)				packagename="com.google.android.feedback"; packagetype="Core"; packagetarget="priv-app/GoogleFeedback";;
		gsfcore)					packagename="com.google.android.gsf"; packagetype="Core"; packagetarget="priv-app/GoogleServicesFramework";;
		gsflogin)					packagename="com.google.android.gsf.login"; packagetype="Core"; packagetarget="priv-app/GoogleLoginService";;
		googleonetimeinitializer)	packagename="com.google.android.onetimeinitializer"; packagetype="Core"; packagetarget="priv-app/GoogleOneTimeInitializer";;
		googlepartnersetup)			packagename="com.google.android.partnersetup"; packagetype="Core"; packagetarget="priv-app/GooglePartnerSetup";;
		setupwizard)				packagename="com.google.android.setupwizard"; packagetype="Core"; packagetarget="priv-app/SetupWizard";;
		vending)					packagename="com.android.vending"; packagetype="Core"; packagetarget="priv-app/Phonesky";;

		books)	 		packagename="com.google.android.apps.books"; packagetype="GApps"; packagetarget="app/Books";;
		calendargoogle)	packagename="com.google.android.calendar"; packagetype="GApps"; packagetarget="app/CalendarGooglePrebuilt";;
		calsync)		packagename="com.google.android.syncadapters.calendar"; packagetype="GApps"; packagetarget="app/GoogleCalendarSyncAdapter";;
		cameragoogle) 	if [ "$FALLBACKARCH" = "arm" ]; then #this covers both arm and arm64
							packagename="com.google.android.googlecamera"; packagetype="GApps"; packagetarget="app/GoogleCamera"
						fi;;
		chrome)			packagename="com.android.chrome"; packagetype="GApps"; packagetarget="app/Chrome";;
		clockgoogle)	packagename="com.google.android.deskclock"; packagetype="GApps"; packagetarget="app/DeskClockGoogle";;
		cloudprint)		packagename="com.google.android.apps.cloudprint"; packagetype="GApps"; packagetarget="app/CloudPrint2";;
		docs)			packagename="com.google.android.apps.docs.editors.docs"; packagetype="GApps"; packagetarget="app/EditorsDocs";;
		drive)			packagename="com.google.android.apps.docs"; packagetype="GApps"; packagetarget="app/Drive";;
		ears)			if [ "$FALLBACKARCH" = "arm" ]; then #this covers both arm and arm64
							packagename="com.google.android.ears"; packagetype="GApps"; packagetarget="app/GoogleEars"
						fi;;
		earth)			packagename="com.google.earth"; packagetype="GApps"; packagetarget="app/GoogleEarth";;
		exchangegoogle)	packagename="com.google.android.gm.exchange"; packagetype="GApps"; packagetarget="app/PrebuiltExchange3Google";;
		faceunlock)		packagename="com.android.facelock"; packagetype="GApps"; packagetarget="app/FaceLock";
						packagefiles="vendor/pittpatt/ $LIBFOLDER/libfacelock_jni.so $LIBFOLDER/libfilterpack_facedetect.so"
						if [ "$FALLBACKARCH" != "$ARCH" ]; then #on 64 bit, we also need the 32 bit file
							packagefiles="$packagefiles lib/libfilterpack_facedetect.so";
						fi;;
		fitness)		packagename="com.google.android.apps.fitness"; packagetype="GApps"; packagetarget="app/FitnessPrebuilt";;
		gmail)			packagename="com.google.android.gm"; packagetype="GApps"; packagetarget="app/PrebuiltGmail";;
		googlenow)		packagename="com.google.android.launcher"; packagetype="GApps"; packagetarget="priv-app/GoogleHome";; #moves in android M to /app/
		photos)			packagename="com.google.android.apps.photos"; packagetype="GApps"; packagetarget="app/Photos";;
		googleplus)		packagename="com.google.android.apps.plus"; packagetype="GApps"; packagetarget="app/PlusOne";;
		googletts)		packagename="com.google.android.tts"; packagetype="GApps"; packagetarget="app/GoogleTTS";;
		hangouts)		packagename="com.google.android.talk"; packagetype="GApps"; packagetarget="priv-app/Hangouts";;
		keep)			packagename="com.google.android.keep"; packagetype="GApps"; packagetarget="app/PrebuiltKeep";;
		keyboardgoogle)	packagename="com.google.android.inputmethod.latin"; packagetype="GApps"; packagetarget="app/LatinImeGoogle";;
		maps)			packagename="com.google.android.apps.maps"; packagetype="GApps"; packagetarget="app/Maps";;
		messenger)	 	packagename="com.google.android.apps.messaging"; packagetype="GApps"; packagetarget="app/PrebuiltBugle";;
		movies)			packagename="com.google.android.videos"; packagetype="GApps"; packagetarget="app/Videos";;
		music)			packagename="com.google.android.music"; packagetype="GApps"; packagetarget="app/Music2";;
		newsstand)		packagename="com.google.android.apps.magazines"; packagetype="GApps"; packagetarget="app/Newsstand";;
		newswidget)		packagename="com.google.android.apps.genie.geniewidget"; packagetype="GApps"; packagetarget="app/PrebuiltNewsWeather";;
		playgames) 		packagename="com.google.android.play.games"; packagetype="GApps"; packagetarget="app/PlayGames";;
		search)			packagename="com.google.android.googlequicksearchbox"; packagetype="GApps"; packagetarget="priv-app/Velvet";;
		sheets)			packagename="com.google.android.apps.docs.editors.sheets"; packagetype="GApps"; packagetarget="app/EditorsSheets";;
		slides)			packagename="com.google.android.apps.docs.editors.slides"; packagetype="GApps"; packagetarget="app/EditorsSlides";;
		speech)			packagetype="GApps"; packagefiles="usr/srec/";;
		street)			packagename="com.google.android.street"; packagetype="GApps"; packagetarget="app/Street";;
		talkback)		packagename="com.google.android.marvin.talkback"; packagetype="GApps"; packagetarget="app/talkback";;
		wallet)			if [ "$FALLBACKARCH" = "arm" ]; then #this covers both arm and arm64
							packagename="com.google.android.apps.walletnfcrel"; packagetype="GApps"; packagetarget="priv-app/Wallet"
						fi;;
		webviewgoogle)	packagename="com.google.android.webview"; packagetype="GApps"; packagetarget="app/WebViewGoogle";;
		youtube)		packagename="com.google.android.youtube"; packagetype="GApps"; packagetarget="app/YouTube";;
		*) 		echo "ERROR! Missing build rule for application with keyword $app";exit 1;;
	esac
}
