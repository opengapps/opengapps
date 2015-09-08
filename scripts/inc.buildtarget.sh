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
gsflogin
vending"

gappscore_optional=""

gappssuper="androidforwork
androidpay
dmagent
earth
gcs
indic
japanese
korean
pinyin
projectfi
street
translate
zhuyin"

gappsstock="cameragoogle
keyboardgoogle
messenger"

gappsstock_optional=""

gappsfull="books
chrome
cloudprint
docs
drive
ears
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

gappsmini="clockgoogle
hangouts
maps
photos
youtube"

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
gsfcore
notouch
setupwraith
tvetc
tvframework
tvgmscore
tvvending"

gappstvstock="backdrop
castreceiver
gamepadpairing
globalkey
livechannels
overscan
remotecontrol
secondscreensetup
secondscreenauthbridge
talkback
tvcustomization
tvlauncher
tvkeyboardgoogle
tvmovies
tvmusic
tvpackageinstallergoogle
tvpairing
tvplaygames
tvremote
tvsearch
tvwidget
tvyoutube
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
    buildfile "$file" "$packagetype/$app/common"
  done
  for lib in $packagelibs; do
    buildsystemlib "$lib" "$packagetype/$app/common"
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
  packagelibs=""
  packagemaxapi="$API"
  packagegappsremove=""
  case "$1" in
    # Common GApps
    configupdater)            packagetype="Core"; packagename="com.google.android.configupdater"; packagetarget="priv-app/ConfigUpdater";; #On Android TV this is in 'app'
    googlebackuptransport)    packagetype="Core"; packagename="com.google.android.backuptransport"; packagetarget="priv-app/GoogleBackupTransport";;
    gsfcore)                  packagetype="Core"; packagename="com.google.android.gsf"; packagetarget="priv-app/GoogleServicesFramework";;
    talkback)                 packagetype="GApps"; packagename="com.google.android.marvin.talkback"; packagetarget="app/talkback";;
    webviewgoogle)            packagetype="GApps"; packagename="com.google.android.webview"; packagetarget="app/WebViewGoogle"; packagegappsremove="$webviewgappsremove";;

    # Regular GApps
    defaultetc)               packagetype="Core"; packagefiles="etc/preferred-apps/google.xml etc/sysconfig/google.xml etc/sysconfig/google_build.xml etc/sysconfig/whitelist_com.android.omadm.service.xml";;
    defaultframework)         packagetype="Core"; packagefiles="etc/permissions/com.google.android.maps.xml etc/permissions/com.google.android.media.effects.xml etc/permissions/com.google.widevine.software.drm.xml framework/com.google.android.maps.jar framework/com.google.android.media.effects.jar framework/com.google.widevine.software.drm.jar";;
    gmscore)                  packagetype="Core"; packagename="com.google.android.gms"; packagetarget="priv-app/PrebuiltGmsCore";;
    googlecontactssync)       packagetype="Core"; packagename="com.google.android.syncadapters.contacts"; packagetarget="app/GoogleContactsSyncAdapter";;
    googlefeedback)           packagetype="Core"; packagename="com.google.android.feedback"; packagetarget="priv-app/GoogleFeedback";;
    googleonetimeinitializer) packagetype="Core"; packagename="com.google.android.onetimeinitializer"; packagetarget="priv-app/GoogleOneTimeInitializer";;
    googlepartnersetup)       packagetype="Core"; packagename="com.google.android.partnersetup"; packagetarget="priv-app/GooglePartnerSetup";;
    gsflogin)                 packagetype="Core"; packagename="com.google.android.gsf.login"; packagetarget="priv-app/GoogleLoginService";;
    setupwizard)              packagetype="Core"; packagename="com.google.android.setupwizard"; packagetarget="priv-app/SetupWizard";; #KitKat only
    setupwizarddefault)       packagetype="Core"; packagename="com.google.android.setupwizard.default"; packagetarget="priv-app/SetupWizard";;
    setupwizardtablet )       packagetype="Core"; packagename="com.google.android.setupwizard.tablet"; packagetarget="priv-app/SetupWizard";;
    vending)                  packagetype="Core"; packagename="com.android.vending"; packagetarget="priv-app/Phonesky";;

    androidforwork)           packagetype="GApps"; packagename="com.google.android.androidforwork"; packagetarget="priv-app/AndroidForWork";;
    androidpay)               packagetype="GApps"; packagename="com.google.android.apps.walletnfcrel"; packagetarget="app/Wallet";;
    books)                    packagetype="GApps"; packagename="com.google.android.apps.books"; packagetarget="app/Books";;
    calculatorgoogle)         packagetype="GApps"; packagename="com.google.android.calculator"; packagetarget="app/CalculatorGoogle";;
    calendargoogle)           packagetype="GApps"; packagename="com.google.android.calendar"; packagetarget="app/CalendarGooglePrebuilt";;
    calsync)                  packagetype="GApps"; packagename="com.google.android.syncadapters.calendar"; packagetarget="app/GoogleCalendarSyncAdapter";;
    cameragoogle)             packagetype="GApps"; packagename="com.google.android.googlecamera"; packagetarget="app/GoogleCamera";
                              if [ "$API" -ge "23" ]; then  # On Marshmallow+ we use the new GoogleCamera
                                packagefiles="etc/permissions/com.google.android.camera.experimental2015.xml framework/com.google.android.camera.experimental2015.jar"
                              else
                                packagefiles="etc/permissions/com.google.android.camera2.xml framework/com.google.android.camera2.jar"
                              fi;;
    cameragooglelegacy)       packagetype="GApps"; packagename="com.google.android.googlecamera"; packagetarget="app/GoogleCamera"; packagemaxapi="22"; packagefiles="etc/permissions/com.google.android.camera2.xml framework/com.google.android.camera2.jar";;
    chrome)                   packagetype="GApps"; packagename="com.android.chrome"; packagetarget="app/Chrome";;
    clockgoogle)              packagetype="GApps"; packagename="com.google.android.deskclock"; packagetarget="app/PrebuiltDeskClockGoogle";;
    cloudprint)               packagetype="GApps"; packagename="com.google.android.apps.cloudprint"; packagetarget="app/CloudPrint2";;
    contactsgoogle)           packagetype="GApps"; packagename="com.google.android.contacts"; packagetarget="priv-app/GoogleContacts";;
    dialergoogle)             packagetype="GApps"; packagename="com.google.android.dialer"; packagetarget="priv-app/GoogleDialer"; packagefiles="etc/permissions/com.google.android.dialer.support.xml framework/com.google.android.dialer.support.jar";;
    dmagent)                  packagetype="GApps"; packagename="com.google.android.apps.enterprise.dmagent"; packagetarget="app/DMAgent";;
    docs)                     packagetype="GApps"; packagename="com.google.android.apps.docs.editors.docs"; packagetarget="app/EditorsDocs";;
    drive)                    packagetype="GApps"; packagename="com.google.android.apps.docs"; packagetarget="app/Drive";;
    ears)                     packagetype="GApps"; packagename="com.google.android.ears"; packagetarget="app/GoogleEars";;
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
                                      packagefiles="vendor/pittpatt/";
                                      if [ "$LIBFOLDER" = "lib64" ]; then #on 64 bit, we also need the 32 bit lib of librsdk.so
                                        packagelibs="libfacelock_jni.so libfrsdk.so+fallback";
                                      else
                                        packagelibs="libfacelock_jni.so libfrsdk.so";
                                      fi;;
                              esac;;
    fitness)                  packagetype="GApps"; packagename="com.google.android.apps.fitness"; packagetarget="app/FitnessPrebuilt";;
    gcs)                      packagetype="GApps"; packagename="com.google.android.apps.gcs"; packagetarget="priv-app/GCS";;
    gmail)                    packagetype="GApps"; packagename="com.google.android.gm"; packagetarget="app/PrebuiltGmail";;
    googlenow)                packagetype="GApps"; packagename="com.google.android.launcher"; packagetarget="app/GoogleHome";;
    googleplus)               packagetype="GApps"; packagename="com.google.android.apps.plus"; packagetarget="app/PlusOne";;
    googletts)                packagetype="GApps"; packagename="com.google.android.tts"; packagetarget="app/GoogleTTS";;
    hangouts)                 packagetype="GApps"; packagename="com.google.android.talk"; packagetarget="app/Hangouts";;
    hotword)                  packagetype="GApps"; packagename="com.android.hotwordenrollment"; packagetarget="priv-app/HotwordEnrollment";;
    indic)                    packagetype="GApps"; packagename="com.google.android.apps.inputmethod.hindi"; packagetarget="app/GoogleHindiIME";;
    japanese)                 packagetype="GApps"; packagename="com.google.android.inputmethod.japanese"; packagetarget="app/GoogleJapaneseInput";;
    korean)                   packagetype="GApps"; packagename="com.google.android.inputmethod.korean"; packagetarget="app/KoreanIME";;
    keep)                     packagetype="GApps"; packagename="com.google.android.keep"; packagetarget="app/PrebuiltKeep";;
    keyboardgoogle)           packagetype="GApps"; packagename="com.google.android.inputmethod.latin"; packagetarget="app/LatinImeGoogle";;
    maps)                     packagetype="GApps"; packagename="com.google.android.apps.maps"; packagetarget="app/Maps";;
    messenger)                packagetype="GApps"; packagename="com.google.android.apps.messaging"; packagetarget="app/PrebuiltBugle";;
    movies)                   packagetype="GApps"; packagename="com.google.android.videos"; packagetarget="app/Videos";;
    music)                    packagetype="GApps"; packagename="com.google.android.music"; packagetarget="app/Music2";;
    newsstand)                packagetype="GApps"; packagename="com.google.android.apps.magazines"; packagetarget="app/Newsstand";;
    newswidget)               packagetype="GApps"; packagename="com.google.android.apps.genie.geniewidget"; packagetarget="app/PrebuiltNewsWeather";;
    packageinstallergoogle)   packagetype="GApps"; packagename="com.google.android.packageinstaller"; packagetarget="priv-app/GooglePackageInstaller";;
    photos)                   packagetype="GApps"; packagename="com.google.android.apps.photos"; packagetarget="app/Photos";;
    pinyin)                   packagetype="GApps"; packagename="com.google.android.inputmethod.pinyin"; packagetarget="app/GooglePinyinIME";;
    playgames)                packagetype="GApps"; packagename="com.google.android.play.games"; packagetarget="app/PlayGames";;
    projectfi)                packagetype="GApps"; packagename="com.google.android.apps.tycho"; packagetarget="app/Tycho";;
    search)                   packagetype="GApps"; packagename="com.google.android.googlequicksearchbox"; packagetarget="priv-app/Velvet";;
    sheets)                   packagetype="GApps"; packagename="com.google.android.apps.docs.editors.sheets"; packagetarget="app/EditorsSheets";;
    slides)                   packagetype="GApps"; packagename="com.google.android.apps.docs.editors.slides"; packagetarget="app/EditorsSlides";;
    speech)                   packagetype="GApps"; packagefiles="usr/srec/en-US/";;
    street)                   packagetype="GApps"; packagename="com.google.android.street"; packagetarget="app/Street";;
    taggoogle)                packagetype="GApps"; packagename="com.google.android.tag"; packagetarget="priv-app/TagGoogle";;
    translate)                packagetype="GApps"; packagename="com.google.android.apps.translate"; packagetarget="app/TranslatePrebuilt";;
    youtube)                  packagetype="GApps"; packagename="com.google.android.youtube"; packagetarget="app/YouTube";;
    zhuyin)                   packagetype="GApps"; packagename="com.google.android.apps.inputmethod.zhuyin"; packagetarget="app/GoogleZhuyinIME";;

    # TV GApps
    bugreport)                packagetype="Core"; packagename="com.google.tungsten.bugreportsender"; packagetarget="app/BugReportSender";;
    notouch)                  packagetype="Core"; packagename="com.google.android.gsf.notouch"; packagetarget="app/NoTouchAuthDelegate";;
    setupwraith)              packagetype="Core"; packagename="com.google.android.tungsten.setupwraith"; packagetarget="priv-app/SetupWraith";;
    tvetc)                    packagetype="Core"; packagefiles="etc/sysconfig/google.xml etc/sysconfig/google_build.xml";;
    tvframework)              packagetype="Core"; packagefiles="etc/permissions/com.google.android.pano.v1.xml etc/permissions/com.google.widevine.software.drm.xml framework/com.google.android.pano.v1.jar framework/com.google.widevine.software.drm.jar";;
    tvgmscore)                packagetype="Core"; packagename="com.google.android.gms.leanback"; packagetarget="priv-app/PrebuiltGmsCorePano";;
    tvvending)                packagetype="Core"; packagename="com.android.vending.leanback"; packagetarget="priv-app/PhoneskyKamikazeCanvas";;

    backdrop)                 packagetype="GApps"; packagename="com.google.android.backdrop.leanback"; packagetarget="app/Backdrop";;
    castreceiver)             packagetype="GApps"; packagename="com.google.android.apps.mediashell.leanback" packagetarget="priv-app/AndroidMediaShell";;
    gamepadpairing)           packagetype="GApps"; packagename="com.google.android.tv.remotepairing" packagetarget="priv-app/GamepadPairingService";;
    globalkey)                packagetype="GApps"; packagename="com.google.android.athome.globalkeyinterceptor" packagetarget="priv-app/GlobalKeyInterceptor";;
    livechannels)             packagetype="GApps"; packagename="com.google.android.tv.leanback" packagetarget="priv-app/TV";;
    overscan)                 packagetype="GApps"; packagename="com.google.android.tungsten.overscan" packagetarget="priv-app/Overscan";;
    remotecontrol)            packagetype="GApps"; packagename="com.google.android.athome.remotecontrol" packagetarget="priv-app/RemoteControlService";;
    secondscreensetup)        packagetype="GApps"; packagename="com.google.android.sss"; packagetarget="app/SecondScreenSetup";;
    secondscreenauthbridge)   packagetype="GApps"; packagename="com.google.android.sss.authbridge"; packagetarget="app/SecondScreenSetupAuthBridge";;
    tvcustomization)          packagetype="GApps"; packagename="com.google.android.atv.customization" packagetarget="priv-app/AtvCustomization";;
    tvlauncher)               packagetype="GApps"; packagename="com.google.android.leanbacklauncher.leanback" packagetarget="priv-app/LeanbackLauncher";;
    tvkeyboardgoogle)         packagetype="GApps"; packagename="com.google.android.leanback.ime"; packagetarget="app/LeanbackIme";;
    tvmovies)                 packagetype="GApps"; packagename="com.google.android.videos.leanback"; packagetarget="app/VideosPano";;
    tvmusic)                  packagetype="GApps"; packagename="com.google.android.music"; packagetarget="app/Music2Pano";;  # Only change is the foldername
    tvpackageinstallergoogle) packagetype="GApps"; packagename="com.google.android.pano.packageinstaller"; packagetarget="app/CanvasPackageInstaller";;
    tvpairing)                packagetype="GApps"; packagename="com.google.android.fugu.pairing"; packagetarget="app/FuguPairingTutorial";;
    tvplaygames)              packagetype="GApps"; packagename="com.google.android.play.games.leanback"; packagetarget="app/PlayGames";;  # Only change is leanback in the packagename
    tvremote)                 packagetype="GApps"; packagename="com.google.android.tv.remote" packagetarget="priv-app/AtvRemoteService"; packagelibs="libatv_uinputbridge.so";;
    tvsearch)                 packagetype="GApps"; packagename="com.google.android.katniss.leanback"; packagetarget="priv-app/Katniss";;
    tvvoiceinput)             packagetype="GApps"; packagename="com.google.android.tv.voiceinput"; packagetarget="app/TvVoiceInput";;  # Only in 5.1
    tvwidget)                 packagetype="GApps"; packagename="com.google.android.atv.widget"; packagetarget="app/AtvWidget";;
    tvyoutube)                packagetype="GApps"; packagename="com.google.android.youtube.tv.leanback"; packagetarget="app/YouTubeLeanback";;

    # Swypelibs
    swypelibs)                packagetype="Optional"; packagelibs="libjni_latinimegoogle.so";
                              if [ "$API" -ge "23" ]; then  # On Marshmallow+ there is an extra lib
                                packagelibs="$packagelibs libjni_keyboarddecoder.so"
                              fi;;

    *)              echo "ERROR! Missing build rule for application with keyword $1"; exit 1;;
  esac
}
