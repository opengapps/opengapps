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

# Static definitions, lists of packages per variant and in the core
# setupwizard is defined in in.compatibility.sh api19hack
gappscore="defaultetc
defaultframework
googlebackuptransport
googlecontactssync
googlefeedback
googleonetimeinitializer
googlepartnersetup
gmscore
gsfcore
vending"

gappscore_optional=""

gappssuper="dmagent
earth
gcs
googlepay
indic
japanese
korean
pinyin
projectfi
street
translate
zhuyin"

gappsstock="cameragoogle
duo
hangouts
keyboardgoogle
vrservice
wallpapers"

gappsstock_optional=""

gappsfull="books
chrome
cloudprint
docs
drive
fitness
googleplus
keep
movies
music
newsstand
newswidget
playgames
sheets
slides
talkback"

gappsfull_optional=""

gappsmini="clockgoogle
maps
messenger
photos
youtube"

gappsmini_optional=""

#googletts for micro is defined in inc.compatibility.sh api23hack
gappsmicro="calendargoogle
exchangegoogle
gmail
googlenow"

gappsnano="facedetect
faceunlock
search
speech"

gappspico="calsync"

stockremove="browser
camerastock
email
gallery
launcher
mms
picotts"

gappstvcore="bugreport
configupdater
googlebackuptransport
googlecontactssync
gsfcore
notouch
tvetc
tvframework
tvgmscore
tvvending"

gappstvstock="backdrop
castreceiver
globalkey
livechannels
overscan
remotecontrol
secondscreensetup
secondscreenauthbridge
talkback
tvlauncher
tvkeyboardgoogle
tvmovies
tvmusic
tvpackageinstallergoogle
tvplaygames
tvremote
tvsearch
tvwidget
tvyoutube
tvwallpaper
webviewgoogle"

miniremove=""

case "$ARCH" in
  arm64|x86_64)  LIBFOLDER="lib64";;
  *)             LIBFOLDER="lib";;
esac

get_fallback_arch(){
  case "$1" in
    arm)    fallback_arch="all";;
    arm64)  fallback_arch="arm";;
    x86)    fallback_arch="arm";; #by using libhoudini
    x86_64) fallback_arch="x86";; #e.g. chain: x86_64->x86->arm->all
    *)      fallback_arch="$1";; #return original arch if no fallback available
  esac
}

get_supported_variants(){
  case "$1" in
    aroma)          if [ "$API" -ge "22" ]; then
                      supported_variants="pico nano micro mini full stock super"
                    else
                      supported_variants="pico nano micro mini full stock"
                    fi
                    gappsremove_variant="super";;
    super)          supported_variants="pico nano micro mini full stock super"; gappsremove_variant="super";;
    stock)          supported_variants="pico nano micro mini full stock"; gappsremove_variant="super";;
    full)           supported_variants="pico nano micro mini full"; gappsremove_variant="super";;
    mini)           supported_variants="pico nano micro mini"; gappsremove_variant="super";;
    micro)          supported_variants="pico nano micro"; gappsremove_variant="super";;
    nano)           supported_variants="pico nano"; gappsremove_variant="super";;
    pico)           supported_variants="pico"; gappsremove_variant="super";;

    tvstock)        supported_variants="tvstock"; gappsremove_variant="tvstock";;

    *)              supported_variants="";;
  esac
}

get_gapps_list(){
  # Compile the list of applications that will be build for this variant
  case "$1" in
    tv*) gapps_list="$gappstvcore $gappstvcore_optional";;
    *)  gapps_list="$gappscore $gappscore_optional";;
  esac
  for variant in $1; do
    eval "addtogapps=\"\$gapps$variant \$gapps${variant}_optional\""
    gapps_list="$gapps_list $addtogapps"
  done
}

buildtarget() {
preparebuildarea

# Compile the list of applications that will have to be build for this variant
get_gapps_list "$SUPPORTEDVARIANTS"
gapps="$gapps_list"

for app in $gapps; do
  get_package_info "$app"
  if [ -n "$packagename" ]; then
    buildapp "$packagename" "$packagemaxapi" "$packagetype/$app" "$packagetarget"
  fi
  for file in $packagefiles; do
    buildfile "$file" "$packagetype/$app" "common"
  done
  for framework in $packageframework; do
    buildframework "$framework" "$packagetype/$app" "common"
  done
  for lib in $packagelibs; do
    buildsystemlib "$lib" "$packagetype/$app" "common"
  done
done

EXTRACTFILES="app_densities.txt app_sizes.txt" #is executed as first
CHMODXFILES=""
}

