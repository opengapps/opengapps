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

keyboardgooglenotremovehack(){
  if [ "$API" -le "19" ]; then
    echo '  sed -i "\:/system/app/LatinImeGoogle.apk:d" $gapps_removal_list;'>> "$1"
  else
    echo '  sed -i "\:/system/app/LatinImeGoogle:d" $gapps_removal_list;'>> "$1"
  fi
}

keyboardlibhack(){
  #if [ "$API" -ge "24" ]; then # on Nougat there are officially no swypelibs, but we can use the Marshmallow ones for now, they are still AOSP compatible
  #  REQDLIST=""
  #  KEYBDLIBS=""
  #  KEYBDINSTALLCODE=""
  #el
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
    ui_print "- Removing swypelibs"
    rm -f "/system/$libfolder/$keybd_lib_google" # remove swypelibs
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
    "$TMP/xzdec-$BINARCH" "$TMP/GApps/$1.tar.xz" | tar -x -C "$TMP" -f - "$2"
  elif [ -e "$TMP/GApps/$1.tar.lz" ]; then
    "$TMP/tar-$BINARCH" -xf "$TMP/GApps/$1.tar.lz" -C "$TMP" "$2"
  elif [ -e "$TMP/GApps/$1.tar" ]; then
    "$TMP/tar-$BINARCH" -xf "$TMP/GApps/$1.tar" -C "$TMP" "$2"
  fi
  cp -rf "$TMP/$2/app/$4" "/data/app/$3-$number.apk"
  rm -rf "$TMP/$2"
  if [ -e "$TMP/GApps/$1.tar.xz" ]; then
    "$TMP/xzdec-$BINARCH" "$TMP/GApps/$1.tar.xz" | tar -x -C "$TMP" -f - "$1/common"
    rm -f "$TMP/GApps/$1.tar.xz"
  elif [ -e "$TMP/GApps/$1.tar.lz" ]; then
    "$TMP/tar-$BINARCH" -xyf "$TMP/GApps/$1.tar.lz" -C "$TMP" "$1/common"
    rm -f "$TMP/GApps/$1.tar.lz"
  elif [ -e "$TMP/GApps/$1.tar" ]; then
    "$TMP/tar-$BINARCH" -xf "$TMP/GApps/$1.tar" -C "$TMP" "$1/common"
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
  "$TMP/unzip-$BINARCH" -o "$OPENGAZIP" "GApps/hangouts-$arch.tar*" -d "$TMP"
  which_dpi "hangouts-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "hangouts-$arch" "$dpiapkpath" "com.google.android.talk" "Hangouts.apk"
  gapps_list=${gapps_list/hangouts}
fi
# Handle broken lib configuration on KitKat by putting Google+ on /data/
if ( contains "$gapps_list" "googleplus" ); then
  "$TMP/unzip-$BINARCH" -o "$OPENGAZIP" "GApps/googleplus-$arch.tar*" -d "$TMP"
  which_dpi "googleplus-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "googleplus-$arch" "$dpiapkpath" "com.google.android.apps.plus" "PlusOne.apk"
  gapps_list=${gapps_list/googleplus}
fi
# Handle broken lib configuration on KitKat by putting Messenger on /data/
if ( contains "$gapps_list" "messenger" ); then
  "$TMP/unzip-$BINARCH" -o "$OPENGAZIP" "GApps/messenger-$arch.tar*" -d "$TMP"
  which_dpi "messenger-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "messenger-$arch" "$dpiapkpath" "com.google.android.apps.messaging" "PrebuiltBugle.apk"
  gapps_list=${gapps_list/messenger}
fi
# Handle broken lib configuration on KitKat by putting Photos on /data/
if ( contains "$gapps_list" "photos" ); then
  "$TMP/unzip-$BINARCH" -o "$OPENGAZIP" "GApps/photos-$arch.tar*" -d "$TMP"
  which_dpi "photos-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "photos-$arch" "$dpiapkpath" "com.google.android.apps.photos" "Photos.apk"
  gapps_list=${gapps_list/photos}
fi
# Handle broken lib configuration on KitKat by putting StreetView on /data/
if ( contains "$gapps_list" "street" ); then
  "$TMP/unzip-$BINARCH" -o "$OPENGAZIP" "GApps/street-$arch.tar*" -d "$TMP"
  which_dpi "street-$arch"  # Keep it simple, only 32 bit arch on kitkat and no weird libs for these apps
  kitkatdata_folder_extract "street-$arch" "$dpiapkpath" "com.google.android.street" "Street.apk"
  gapps_list=${gapps_list/street}
fi
# Handle broken lib configuration on KitKat by putting YouTube on /data/
if ( contains "$gapps_list" "youtube" ); then
  "$TMP/unzip-$BINARCH" -o "$OPENGAZIP" "GApps/youtube-$arch.tar*" -d "$TMP"
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
      fi;;
    com.android.chrome)
      if [ "$API" -ge "24" ]; then
        useminapi="24"
      elif [ "$API" -ge "21" ]; then
        useminapi="21"
      fi;;
  esac
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

