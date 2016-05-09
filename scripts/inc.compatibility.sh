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

cameracompatibilityhack(){
  if [ "$API" -le "19" ]; then
    echo '    A0001|bacon|find7) cameragoogle_compat=false;; # bacon or A0001=OnePlus One | find7=Oppo Find7 and Find7a' >> "$1"
  fi
}

camerav3compatibilityhack(){
  if [ "$API" -ge "23" ]; then
    echo '
# Google Camera fallback to Legacy if incompatible with new Camera API
case $newcamera_compat in
  false*) gapps_list=${gapps_list/cameragoogle/cameragooglelegacy}; log "Google Camera version" "Legacy";;
esac' >> "$1"
  fi
}

hotwordadditionhack(){
  if [ "$API" -ge "21" ] && [ "$ARCH" = "arm64" ]; then
    tee -a "$1" > /dev/null <<'EOFILE'
# On Marshmallow; If we're installing search we must install hotword too (if it's not already there)
if ( contains "$gapps_list" "search" ) && ( ! contains "$gapps_list" "hotword" ); then
  gapps_list="${gapps_list}hotword"$'\n';
fi;

EOFILE
  fi
}

keyboardgooglenotremovehack(){
  if [ "$API" -le "19" ]; then
    echo '  sed -i "\:/system/app/LatinImeGoogle.apk:d" $gapps_removal_list;'>> "$1"
  else
    echo '  sed -i "\:/system/app/LatinImeGoogle:d" $gapps_removal_list;'>> "$1"
  fi
}

keyboardlibhack(){
  if [ "$API" -ge "23" ]; then # on Marshmallow it is like Lollipop but with extra libjni_keyboarddecoder.so; on Marshmallow we support all platforms
    gappscore_optional="swypelibs $gappscore_optional"
    REQDLIST='/system/lib/libjni_latinimegoogle.so
/system/lib64/libjni_latinimegoogle.so
/system/app/LatinIME/lib/$arch/libjni_latinimegoogle.so
/system/lib/libjni_keyboarddecoder.so
/system/lib64/libjni_keyboarddecoder.so
/system/app/LatinIME/lib/$arch/libjni_keyboarddecoder.so'
    KEYBDLIBS='keybd_lib_google="libjni_latinimegoogle.so"
keybd_dec_google="libjni_keyboarddecoder.so"
keybd_lib_aosp="libjni_latinime.so"'
    # Only touch AOSP keyboard only if it is not removed
    KEYBDINSTALLCODE='# Install/Remove SwypeLibs
if ( ! contains "$gapps_list" "keyboardgoogle" ); then
  if [ "$skipswypelibs" = "false" ]; then
    if [ "$substituteswypelibs" = "true" ]; then
      keybd_lib_target="$keybd_lib_aosp"
      rm -f "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_google" # remove swypelibs and symlink if any
      rm -f "/system/app/LatinIME/$libfolder/$arch/$keybd_dec_google" # remove swypelibs and symlink if any
    else
      keybd_lib_target="$keybd_lib_google"
      ln -sfn "/system/$libfolder/$keybd_lib_aosp" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp" # relink aosp as the normal link
    fi
    ui_print "- Installing swypelibs"
    extract_app "Optional/swypelibs-lib-$arch"  # Keep it simple, swypelibs is only lib-$arch
    install -d "/system/app/LatinIME/$libfolder/$arch"
    ln -sfn "/system/$libfolder/$keybd_lib_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_target" # create required symlink
    ln -sfn "/system/$libfolder/$keybd_dec_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_dec_google" # create required symlink

    # Add same code to backup script to insure symlinks are recreated on addon.d restore
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"/system/$libfolder/$keybd_dec_google\" \"/system/app/LatinIME/$libfolder/$arch/$keybd_dec_google\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"/system/$libfolder/$keybd_lib_google\" \"/system/app/LatinIME/$libfolder/$arch/$keybd_lib_target\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    install -d \"/system/app/LatinIME/$libfolder/$arch\"" $bkup_tail
  else
    ui_print "- Removing swypelibs"
    rm -f "/system/$libfolder/$keybd_lib_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_google" # remove swypelibs and symlink if any
    rm -f "/system/$libfolder/$keybd_dec_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_dec_google" # remove swypelibs and symlink if any
    ln -sfn "/system/$libfolder/$keybd_lib_aosp" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp" # restore non-swypelibs symlink
  fi
fi'
  elif [ "$API" -gt "19" ]; then # on Lollipop there are symlinks in /LatinIME/lib/ and we don't need to remove the aosp lib
    case "$ARCH" in #only arm-based platforms have swypelibs on Lollipop
    arm*)
      gappscore_optional="swypelibs $gappscore_optional"
      REQDLIST='/system/lib/libjni_latinimegoogle.so