get_package_info(){
  packagename=""
  packagetype=""
  packagetarget=""
  packagefiles=""
  packageframework=""
  packagelibs=""
  packagemaxapi="$API"
  packagegappsremove=""
  case "$1" in
    # Common GApps
    configupdater)            packagetype="Core"; packagename="com.google.android.configupdater"; packagetarget="priv-app/ConfigUpdater";; #On Android TV 5.1 and 6.0 this is in 'app'
    extsharedgoogle)          packagetype="Core"; packagename="com.google.android.ext.shared"; packagetarget="app/GoogleExtShared";;
    extservicesgoogle)        packagetype="Core"; packagename="com.google.android.ext.services"; packagetarget="priv-app/GoogleExtServices";;
    googlebackuptransport)    packagetype="Core"; packagename="com.google.android.backuptransport"; packagetarget="priv-app/GoogleBackupTransport";;
    googlecontactssync)       packagetype="Core"; packagename="com.google.android.syncadapters.contacts"; packagetarget="app/GoogleContactsSyncAdapter";;
    gsfcore)                  packagetype="Core"; packagename="com.google.android.gsf"; packagetarget="priv-app/GoogleServicesFramework";;
    talkback)                 packagetype="GApps"; packagename="com.google.android.marvin.talkback"; packagetarget="app/talkback";;
    webviewgoogle)            packagetype="GApps"; packagename="com.google.android.webview"; packagetarget="app/WebViewGoogle"; packagegappsremove="$webviewgappsremove";;
    webviewstub)              packagetype="GApps"; packagename="com.google.android.webview.stub"; packagetarget="app/WebViewStub";;

    # Regular GApps
    defaultetc)               packagetype="Core"; packagefiles="etc/default-permissions/default-permissions.xml etc/default-permissions/opengapps-permissions.xml etc/permissions/privapp-permissions-google.xml etc/sysconfig/framework-sysconfig.xml etc/preferred-apps/google.xml etc/sysconfig/google.xml etc/sysconfig/google_build.xml etc/sysconfig/whitelist_com.android.omadm.service.xml";;  # default-permissions is gone in Oreo
    defaultframework)         packagetype="Core"; packagefiles="etc/permissions/com.google.android.maps.xml etc/permissions/com.google.android.media.effects.xml etc/permissions/com.google.widevine.software.drm.xml"; packageframework="com.google.android.maps.jar com.google.android.media.effects.jar com.google.widevine.software.drm.jar";;  # widevine is gone in Oreo
    androidplatformservices)  packagetype="Core"; packagename="com.google.android.gms.policy_sidecar_o"; packagetarget="priv-app/AndroidPlatformServices";;
    gmscore)                  packagetype="Core"; packagename="com.google.android.gms"; packagetarget="priv-app/PrebuiltGmsCore";;  # Alternative path on Android One 7.0 is priv-app/GmsCore
    gmssetup)                 packagetype="Core"; packagename="com.google.android.gms.setup"; packagetarget="priv-app/GmsCoreSetupPrebuilt";;
    googlefeedback)           packagetype="Core"; packagename="com.google.android.feedback"; packagetarget="priv-app/GoogleFeedback";;
    googleonetimeinitializer) packagetype="Core"; packagename="com.google.android.onetimeinitializer"; packagetarget="priv-app/GoogleOneTimeInitializer";;
    googlepartnersetup)       packagetype="Core"; packagename="com.google.android.partnersetup"; packagetarget="priv-app/GooglePartnerSetup";;
    gsflogin)                 packagetype="Core"; packagename="com.google.android.gsf.login"; packagetarget="priv-app/GoogleLoginService";;  # Gone in Oreo
    setupwizard)              packagetype="Core"; packagename="com.google.android.setupwizard"; packagetarget="priv-app/SetupWizard";; #KitKat only
    setupwizarddefault)       packagetype="Core"; packagename="com.google.android.setupwizard.default"; packagetarget="priv-app/SetupWizard";;
    setupwizardtablet )       packagetype="Core"; packagename="com.google.android.setupwizard.tablet"; packagetarget="priv-app/SetupWizard";;
    vending)                  packagetype="Core"; packagename="com.android.vending"; packagetarget="priv-app/Phonesky";;

    batteryusage)             packagetype="GApps"; packagename="com.google.android.apps.turbo"; packagetarget="priv-app/Turbo";;
    books)                    packagetype="GApps"; packagename="com.google.android.apps.books"; packagetarget="app/Books";;
    calculatorgoogle)         packagetype="GApps"; packagename="com.google.android.calculator"; packagetarget="app/CalculatorGooglePrebuilt";;
    calendargoogle)           packagetype="GApps"; packagename="com.google.android.calendar"; packagetarget="app/CalendarGooglePrebuilt";;
    calsync)                  packagetype="GApps"; packagename="com.google.android.syncadapters.calendar"; packagetarget="app/GoogleCalendarSyncAdapter";;
    cameragoogle)             packagetype="GApps"; packagename="com.google.android.googlecamera"; packagetarget="app/GoogleCamera";
                              if [ "$API" -ge "25" ]; then  # On Nougat 7.1 we bundle Camera 2016
                                packagefiles="etc/permissions/com.google.android.camera.experimental2016.xml"; packageframework="com.google.android.camera.experimental2016.jar"
                              elif [ "$API" -ge "23" ]; then  # On Marshmallow+ we bundle Camera 2015 for non-legacy camera
                                packagefiles="etc/permissions/com.google.android.camera.experimental2015.xml"; packageframework="com.google.android.camera.experimental2015.jar"
                              else
                                packagefiles="etc/permissions/com.google.android.camera2.xml"; packageframework="com.google.android.camera2.jar"
                              fi;;
    cameragooglelegacy)       packagetype="GApps"; packagename="com.google.android.googlecamera"; packagetarget="app/GoogleCameraLegacy"; packagemaxapi="22"; packagefiles="etc/permissions/com.google.android.camera2.xml"; packageframework="com.google.android.camera2.jar";;
    chrome)                   packagetype="GApps"; packagename="com.android.chrome"; packagetarget="app/Chrome";;
    clockgoogle)              packagetype="GApps"; packagename="com.google.android.deskclock"; packagetarget="app/PrebuiltDeskClockGoogle";;
    cloudprint)               packagetype="GApps"; packagename="com.google.android.apps.cloudprint"; packagetarget="app/CloudPrint2";;
    contactsgoogle)           packagetype="GApps"; packagename="com.google.android.contacts"; packagetarget="priv-app/GoogleContacts";;
    dialerframework)          packagetype="GApps"; packagefiles="etc/permissions/com.google.android.dialer.support.xml etc/sysconfig/dialer_experience.xml"; packageframework="com.google.android.dialer.support.jar";;
    dialergoogle)             packagetype="GApps"; packagename="com.google.android.dialer"; packagetarget="priv-app/GoogleDialer";;
    dmagent)                  packagetype="GApps"; packagename="com.google.android.apps.enterprise.dmagent"; packagetarget="app/DMAgent";;
    docs)                     packagetype="GApps"; packagename="com.google.android.apps.docs.editors.docs"; packagetarget="app/EditorsDocs";;
    drive)                    packagetype="GApps"; packagename="com.google.android.apps.docs"; packagetarget="app/Drive";;
    duo)                      packagetype="GApps"; packagename="com.google.android.apps.tachyon"; packagetarget="app/Duo";;
    earth)                    packagetype="GApps"; packagename="com.google.earth"; packagetarget="app/GoogleEarth";;
    exchangegoogle)           packagetype="GApps"; packagename="com.google.android.gm.exchange"; packagetarget="app/PrebuiltExchange3Google";;
    facedetect)               packagetype="GApps";
                              if [ "$LIBFOLDER" = "lib64" ]; then #on 64 bit, we also need the 32 bit lib of libfilterpack_facedetect.so
                                packagelibs="libfilterpack_facedetect.so+fallback";
                              else
                                packagelibs="libfilterpack_facedetect.so";
                              fi;;
    faceunlock)               case "$ARCH" in #only arm based platforms
                                arm*) packagetype="GApps"; packagename="com.android.facelock"; packagetarget="app/FaceLock";
                                      if [ "$API" -ge "24" ]; then  # On 7.0+ the facelock library is libfacenet.so
                                        FACELOCKLIB="libfacenet.so"
					# On 8.0+ we also need libprotobuf-cpp-shit.so as there is no libfacenet.so for 8.0+ 32bit devices.
                                        FACELOCKLIB2="libprotobuf-cpp-shit.so"
                                      else  # Before Nougat there is a pittpatt folder and libfacelock_jni
                                        packagefiles="vendor/pittpatt/";
                                        FACELOCKLIB="libfacelock_jni.so"
                                      fi
                                      if [ "$LIBFOLDER" = "lib64" ]; then #on 64 bit, we also need the 32 bit lib of libfrsdk.so
                                        packagelibs="$FACELOCKLIB $FACELOCKLIB2+fallback libfrsdk.so+fallback";
                                      else
                                        packagelibs="$FACELOCKLIB $FACELOCKLIB2 libfrsdk.so";
                                      fi;;
                              esac;;
    fitness)                  packagetype="GApps"; packagename="com.google.android.apps.fitness"; packagetarget="app/FitnessPrebuilt";;
    gcs)                      packagetype="GApps"; packagename="com.google.android.apps.gcs"; packagetarget="priv-app/GCS";;
    gmail)                    packagetype="GApps"; packagename="com.google.android.gm"; packagetarget="app/PrebuiltGmail";;
    googlenow)                packagetype="GApps"; packagename="com.google.android.launcher"; packagetarget="app/GoogleHome";;
    googlepay)                packagetype="GApps"; packagename="com.google.android.apps.walletnfcrel"; packagetarget="app/Wallet";;
    googlepixelconfig)        packagetype="GApps"; packagefiles="etc/sysconfig/nexus.xml";;
    googleplus)               packagetype="GApps"; packagename="com.google.android.apps.plus"; packagetarget="app/PlusOne";;
    googletts)                packagetype="GApps"; packagename="com.google.android.tts"; packagetarget="app/GoogleTTS";;
    hangouts)                 packagetype="GApps"; packagename="com.google.android.talk"; packagetarget="app/Hangouts";;
    indic)                    packagetype="GApps"; packagename="com.google.android.apps.inputmethod.hindi"; packagetarget="app/GoogleHindiIME";;
    japanese)                 packagetype="GApps"; packagename="com.google.android.inputmethod.japanese"; packagetarget="app/GoogleJapaneseInput";;  # also JapaneseIME exists on some ROMs
    korean)                   packagetype="GApps"; packagename="com.google.android.inputmethod.korean"; packagetarget="app/KoreanIME";;
    keep)                     packagetype="GApps"; packagename="com.google.android.keep"; packagetarget="app/PrebuiltKeep";;
    keyboardgoogle)           packagetype="GApps"; packagename="com.google.android.inputmethod.latin";
                              if [ "$API" -ge "24" ]; then
                                packagetarget="app/LatinIMEGooglePrebuilt"
                              else
                                packagetarget="app/LatinImeGoogle"
                              fi;;
    maps)                     packagetype="GApps"; packagename="com.google.android.apps.maps"; packagetarget="app/Maps";;
    messenger)                packagetype="GApps"; packagename="com.google.android.apps.messaging"; packagetarget="app/PrebuiltBugle";;
    movies)                   packagetype="GApps"; packagename="com.google.android.videos"; packagetarget="app/Videos";;
    moviesvrmode)             packagetype="GApps"; packagename="com.google.android.videos.vrmode"; packagetarget="app/Videos";;
    music)                    packagetype="GApps"; packagename="com.google.android.music"; packagetarget="app/Music2";;
    newsstand)                packagetype="GApps"; packagename="com.google.android.apps.magazines"; packagetarget="app/Newsstand";;
    newswidget)               packagetype="GApps"; packagename="com.google.android.apps.genie.geniewidget"; packagetarget="app/PrebuiltNewsWeather";;
    packageinstallergoogle)   packagetype="GApps"; packagename="com.google.android.packageinstaller"; packagetarget="priv-app/GooglePackageInstaller";;
    pixelicons)               packagetype="GApps"; packagename="com.google.android.nexusicons"; packagetarget="app/NexusLauncherIcons";;
    pixellauncher)            packagetype="GApps"; packagename="com.google.android.apps.nexuslauncher"; packagetarget="priv-app/NexusLauncherPrebuilt";;
    photos)                   packagetype="GApps"; packagename="com.google.android.apps.photos"; packagetarget="app/Photos";;
    photosvrmode)             packagetype="GApps"; packagename="com.google.android.apps.photos.vrmode"; packagetarget="app/Photos";;
    pinyin)                   packagetype="GApps"; packagename="com.google.android.inputmethod.pinyin"; packagetarget="app/GooglePinyinIME";;
    playgames)                packagetype="GApps"; packagename="com.google.android.play.games"; packagetarget="app/PlayGames";;
    printservicegoogle)       packagetype="GApps"; packagename="com.google.android.printservice.recommendation"; packagetarget="app/GooglePrintRecommendationService";;
    projectfi)                packagetype="GApps"; packagename="com.google.android.apps.tycho"; packagetarget="app/Tycho";;
    search)                   packagetype="GApps"; packagename="com.google.android.googlequicksearchbox"; packagetarget="priv-app/Velvet";;
    sheets)                   packagetype="GApps"; packagename="com.google.android.apps.docs.editors.sheets"; packagetarget="app/EditorsSheets";;
    slides)                   packagetype="GApps"; packagename="com.google.android.apps.docs.editors.slides"; packagetarget="app/EditorsSlides";;
    speech)                   packagetype="GApps"; packagefiles="usr/srec/en-US/";;
    storagemanagergoogle)     packagetype="GApps"; packagename="com.google.android.storagemanager"; packagetarget="priv-app/StorageManagerGoogle";;
    street)                   packagetype="GApps"; packagename="com.google.android.street"; packagetarget="app/Street";;
    taggoogle)                packagetype="GApps"; packagename="com.google.android.tag"; packagetarget="priv-app/TagGoogle";;
    translate)                packagetype="GApps"; packagename="com.google.android.apps.translate"; packagetarget="app/TranslatePrebuilt";;
    vrservice)                packagetype="GApps"; packagefiles="etc/sysconfig/google_vr_build.xml"; packagename="com.google.vr.vrcore"; packagetarget="app/GoogleVrCore";;
    wallpapers)               packagetype="GApps"; packagename="com.google.android.apps.wallpaper"; packagetarget="app/WallpaperPickerGooglePrebuilt";;
    youtube)                  packagetype="GApps"; packagename="com.google.android.youtube"; packagetarget="app/YouTube";;
    zhuyin)                   packagetype="GApps"; packagename="com.google.android.apps.inputmethod.zhuyin"; packagetarget="app/GoogleZhuyinIME";;  # also ZhuyinIME exists on some ROMs

    # TV GApps
    bugreport)                packagetype="Core"; packagetarget="app/BugReportSender";
                              if [ "$API" -ge "24" ]; then
                                packagename="com.google.android.tv.bugreportsender"
                              else
                                packagename="com.google.tungsten.bugreportsender"
                              fi;;
    notouch)                  packagetype="Core"; packagename="com.google.android.gsf.notouch"; packagetarget="app/NoTouchAuthDelegate";;
    tvetc)                    packagetype="Core"; packagefiles="etc/sysconfig/google.xml etc/sysconfig/google_build.xml";;
    tvframework)              packagetype="Core"; packagefiles="etc/permissions/com.google.android.pano.v1.xml etc/permissions/com.google.android.tv.installed.xml etc/permissions/com.google.widevine.software.drm.xml"; packageframework="com.google.android.pano.v1.jar com.google.widevine.software.drm.jar";;
    tvgmscore)                packagetype="Core"; packagename="com.google.android.gms.leanback"; packagetarget="priv-app/PrebuiltGmsCorePano";;
    tvvending)                packagetype="Core"; packagename="com.android.vending.leanback";
                              if [ "$API" -ge "24" ]; then
                                packagetarget="priv-app/Tubesky"
                              else
                                packagetarget="priv-app/PhoneskyKamikazeCanvas"
                              fi;;

    backdrop)                 packagetype="GApps"; packagename="com.google.android.backdrop.leanback"; packagetarget="app/Backdrop";;
    castreceiver)             packagetype="GApps"; packagename="com.google.android.apps.mediashell.leanback" packagetarget="priv-app/AndroidMediaShell";;
    globalkey)                packagetype="GApps"; packagename="com.google.android.athome.globalkeyinterceptor" packagetarget="priv-app/GlobalKeyInterceptor";;
    livechannels)             packagetype="GApps"; packagename="com.google.android.tv.leanback" packagetarget="priv-app/TV";;
    overscan)                 packagetype="GApps"; packagename="com.google.android.tungsten.overscan" packagetarget="priv-app/Overscan";;
    remotecontrol)            packagetype="GApps"; packagename="com.google.android.athome.remotecontrol" packagetarget="priv-app/RemoteControlService";;
    secondscreensetup)        packagetype="GApps"; packagename="com.google.android.sss"; packagetarget="app/SecondScreenSetup";;
    secondscreenauthbridge)   packagetype="GApps"; packagename="com.google.android.sss.authbridge"; packagetarget="app/SecondScreenSetupAuthBridge";;
    tvlauncher)               packagetype="GApps"; packagename="com.google.android.leanbacklauncher.leanback" packagetarget="priv-app/LeanbackLauncher";;
    tvkeyboardgoogle)         packagetype="GApps"; packagename="com.google.android.leanback.ime"; packagetarget="app/LeanbackIme";;
    tvmovies)                 packagetype="GApps"; packagename="com.google.android.videos.leanback"; packagetarget="app/VideosPano";;
    tvmusic)                  packagetype="GApps"; packagename="com.google.android.music"; packagetarget="app/Music2Pano";;  # Only change is the foldername
    tvpackageinstallergoogle) packagetype="GApps"; packagename="com.google.android.pano.packageinstaller"; packagetarget="priv-app/CanvasPackageInstaller";;  # on 5.1 and 6.0 this was in 'app'
    tvplaygames)              packagetype="GApps"; packagename="com.google.android.play.games.leanback"; packagetarget="app/PlayGames";;  # Only change is leanback in the packagename
    tvrecommendations)        packagetype="GApps"; packagename="com.google.android.leanbacklauncher.recommendations.leanback"; packagetarget="priv-app/RecommendationsService";;
    tvremote)                 packagetype="GApps";  packagetarget="priv-app/AtvRemoteService";
                              if [ "$API" -ge "24" ]; then
                                packagename="com.google.android.tv.remote.service.leanback"
                              else
                                packagename="com.google.android.tv.remote"
                                packagelibs="libatv_uinputbridge.so"
                              fi;;
    tvsearch)                 packagetype="GApps"; packagename="com.google.android.katniss.leanback"; packagetarget="priv-app/Katniss";;
    tvvoiceinput)             packagetype="GApps"; packagename="com.google.android.tv.voiceinput"; packagetarget="app/TvVoiceInput";;  # Only in 5.1
    tvwallpaper)              packagetype="GApps"; packagename="com.google.android.landscape"; packagetarget="app/LandscapeWallpaper";;
    tvwidget)                 packagetype="GApps"; packagename="com.google.android.atv.widget"; packagetarget="app/AtvWidget";;
    tvyoutube)                packagetype="GApps"; packagename="com.google.android.youtube.tv.leanback"; packagetarget="app/YouTubeLeanback";;

    # Swypelibs
    swypelibs)                packagetype="Optional"; packagelibs="libjni_latinimegoogle.so";
                              if [ "$API" -eq "23" ]; then  # On Marshmallow there is an extra lib
                                packagelibs="$packagelibs libjni_keyboarddecoder.so"
                              fi;;

    *)              echo "ERROR! Missing build rule for application with keyword $1"; exit 1;;
  esac
}