webviewcheckhack(){
  if [ "$API" -ge "24" ]; then
    tee -a "$1" > /dev/null <<'EOFILE'
# If we're installing chrome and webviewgoogle, replace it with webviewstub unless override removal protection
if ( contains "$gapps_list" "chrome" ) && ( contains "$gapps_list" "webviewgoogle" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
  gapps_list=${gapps_list/webviewgoogle/webviewstub}
  install_note="${install_note}stubwebview_msg"$'\n' # make note that Stub Webview unless user Overrides
fi

# If we're installing webviewgoogle we MUST ADD webviewstub to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "webviewgoogle" ) && ( ! contains "$aosp_remove_list" "webviewstub" ); then
  aosp_remove_list="${aosp_remove_list}webviewstub"$'\n'
fi;

# If we're installing webviewstub we MUST ADD webviewgoogle to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "webviewstub" ) && ( ! contains "$aosp_remove_list" "webviewgoogle" ); then
  aosp_remove_list="${aosp_remove_list}webviewgoogle"$'\n'
fi;

# If we're installing webviewgoogle OR webviewstub we PREFER TO ADD webviewstock to $aosp_remove_list (if it's not already there)
# TODO in the future we could consider this behaviour even if installing just Chrome
if ( ( contains "$gapps_list" "webviewgoogle" ) || ( contains "$gapps_list" "webviewstub" ) ) && ( ! contains "$aosp_remove_list" "webviewstock" ); then
  aosp_remove_list="${aosp_remove_list}webviewstock"$'\n'
fi

# If we're NOT installing webviewgoogle OR webviewstub OR chrome and webviewstock is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "webviewgoogle" ) && ( ! contains "$gapps_list" "webviewstub" ) && ( ! contains "$gapps_list" "chrome" ) && ( contains "$aosp_remove_list" "webviewstock" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/webviewstock} # we'll prevent webviewstock from being removed so user isn't left with no WebView
  install_note="${install_note}nowebview_msg"$'\n' # make note that Stock Webview can't be removed unless user Overrides
fi
EOFILE
  else
    tee -a "$1" > /dev/null <<'EOFILE'
# If we're installing webviewgoogle we SHOULD ADD webviewstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "webviewgoogle" ) && ( ! contains "$aosp_remove_list" "webviewstock" ); then
  aosp_remove_list="${aosp_remove_list}webviewstock"$'\n'
fi

# If we're NOT installing webviewgoogle and webviewstock is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "webviewgoogle" ) && ( contains "$aosp_remove_list" "webviewstock" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/webviewstock}; # we'll prevent webviewstock from being removed so user isn't left with no WebView
  install_note="${install_note}nowebview_msg"$'\n' # make note that Stock Webview can't be removed unless user Overrides
fi
EOFILE
  fi
}

webviewignorehack(){
  if [ "$API" -ge "24" ]; then
    tee -a "$1" > /dev/null <<'EOFILE'
if [ "$ignoregooglewebview" = "true" ]; then  # No AOSP WebView
  if ( ! contains "$gapps_list" "webviewgoogle" ) && ( ! contains "$gapps_list" "webviewstub" ) && ( ! contains "$gapps_list" "chrome" ) && ( ! grep -qiE '^override$' "$g_conf" ); then  # Don't remove components if no other WebViewProvider installed
    if [ -d "/system/app/Chrome" ]; then
      sed -i "\:/system/app/Chrome:d" $gapps_removal_list;
      ignoregooglewebview="true[NoRemoveChrome]"
    elif [ -d "/system/app/WebviewGoogle" ]; then
      sed -i "\:/system/app/WebViewGoogle:d" $gapps_removal_list;
      ignoregooglewebview="true[NoRemoveGoogle]"
    elif [ -d "/system/app/WebviewStub" ]; then
      sed -i "\:/system/app/WebViewStub:d" $gapps_removal_list;
      ignoregooglewebview="true[NoRemoveStub]"
    fi
    install_note="${install_note}nogooglewebview_removal"$'\n'; # make note that Google WebView will not be removed
  elif ( contains "$gapps_list" "webviewgoogle" ); then  # No AOSP WebView, but Google WebView is being installed, no reason to protect the current components
    ignoregooglewebview="false[WebViewGoogle]"
  elif ( contains "$gapps_list" "webviewstub" ); then  # No AOSP WebView, but WebView Stub is being installed, no reason to protect the current components
    ignoregooglewebview="false[WebViewStub]"
  elif ( contains "$gapps_list" "chrome" ); then  # No AOSP WebView, but Chrome is being installed, no reason to protect the current components
    ignoregooglewebview="false[Chrome]"
  fi
fi
EOFILE
  else
    tee -a "$1" > /dev/null <<'EOFILE'
if [ "$ignoregooglewebview" = "true" ]; then  # No AOSP WebView
  if ( ! contains "$gapps_list" "webviewgoogle" ) && ( ! grep -qiE '^override$' "$g_conf" ); then  # Don't remove Google WebView components if no other WebViewProvider installed
    sed -i "\:/system/lib/$WebView_lib_filename:d" $gapps_removal_list;
    sed -i "\:/system/lib64/$WebView_lib_filename:d" $gapps_removal_list;
    sed -i "\:/system/app/WebViewGoogle:d" $gapps_removal_list;
    ignoregooglewebview="true[NoRemove]"
    install_note="${install_note}nogooglewebview_removal"$'\n'; # make note that Google WebView will not be removed
  else  # No AOSP WebView, but Google WebView is being installed, no reason to protect the current components
    ignoregooglewebview="false[WebViewGoogle]"
  fi
elif ( ! contains "$gapps_list" "webviewgoogle" ); then  # AOSP WebView, but no Google WebView being installed, make sure to protect the current AOSP components that share name with Google WebView components (Pre-Marshmallow)
  sed -i "\:/system/lib/$WebView_lib_filename:d" $gapps_removal_list;
  sed -i "\:/system/lib64/$WebView_lib_filename:d" $gapps_removal_list;
fi
EOFILE
  fi
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
    gappsmini="$gappsmini
calculatorgoogle
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
googletts"
    if [ "$API" -eq "23" ] || [ "$API" -ge "26" ] ; then
      gappspico="$gappspico
packageinstallergoogle"  
    fi # TODO packageinstallergoogle temporary disabled because of issues on Nougat ROMs
    gappsstock="$gappsstock
dialergoogle
pixellauncher"
    gappsstock_optional="$gappsstock_optional
cameragooglelegacy"

    gappssuper="$gappssuper
carrierservices"

    webviewstocklibs='lib/$WebView_lib_filename
lib64/$WebView_lib_filename
' #on Marshmallow the AOSP WebViewlibs must be removed, since they are embedded in the Google WebView APK; this assumes also any pre-bundled Google WebView with the ROM uses embedded libs; use single quote to not replace variable names
    webviewgappsremove=""

  # On AndroidTV 6.0+ packageinstallergoogle is also installed (next to the tvpackageinstallergoogle)
  gappstvstock="$gappstvstock
packageinstallergoogle"
  else
    gappsmicro="$gappsmicro
googletts"
    webviewstocklibs="" # on non-Marshmallow the WebViewlibs should not be considered part of the Stock/AOSP WebView, since they are shared with the Google WebView
    webviewgappsremove="lib/libwebviewchromium.so
lib64/libwebviewchromium.so" #on non-Marshmallow the WebViewlibs are to be explictly included as a Google WebView file in gapps-remove.txt

  # On pre-Marshmallow TV Voiceinput exists
  gappstvstock="$gappstvstock
tvvoiceinput"
  fi
}

api24hack(){
  if [ "$API" -ge "24" ]; then
    gappscore="$gappscore
extservicesgoogle
extsharedgoogle"
    gappsstock="$gappsstock
printservicegoogle
storagemanagergoogle"

    gappstvcore="$gappstvcore
extservicesgoogle
extsharedgoogle"
    # On Nougat and higher the TV Recommendations exist
    gappstvstock="$gappstvstock
leanbackrecommendations"
    # On Nougat and higher we might want to install the WebViewStub instead of WebViewGoogle in some situations
    gappsstock_optional="$gappsstock_optional
webviewstub"

  if [ "$ARCH" = "arm" ] || [ "$ARCH" = "arm64" ]; then  # for now only available on arm & arm64
    gappsfull_optional="$gappsfull_optional
moviesvrmode"
  fi
  if [ "$ARCH" = "arm64" ]; then  # for now only available on arm64
    gappsmini_optional="$gappsmini_optional
photosvrmode"
  fi
  fi
}

api25hack(){
  if [ "$API" -ge "25" ]; then
    gappsnano="$gappsnano
batteryusage"
    gappsstock="$gappsstock
pixelicons"
  fi
}

api26hack(){
  if [ "$API" -eq "26" ]; then
    if [ "$ARCH" = "arm64" ]; then  # for now only available on arm64
      gappscore="$gappscore
androidplatformservices"
    fi
    # On Oreo and higher a different launcher exists
    # Also, the suw works without needing platform signed
    gappstvstock="$gappstvstock
setupwraith
tvlauncher
tvrecommendations"
  else
    gappscore="$gappscore
gsflogin"
  fi
}

# Does nothing now, here for completeness
api27hack(){
  if [ "$API" -eq "27" ]; then
    if [ "$ARCH" = "arm64" ]; then  # for now only available on arm64
      gappscore="$gappscore"
    fi
  else
    gappscore="$gappscore"
  fi
}

# Does nothing now, here for completeness
api28hack(){
  if [ "$API" -ge "28" ]; then
    if [ "$ARCH" = "arm64" ]; then  # for now only available on arm64
      gappssuper="$gappssuper
markup"
    fi
    gappscore="$gappscore
androidplatformservices
datatransfertool"
    gappssuper="$gappssuper
actionsservices
bettertogether
soundpicker
wellbeing"
  fi
}

sdkversionhacks(){
  case "$package" in
    com.android.facelock|com.google.android.configupdater|com.google.android.feedback|com.google.android.gsf.login|com.google.android.partnersetup|com.google.android.setupwizard|com.google.android.syncadapters.contacts)
      case "$versioncode" in
        *23) sdkversion="23";;
        *24) sdkversion="24";;
        *25) sdkversion="25";;
        *26) sdkversion="26";;
        *27) sdkversion="27";;
        *28) sdkversion="28";;
        *) ;;
      esac;;
  esac
}

compressioncompathack(){
  if [ "$API" -eq "23" ]; then
    case "$1" in
      googlecontactssync*) compression="none";;  # Googlecontactssync for Marshmallow extraction is broken with compression, so use a plain tar instead
    esac
  fi
}