/system/lib64/libjni_latinimegoogle.so
/system/app/LatinIME/lib/$arch/libjni_latinimegoogle.so'
      KEYBDLIBS='keybd_lib_google="libjni_latinimegoogle.so"
keybd_lib_aosp="libjni_latinime.so"'
      # Only touch AOSP keyboard only if it is not removed
      KEYBDINSTALLCODE='# Install/Remove SwypeLibs
if ( ! contains "$gapps_list" "keyboardgoogle" ); then
  if [ "$skipswypelibs" = "false" ]; then
    if [ "$substituteswypelibs" = "true" ]; then
      keybd_lib_target="$keybd_lib_aosp"
      rm -f "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_google" # remove swypelibs and symlink if any
    else
      keybd_lib_target="$keybd_lib_google"
      ln -sfn "/system/$libfolder/$keybd_lib_aosp" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp" # relink aosp as the normal link
    fi
    ui_print "- Installing swypelibs"
    extract_app "Optional/swypelibs-lib-$arch"  # Keep it simple, swypelibs is only lib-$arch
    install -d "/system/app/LatinIME/$libfolder/$arch"
    ln -sfn "/system/$libfolder/$keybd_lib_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_target" # create required symlink

    # Add same code to backup script to insure symlinks are recreated on addon.d restore
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"/system/$libfolder/$keybd_lib_google\" \"/system/app/LatinIME/$libfolder/$arch/$keybd_lib_target\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    install -d \"/system/app/LatinIME/$libfolder/$arch\"" $bkup_tail
  else
    ui_print "- Removing swypelibs"
    rm -f "/system/$libfolder/$keybd_lib_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_google" # remove swypelibs and symlink if any
    ln -sfn "/system/$libfolder/$keybd_lib_aosp" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp" # restore non-swypelibs symlink
  fi
fi';;
      *) REQDLIST=""
         KEYBDLIBS=""
         KEYBDINSTALLCODE="";;
    esac
  else # on KitKat we need to replace the aosp lib with a symlink, it has no 64bit libs
    case "$ARCH" in #only arm-based platforms have swypelibs on KitKat
      arm*)
        gappscore_optional="swypelibs $gappscore_optional"
        REQDLIST="/system/lib/libjni_latinime.so
/system/lib/libjni_latinimegoogle.so"
        KEYBDLIBS='keybd_lib_google="libjni_latinimegoogle.so"
keybd_lib_aosp="libjni_latinime.so"'
        # Only touch AOSP keyboard only if it is not removed
        KEYBDINSTALLCODE='# Install/Remove SwypeLibs
if ( ! contains "$gapps_list" "keyboardgoogle" ); then
  if [ "$skipswypelibs" = "false" ]; then
    ui_print "- Installing swypelibs"
    extract_app "Optional/swypelibs-lib-$arch"  # Keep it simple, swypelibs is only lib-$arch
    ln -sfn "/system/$libfolder/$keybd_lib_google" "/system/$libfolder/$keybd_lib_aosp" # create required symlink

    # Add same code to backup script to insure symlinks are recreated on addon.d restore
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"/system/$libfolder/$keybd_lib_google\" \"/system/$libfolder/$keybd_lib_aosp\"" $bkup_tail
  else
    ui_print "- Restoring non-swypelibs"
    rm -f "/system/$libfolder/$keybd_lib_google" # remove swypelibs
    ln -sfn "/system/$libfolder/$keybd_lib_aosp" "/system/$libfolder/$arch/$keybd_lib_aosp" # restore non-swypelibs symlink
  fi
fi';;
      *) REQDLIST=""
         KEYBDLIBS=""
         KEYBDINSTALLCODE="";;
    esac
  fi
}

kitkatdatahack(){
  if [ "$API" -le "19" ]; then
    DATASIZESCODE='    # Broken lib configuration on KitKat, so some apps do not count for the /system space because they are on /data
    if [ "$gapp_name" = "hangouts" ] || [ "$gapp_name" = "googleplus" ] || [ "$gapp_name" = "messenger" ] || [ "$gapp_name" = "photos" ] || [ "$gapp_name" = "street" ] || [ "$gapp_name" = "youtube" ]; then
        total_appsize=0;
    fi'
    DATAINSTALLCODE='
kitkatdata_folder_extract() {
  number="$(basename "$(find "/data/app/$3-"* | head -n1)" .apk | rev | cut -d- -f1)"
  if [ -z "$number" ]; then
    number="1"
  fi
  # On KitKat we know that these applications are arm and x86 and are using no fallbacks
  if [ -e "$TMP/GApps/$1.tar.xz" ]; then
    $TMP/xzdec-$BINARCH "$TMP/GApps/$1.tar.xz" | tar -x -C "$TMP" -f - "$2"
  elif [ -e "$TMP/GApps/$1.tar.lz" ]; then
    tar -xyf "$TMP/GApps/$1.tar.lz" -C "$TMP" "$2"
  elif [ -e "$TMP/GApps/$1.tar" ]; then
    tar -xf "$TMP/GApps/$1.tar" -C "$TMP" "$2"
  fi
  cp -rf "$TMP/$2/app/$4" "/data/app/$3-$number.apk"
  rm -rf "$TMP/$2"
  if [ -e "$TMP/GApps/$1.tar.xz" ]; then
    $TMP/xzdec-$BINARCH "$TMP/GApps/$1.tar.xz" | tar -x -C "$TMP" -f - "$1/common"
    rm -f "$TMP/GApps/$1.tar.xz"
  elif [ -e "$TMP/GApps/$1.tar.lz" ]; then
    tar -xyf "$TMP/GApps/$1.tar.lz" -C "$TMP" "$1/common"
    rm -f "$TMP/GApps/$1.tar.lz"
  elif [ -e "$TMP/GApps/$1.tar" ]; then
    tar -xf "$TMP/GApps/$1.tar" -C "$TMP" "$1/common"
    rm -f "$TMP/GApps/$1.tar"
  fi
  cp -rf "$TMP/$1/common/lib"* "/data/app-lib/$3-$number/"
  set_perm 1000 1000 644 "/data/app/$3-$number.apk"
  set_perm_recursive 1000 1000 755 644 "/data/app-lib/$3-$number"
  rm -rf "$TMP/$1/common"
}

install -d /data/app/
install -d /data/app-lib/
# Handle broken lib configuration on KitKat by putting Hangouts on /data/
if ( contains "$gapps_list" "hangouts" ); then
  unzip -o "$OPENGAZIP" "GApps/hangouts-$arch.tar*" -d "$TMP"
  which_dpi "hangouts-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "hangouts-$arch" "$dpiapkpath" "com.google.android.talk" "Hangouts.apk"
  gapps_list=${gapps_list/hangouts}
fi
# Handle broken lib configuration on KitKat by putting Google+ on /data/
if ( contains "$gapps_list" "googleplus" ); then
  unzip -o "$OPENGAZIP" "GApps/googleplus-$arch.tar*" -d "$TMP"
  which_dpi "googleplus-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "googleplus-$arch" "$dpiapkpath" "com.google.android.apps.plus" "PlusOne.apk"
  gapps_list=${gapps_list/googleplus}
fi
# Handle broken lib configuration on KitKat by putting Messenger on /data/
if ( contains "$gapps_list" "messenger" ); then
  unzip -o "$OPENGAZIP" "GApps/messenger-$arch.tar*" -d "$TMP"
  which_dpi "messenger-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "messenger-$arch" "$dpiapkpath" "com.google.android.apps.messaging" "PrebuiltBugle.apk"
  gapps_list=${gapps_list/messenger}
fi
# Handle broken lib configuration on KitKat by putting Photos on /data/
if ( contains "$gapps_list" "photos" ); then
  unzip -o "$OPENGAZIP" "GApps/photos-$arch.tar*" -d "$TMP"
  which_dpi "photos-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "photos-$arch" "$dpiapkpath" "com.google.android.apps.photos" "Photos.apk"
  gapps_list=${gapps_list/photos}
fi
# Handle broken lib configuration on KitKat by putting StreetView on /data/
if ( contains "$gapps_list" "street" ); then
  unzip -o "$OPENGAZIP" "GApps/street-$arch.tar*" -d "$TMP"
  which_dpi "street-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "street-$arch" "$dpiapkpath" "com.google.android.street" "Street.apk"
  gapps_list=${gapps_list/street}
fi
# Handle broken lib configuration on KitKat by putting YouTube on /data/
if ( contains "$gapps_list" "youtube" ); then
  unzip -o "$OPENGAZIP" "GApps/youtube-$arch.tar*" -d "$TMP"
  which_dpi "youtube-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "youtube-$arch" "$dpiapkpath" "com.google.android.youtube" "YouTube.apk"
  gapps_list=${gapps_list/youtube}
fi'
  else
    DATASIZESCODE=""
    DATAINSTALLCODE=""
  fi
}

kitkatpathshack(){
  if [ "$API" -le "19" ]; then
    REMOVALSUFFIX=".apk"
    REMOVALBYPASS="
/system/lib/libjni_eglfence.so
/system/lib/libjni_filtershow_filters.so
/system/lib/libjni_latinime.so
/system/lib/libjni_tinyplanet.so
/system/lib/libjpeg.so
/system/lib/libWVphoneAPI.so
/system/priv-app/CalendarProvider.apk"
  else
    REMOVALSUFFIX=""
    REMOVALBYPASS=""
  fi
}

minapihack(){
  useminapi=""
  case "$package" in
    com.google.android.gms)
    if [ "$API" -ge "23" ]; then
      useminapi="23"
    elif [ "$API" -ge "21" ]; then
      useminapi="21"
    fi;; #for all other situations, not having a minimal API specified is OK
  esac
}

provisionremovalhack(){
  if [ "$API" -le "22" ]; then
    tee -a "$1" > /dev/null <<'EOFILE'
# On Pre-Marshmallow the Provision folder always has to be removed (it conflicts with SetupWizard)
aosp_remove_list="${aosp_remove_list}provision"$'\n';

EOFILE
  fi
}

systemlibhack(){
  case "$package" in
    com.google.android.webview) if [ "$API" -lt "23" ]; then #webview libs are only on /system/lib/ on pre-Marshmallow
                                  systemlib="true"
                                fi;;
#    com.android.chrome)         systemlib="true";; #normally chrome would also be systemwide, but currently we don't do this because it is complicated with it .so versioning
    *) systemlib="false";;
  esac
}

universalremoverhack(){
  if [ "$API" -le "19" ]; then
    tee -a "$1" > /dev/null <<'EOFILE'
                    1)  user_remove_folder_list="${user_remove_folder_list}$(find "$folder" -type f -iname "$testapk")"$'\n'; # Add found file to list
                        user_remove_folder_list="${user_remove_folder_list}$(printf "$(find "$folder" -type f -iname "$testapk")" | rev | cut -c 4- | rev)odex"$'\n'; # Add odex to list
EOFILE
  else
    tee -a "$1" > /dev/null <<'EOFILE'
                    1)  user_remove_folder_list="${user_remove_folder_list}$(dirname "$(find "$folder" -type f -iname "$testapk")")"$'\n'; # Add found folder to list
EOFILE
  fi
}

versionnamehack(){
  case "$package" in
    #the Drive/Docs/Sheets/Slides variate after the last dot per arch and dpi, so we only take the first 4 fields
    com.google.android.apps.docs*) versionname="$(echo "$versionname" | cut -d '.' -f 1-4)";;
    #the Fitness variate after the dash per dpi, so we only take before it
    com.google.android.apps.fitness) versionname="$(echo "$versionname" | cut -d '-' -f 1)";;
    #the Project FI variate after the dash per dpi, so we only take before it
    com.google.android.apps.tycho) versionname="$(echo "$versionname" | cut -d '-' -f 1)";;
    #the Google Search app variates after the 3 dots per SDK and after the 4th dot per arch, so we only take the first 3 fields
    com.google.android.googlequicksearchbox) versionname="$(echo "$versionname" | cut -d '.' -f 1-3)";;
  esac
}

api19hack(){
  # On KitKat there is only 1 kind of setupwizard without a product type
  if [ "$API" -le "19" ]; then
  gappscore="$gappscore
setupwizard"
  else
  gappscore="$gappscore
setupwizarddefault
setupwizardtablet"
  fi
}

api21hack(){
  if [ "$API" -ge "21" ]; then
    if [ "$ARCH" = "arm64" ]; then
      gappsnano="$gappsnano
hotword"
    fi
    gappsmini="$gappsmini
taggoogle"
    gappsstock="$gappsstock
contactsgoogle"
    miniremove="$miniremove
clockstock
tagstock"
  fi
}

api22hack(){
  if [ "$API" -ge "22" ]; then
    # Starting from API 22 configupdater is part of the core apps
    gappscore="$gappscore
configupdater"

    # On AOSP we only support Webview on 5.1+, stock Google ROMs support it on 5.0 too, but we're merging stock and fornexus
    gappsstock="$gappsstock
webviewgoogle"
    stockremove="$stockremove
webviewstock"
  fi
}

api23hack(){
  if [ "$API" -ge "23" ]; then
    gappspico="$gappspico
dialerframework
googletts
packageinstallergoogle"
    gappsmini="$gappsmini
calculatorgoogle"
    gappsstock="$gappsstock
dialergoogle"
    gappsstock_optional="$gappsstock_optional
cameragooglelegacy"

    webviewstocklibs='lib/$WebView_lib_filename
lib64/$WebView_lib_filename
' #on Marshmallow the AOSP WebViewlibs must be removed, since they are embedded in the Google WebView APK; this assumes also any pre-bundled Google WebView with the ROM uses embedded libs; use single quote to not replace variable names
    webviewgappsremove=""

  # On Marshmallow the regular Packageinstaller is used
  gappstvstock="$gappstvstock
packageinstallergoogle"
  else
    gappsmicro="$gappsmicro
googletts"
    webviewstocklibs="" # on non-Marshmallow the WebViewlibs should not be considered part of the Stock/AOSP WebView, since they are shared with the Google WebView
    webviewgappsremove="lib/libwebviewchromium.so
lib64/libwebviewchromium.so" #on non-Marshmallow the WebViewlibs are to be explictly included as a Google WebView file in gapps-remove.txt

  # On pre-Marshmallow TV Voiceinput and TV Packageinstaller exist
  gappstvstock="$gappstvstock
tvpackageinstallergoogle
tvvoiceinput"
  fi
}

sdkversionhacks(){
  case "$package" in
    com.android.facelock) if [ "$versioncode" = "23" ]; then sdkversion="23"; fi;;
    com.google.android.partnersetup) if [ "$versioncode" = "23" ]; then sdkversion="23"; fi;;
    *) ;;
  esac
}
