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
    echo '    A0001|bacon|find7) cameragoogle_compat=false;; # bacon or A0001=OnePlus One | find7=Oppo Find7 and Find7a'
  fi
}

camerav3compatibilityhack(){
  if [ "$API" -ge "23" ]; then
    echo '
# Google Camera fallback to Legacy if incompatible with new Camera API (not for cameragooglego)
case $newcamera_compat in
  false*) gapps_list=$(echo "$gapps_list" | sed -e "s/\bcameragoogle\b/cameragooglelegacy/"); log "Google Camera version" "Legacy";;
esac'
  fi
}

keyboardgooglenotremovehack(){
  if [ "$API" -le "19" ]; then
    echo '  sed -i "\:/system/app/LatinImeGoogle.apk:d" $gapps_removal_list;'
  else
    echo '  sed -i "\:/system/app/LatinImeGoogle:d" $gapps_removal_list;'
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
/system/app/LatinIME/lib/$arch/libjni_keyboarddecoder.so
/system/product/lib/libjni_latinimegoogle.so
/system/product/lib64/libjni_latinimegoogle.so
/system/product/app/LatinIME/lib/$arch/libjni_latinimegoogle.so
/system/product/lib/libjni_keyboarddecoder.so
/system/product/lib64/libjni_keyboarddecoder.so
/system/product/app/LatinIME/lib/$arch/libjni_keyboarddecoder.so'
    KEYBDLIBS='keybd_lib_google="libjni_latinimegoogle.so"
keybd_dec_google="libjni_keyboarddecoder.so"
keybd_lib_aosp="libjni_latinime.so"'
    # Only touch AOSP keyboard only if it is not removed
    KEYBDINSTALLCODE='# Install/Remove SwypeLibs
if ( ! contains "$gapps_list" "keyboardgoogle" ) && ( ! contains "$gapps_list" "keyboardgooglego" ); then
  if [ "$skipswypelibs" = "false" ]; then
    if [ "$substituteswypelibs" = "true" ]; then
      keybd_lib_target="$keybd_lib_aosp"
      # remove swypelibs and symlink if any
      rm -f "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_google"
      rm -f "/system/app/LatinIME/$libfolder/$arch/$keybd_dec_google"
      rm -f "/system/product/app/LatinIME/$libfolder/$arch/$keybd_lib_google"
      rm -f "/system/product/app/LatinIME/$libfolder/$arch/$keybd_dec_google"
    else
      keybd_lib_target="$keybd_lib_google"
      # relink aosp as the normal link
      ln -sfn "/system/$libfolder/$keybd_lib_aosp" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp"
      ln -sfn "/system/product/$libfolder/$keybd_lib_aosp" "/system/product/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp"
    fi
    ui_print "- Installing swypelibs"
    extract_app "Optional/swypelibs-lib-$arch"  # Keep it simple, swypelibs is only lib-$arch
    install -d "/system/app/LatinIME/$libfolder/$arch"
    # create required symlinks
    ln -sfn "/system/$libfolder/$keybd_lib_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_target"
    ln -sfn "/system/$libfolder/$keybd_dec_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_dec_google"
    ln -sfn "/system/product/$libfolder/$keybd_lib_google" "/system/product/app/LatinIME/$libfolder/$arch/$keybd_lib_target"
    ln -sfn "/system/product/$libfolder/$keybd_dec_google" "/system/product/app/LatinIME/$libfolder/$arch/$keybd_dec_google"

    # Add same code to backup script to ensure symlinks are recreated on addon.d restore
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/$libfolder/$keybd_dec_google\" \"\$SYS/app/LatinIME/$libfolder/$arch/$keybd_dec_google\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/$libfolder/$keybd_lib_google\" \"\$SYS/app/LatinIME/$libfolder/$arch/$keybd_lib_target\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/product/$libfolder/$keybd_dec_google\" \"\$SYS/product/app/LatinIME/$libfolder/$arch/$keybd_dec_google\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/product/$libfolder/$keybd_lib_google\" \"\$SYS/product/app/LatinIME/$libfolder/$arch/$keybd_lib_target\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    install -d \"\$SYS/app/LatinIME/$libfolder/$arch\"" $bkup_tail
  else
    ui_print "- Removing swypelibs"
    # remove swypelibs and symlink if any
    rm -f "/system/$libfolder/$keybd_lib_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_google"
    rm -f "/system/$libfolder/$keybd_dec_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_dec_google"
    rm -f "/system/product/$libfolder/$keybd_lib_google" "/system/product/app/LatinIME/$libfolder/$arch/$keybd_lib_google"
    rm -f "/system/product/$libfolder/$keybd_dec_google" "/system/product/app/LatinIME/$libfolder/$arch/$keybd_dec_google"
    # restore non-swypelibs symlink
    ln -sfn "/system/$libfolder/$keybd_lib_aosp" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp"
    ln -sfn "/system/product/$libfolder/$keybd_lib_aosp" "/system/product/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp"
  fi
fi'
  elif [ "$API" -gt "19" ]; then # on Lollipop there are symlinks in /LatinIME/lib/ and we don't need to remove the aosp lib
    case "$ARCH" in #only arm-based platforms have swypelibs on Lollipop
    arm*)
      gappscore_optional="swypelibs $gappscore_optional"
      REQDLIST='/system/lib/libjni_latinimegoogle.so
/system/lib64/libjni_latinimegoogle.so
/system/app/LatinIME/lib/$arch/libjni_latinimegoogle.so
/system/product/lib/libjni_latinimegoogle.so
/system/product/lib64/libjni_latinimegoogle.so
/system/product/app/LatinIME/lib/$arch/libjni_latinimegoogle.so'
      KEYBDLIBS='keybd_lib_google="libjni_latinimegoogle.so"
keybd_lib_aosp="libjni_latinime.so"'
      # Only touch AOSP keyboard only if it is not removed
      KEYBDINSTALLCODE='# Install/Remove SwypeLibs
if ( ! contains "$gapps_list" "keyboardgoogle" ) && ( ! contains "$gapps_list" "keyboardgooglego" ); then
  if [ "$skipswypelibs" = "false" ]; then
    if [ "$substituteswypelibs" = "true" ]; then
      keybd_lib_target="$keybd_lib_aosp"
      # remove swypelibs and symlink if any
      rm -f "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_google"
      rm -f "/system/product/app/LatinIME/$libfolder/$arch/$keybd_lib_google"
    else
      keybd_lib_target="$keybd_lib_google"
      # relink aosp as the normal link
      ln -sfn "/system/$libfolder/$keybd_lib_aosp" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp"
      ln -sfn "/system/product/$libfolder/$keybd_lib_aosp" "/system/product/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp"
    fi
    ui_print "- Installing swypelibs"
    extract_app "Optional/swypelibs-lib-$arch"  # Keep it simple, swypelibs is only lib-$arch
    install -d "/system/app/LatinIME/$libfolder/$arch"
    # create required symlinks
    ln -sfn "/system/$libfolder/$keybd_lib_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_target"
    ln -sfn "/system/product/$libfolder/$keybd_lib_google" "/system/product/app/LatinIME/$libfolder/$arch/$keybd_lib_target"

    # Add same code to backup script to ensure symlinks are recreated on addon.d restore
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/$libfolder/$keybd_lib_google\" \"\$SYS/app/LatinIME/$libfolder/$arch/$keybd_lib_target\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/product/$libfolder/$keybd_lib_google\" \"\$SYS/product/app/LatinIME/$libfolder/$arch/$keybd_lib_target\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    install -d \"\$SYS/app/LatinIME/$libfolder/$arch\"" $bkup_tail
  else
    ui_print "- Removing swypelibs"
    # remove swypelibs and symlink if any
    rm -f "/system/$libfolder/$keybd_lib_google" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_google"
    rm -f "/system/product/$libfolder/$keybd_lib_google" "/system/product/app/LatinIME/$libfolder/$arch/$keybd_lib_google"
    # restore non-swypelibs symlink
    ln -sfn "/system/$libfolder/$keybd_lib_aosp" "/system/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp"
    ln -sfn "/system/product/$libfolder/$keybd_lib_aosp" "/system/product/app/LatinIME/$libfolder/$arch/$keybd_lib_aosp"
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
/system/lib/libjni_latinimegoogle.so
/system/product/lib/libjni_latinime.so
/system/product/lib/libjni_latinimegoogle.so"
        KEYBDLIBS='keybd_lib_google="libjni_latinimegoogle.so"
keybd_lib_aosp="libjni_latinime.so"'
        # Only touch AOSP keyboard only if it is not removed
        KEYBDINSTALLCODE='# Install/Remove SwypeLibs
if ( ! contains "$gapps_list" "keyboardgoogle" ) && ( ! contains "$gapps_list" "keyboardgooglego" ); then
  if [ "$skipswypelibs" = "false" ]; then
    ui_print "- Installing swypelibs"
    extract_app "Optional/swypelibs-lib-$arch"  # Keep it simple, swypelibs is only lib-$arch
    # create required symlinks
    ln -sfn "/system/$libfolder/$keybd_lib_google" "/system/$libfolder/$keybd_lib_aosp"
    ln -sfn "/system/product/$libfolder/$keybd_lib_google" "/system/product/$libfolder/$keybd_lib_aosp"

    # Add same code to backup script to ensure symlinks are recreated on addon.d restore
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/$libfolder/$keybd_lib_google\" \"\$SYS/$libfolder/$keybd_lib_aosp\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/product/$libfolder/$keybd_lib_google\" \"\$SYS/product/$libfolder/$keybd_lib_aosp\"" $bkup_tail
  else
    ui_print "- Removing swypelibs"
    # remove swypelibs
    rm -f "/system/$libfolder/$keybd_lib_google"
    rm -f "/system/product/$libfolder/$keybd_lib_google"
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
    if [ "$gapp_name" = "hangouts" ] || [ "$gapp_name" = "messenger" ] || [ "$gapp_name" = "photos" ] || [ "$gapp_name" = "street" ] || [ "$gapp_name" = "youtube" ]; then
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
# Handle broken lib configuration on KitKat by putting Google Messages on /data/
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

launcherhack(){
  if [ "$API" -ge "28" ]; then
    cat <<'EOFILE'
# If we're installing the pixel launcher overlay apk we must ADD launcher to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "pixellauncher" ) && ( ! contains "$aosp_remove_list" "launcher" ); then
  aosp_remove_list="${aosp_remove_list}launcher"$'\n'
fi
EOFILE
  fi
}

minapihack(){
  useminapi=""
  case "$package" in
    com.google.android.dialer)
      if [ "$API" -ge "24" ]; then
        useminapi="24"
      fi;;
    com.google.android.gms)
      if [ "$API" -ge "23" ]; then
        useminapi="23"
      elif [ "$API" -ge "21" ]; then
        useminapi="21"
      fi;;
    com.android.chrome)
      if [ "$ARCH" = "arm64" ] && [ "$API" -ge "29" ]; then # for now only available on arm64
        useminapi="29"
      elif [ "$API" -ge "24" ]; then
        useminapi="24"
      elif [ "$API" -ge "21" ]; then
        useminapi="21"
      fi;;
    com.google.android.webview)
      if [ "$ARCH" = "arm64" ] && [ "$API" -ge "29" ]; then # for now only available on arm64
        useminapi="29"
      elif [ "$API" -ge "21" ]; then
        useminapi="21"
      fi;;
    com.google.android.googlequicksearchbox)
      if [ "$ARCH" = "arm64" ] && [ "$API" -ge "29" ]; then # for now only available on arm64
        useminapi="29"
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
    cat <<'EOFILE'
                    1)  user_remove_folder_list="${user_remove_folder_list}$(find "$folder" -type f -iname "$testapk")$newline"; # Add found file to list
                        user_remove_folder_list="${user_remove_folder_list}$(printf "$(find "$folder" -type f -iname "$testapk")" | rev | cut -c 4- | rev)odex$newline"; # Add odex to list
EOFILE
  else
    cat <<'EOFILE'
                    1)  user_remove_folder_list="${user_remove_folder_list}$(dirname "$(find "$folder" -type f -iname "$testapk")")$newline"; # Add found folder to list
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
  if [ "$API" -ge "29" ]; then
    cat <<'EOFILE'
# If we're installing webviewgoogle we MUST ADD webviewstub to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "webviewgoogle" ) && ( ! contains "$aosp_remove_list" "webviewstub" ); then
  aosp_remove_list="${aosp_remove_list}webviewstub$newline"
fi;

# If we're installing webviewstub we MUST ADD webviewgoogle to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "webviewstub" ) && ( ! contains "$aosp_remove_list" "webviewgoogle" ); then
  aosp_remove_list="${aosp_remove_list}webviewgoogle$newline"
fi;

# If we're installing webviewgoogle OR webviewstub we PREFER TO ADD webviewstock to $aosp_remove_list (if it's not already there)
if ( ( contains "$gapps_list" "webviewgoogle" ) || ( contains "$gapps_list" "webviewstub" ) ) && ( ! contains "$aosp_remove_list" "webviewstock" ); then
  aosp_remove_list="${aosp_remove_list}webviewstock$newline"
fi

# If we're NOT installing webviewgoogle OR webviewstub and webviewstock is in $aosp_remove_list then user must override removal protection
# Chrome is not there since on Android 10+ it's not a webview provider anymore
if ( ! contains "$gapps_list" "webviewgoogle" ) && ( ! contains "$gapps_list" "webviewstub" ) && ( contains "$aosp_remove_list" "webviewstock" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/webviewstock} # we'll prevent webviewstock from being removed so user isn't left with no WebView
  install_note="${install_note}nowebview_msg$newline" # make note that Stock Webview can't be removed unless user Overrides
fi
EOFILE
  elif [ "$API" -ge "24" ]; then
    cat <<'EOFILE'
# If we're installing chrome and webviewgoogle, replace it with webviewstub unless override removal protection
if ( contains "$gapps_list" "chrome" ) && ( contains "$gapps_list" "webviewgoogle" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
  gapps_list=${gapps_list/webviewgoogle/webviewstub}
  install_note="${install_note}stubwebview_msg$newline" # make note that Stub Webview unless user Overrides
fi

# If we're installing webviewgoogle we MUST ADD webviewstub to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "webviewgoogle" ) && ( ! contains "$aosp_remove_list" "webviewstub" ); then
  aosp_remove_list="${aosp_remove_list}webviewstub$newline"
fi;

# If we're installing webviewstub we MUST ADD webviewgoogle to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "webviewstub" ) && ( ! contains "$aosp_remove_list" "webviewgoogle" ); then
  aosp_remove_list="${aosp_remove_list}webviewgoogle$newline"
fi;

# If we're installing webviewgoogle OR webviewstub we PREFER TO ADD webviewstock to $aosp_remove_list (if it's not already there)
if ( ( contains "$gapps_list" "webviewgoogle" ) || ( contains "$gapps_list" "webviewstub" ) ) && ( ! contains "$aosp_remove_list" "webviewstock" ); then
  aosp_remove_list="${aosp_remove_list}webviewstock$newline"
fi

# If we're NOT installing webviewgoogle OR webviewstub OR chrome and webviewstock is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "webviewgoogle" ) && ( ! contains "$gapps_list" "webviewstub" ) && ( ! contains "$gapps_list" "chrome" ) && ( contains "$aosp_remove_list" "webviewstock" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/webviewstock} # we'll prevent webviewstock from being removed so user isn't left with no WebView
  install_note="${install_note}nowebview_msg$newline" # make note that Stock Webview can't be removed unless user Overrides
fi
EOFILE
  else
    cat <<'EOFILE'
# If we're installing webviewgoogle we SHOULD ADD webviewstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "webviewgoogle" ) && ( ! contains "$aosp_remove_list" "webviewstock" ); then
  aosp_remove_list="${aosp_remove_list}webviewstock$newline"
fi

# If we're NOT installing webviewgoogle and webviewstock is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "webviewgoogle" ) && ( contains "$aosp_remove_list" "webviewstock" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/webviewstock}; # we'll prevent webviewstock from being removed so user isn't left with no WebView
  install_note="${install_note}nowebview_msg$newline" # make note that Stock Webview can't be removed unless user Overrides
fi
EOFILE
  fi
}

webviewignorehack(){
  if [ "$API" -ge "24" ]; then
    cat <<'EOFILE'
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
    install_note="${install_note}nogooglewebview_removal_msg$newline"; # make note that Google WebView will not be removed
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
    cat <<'EOFILE'
if [ "$ignoregooglewebview" = "true" ]; then  # No AOSP WebView
  if ( ! contains "$gapps_list" "webviewgoogle" ) && ( ! grep -qiE '^override$' "$g_conf" ); then  # Don't remove Google WebView components if no other WebViewProvider installed
    sed -i "\:/system/lib/$WebView_lib_filename:d" $gapps_removal_list;
    sed -i "\:/system/lib64/$WebView_lib_filename:d" $gapps_removal_list;
    sed -i "\:/system/app/WebViewGoogle:d" $gapps_removal_list;
    ignoregooglewebview="true[NoRemove]"
    install_note="${install_note}nogooglewebview_removal_msg$newline"; # make note that Google WebView will not be removed
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

androidautohack(){
  if [ "$API" -ge "30" ]; then
    cat <<'EOFILE'
# If we're installing androidauto we MUST ADD gearheadstub to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "androidauto" ) && ( ! contains "$aosp_remove_list" "gearheadstub" ); then
  aosp_remove_list="${aosp_remove_list}gearheadstub$newline"
fi

# If we're installing gearheadstub we MUST ADD androidauto to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "gearheadstub" ) && ( ! contains "$aosp_remove_list" "androidauto" ); then
  aosp_remove_list="${aosp_remove_list}androidauto$newline"
fi

# If we're installing androidauto AND gearheadstub we MUST REMOVE gearheadstub from $gapps_list (since it's not required)
if ( contains "$gapps_list" "gearheadstub" ) && ( contains "$gapps_list" "androidauto" ); then
  gapps_list=${gapps_list/gearheadstub}
fi
EOFILE
  fi
}

api19hack(){
  if [ "$API" -le "19" ]; then
    if [ "$API" -eq "19" ]; then
      gappscore="$gappscore
gsflogin
setupwizard"  # On KitKat there is only 1 kind of setupwizard without a product type
      gappsmicro="$gappsmicro
googlenow"
    fi
  else
    gappscore="$gappscore
setupwizarddefault
setupwizardtablet"
  fi
}

api21hack(){
  if [ "$API" -lt "21" ]; then
    gappsfull="$gappsfull
music"
  else
    if [ "$API" -eq "21" ]; then
      gappscore="$gappscore
gmssetup
gsflogin"
    fi
    gappsmini="$gappsmini
calculatorgoogle
taggoogle"
    gappsmicro="$gappsmicro
pixellauncher
wallpapers"
    gappsstock="$gappsstock
androidauto
contactsgoogle"
    gappsfull="$gappsfull
ytmusic"
    miniremove="$miniremove
clockstock
tagstock"
  fi
}

api22hack(){
  if [ "$API" -ge "22" ]; then
    if [ "$API" -eq "22" ]; then
      gappscore="$gappscore
gsflogin"
      fi
    gappscore="$gappscore
configupdater"  # Starting from API 22 configupdater is part of the core apps
    gappsstock="$gappsstock
webviewgoogle"  # On AOSP we only support Webview on 5.1+, stock Google ROMs support it on 5.0 too, but we're merging stock and fornexus
    gappssuper="$gappssuper
gcs"
    stockremove="$stockremove
webviewstock"
  fi
}

api23hack(){
  if [ "$API" -ge "23" ]; then
    if [ "$API" -eq "23" ]; then
      gappscore="$gappscore
gsflogin"
    fi
    gappspico="$gappspico
dialerframework
googletts"
    if [ "$API" -eq "23" ]; then
      gappspico="$gappspico
packageinstallergoogle"  # TODO: packageinstallergoogle temporary disabled because of issues on Nougat ROMs
    fi
    gappsmini="$gappsmini
carrierservices"
    gappsstock="$gappsstock
dialergoogle"
    gappsstock_optional="$gappsstock_optional
cameragooglelegacy"
    webviewstocklibs='lib/$WebView_lib_filename
lib64/$WebView_lib_filename
product/lib/$WebView_lib_filename
product/lib64/$WebView_lib_filename
'  # On Marshmallow the AOSP WebViewlibs must be removed, since they are embedded in the Google WebView APK; this assumes also any pre-bundled Google WebView with the ROM uses embedded libs; use single quote to not replace variable names
    webviewgappsremove=""
  gappstvstock="$gappstvstock
packageinstallergoogle"  # On AndroidTV 6.0+ packageinstallergoogle is also installed (next to the tvpackageinstallergoogle)
  else
    gappsmicro="$gappsmicro
googletts"
    webviewstocklibs=""  # On non-Marshmallow the WebViewlibs should not be considered part of the Stock/AOSP WebView, since they are shared with the Google WebView
    webviewgappsremove="lib/libwebviewchromium.so
lib64/libwebviewchromium.so
product/lib/libwebviewchromium.so
product/lib64/libwebviewchromium.so"  # On non-Marshmallow the WebViewlibs are to be explictly included as a Google WebView file in gapps-remove.txt
  gappstvstock="$gappstvstock
tvvoiceinput"  # On pre-Marshmallow TV Voiceinput exists
  fi
}

api24hack(){
  if [ "$API" -ge "24" ]; then
    if [ "$API" -eq "24" ]; then
      gappscore="$gappscore
gmssetup
gsflogin"
    fi
    gappscore="$gappscore
extservicesgoogle
extsharedgoogle"
    gappsstock="$gappsstock
printservicegoogle
storagemanagergoogle"
    gappstvcore="$gappstvcore
extservicesgoogle
extsharedgoogle"
    gappstvstock="$gappstvstock
leanbackrecommendations"  # On Android 7.0+ the TV Recommendations exist
    gappsstock_optional="$gappsstock_optional
webviewstub"  # On Nougat and higher we might want to install the WebViewStub instead of WebViewGoogle in some situations
  if [ "$ARCH" = "arm" ] || [ "$ARCH" = "arm64" ]; then  # for now only available on arm & arm64
    gappsfull_optional="$gappsfull_optional
moviesvrmode"
  fi
  if [ "$ARCH" = "arm64" ]; then # for now only available on arm64
    gappsmini_optional="$gappsmini_optional
photosvrmode"
  fi
  fi
}

api25hack(){
  if [ "$API" -ge "25" ]; then
    if [ "$API" -eq "25" ]; then
      gappscore="$gappscore
gsflogin"
      gappsmicro="$gappsmicro
pixelicons"
    fi
    gappsnano="$gappsnano
batteryusage"
  fi
}

api26hack(){
  if [ "$API" -ge "26" ]; then
    if [ "$ARCH" = "arm64" ] && [ "$API" -eq "26" ]; then
      gappscore="$gappscore
platformservicesoreo"  # Include Android 8.0 specific Platform Services with Android 8.0
    fi
    if [ "$API" -eq "26" ]; then
      gappscore="$gappscore
gmssetup"
    fi
    gappscore="$gappscore
carriersetup"
    gappspico="$gappspico
packageinstallergoogle"
    gappstvmini="$gappstvmini
setupwraith
tvlauncher
tvrecommendations"  # On Android 8.0+ a different launcher exists. SuW also works without needing platform signed
  fi
}

api27hack(){
  if [ "$API" -eq "27" ]; then
    gappscore="$gappscore
gmssetup"
  fi
}

api28hack(){
  if [ "$API" -ge "28" ]; then
    if [ "$API" -eq "28" ]; then  # It is in micro starting from API 29
      gappssuper="$gappssuper
actionsservices"
    fi
    if [ "$ARCH" = "arm64" ] && [ "$API" -eq "28" ]; then
      gappsnano="$gappsnano
platformservices"  # Include Android Platform Services only for arm64 Android 9.0
    fi
    gappscore="$gappscore
backuprestore
datatransfertool"
    gappsnano="$gappsnano
markup
soundpicker
wellbeing"
    gappsfull="$gappsfull
recorder"
    gappssuper="$gappssuper
bettertogether"
    gappstvcore="$gappstvcore
calsync
googlepartnersetup
googleonetimeinitializer"
  fi

  if [ "$API" -lt "28" ]; then
    gappstvcore="$gappstvcore
notouch
tvframework
secondscreensetup
secondscreenauthbridge
tvpackageinstallergoogle" # Several atv packages were removed in Android 9.0
  fi
}

api29hack(){
  if [ "$API" -ge "29" ]; then
    gappspico="$gappspico
gearheadstub"  # Include Android Auto stub file with Android 10.0+
    if [ "$ARCH" = "arm64" ]; then # for now only available on arm64
      gappsfull="$gappsfull
trichromelibrary"
    fi
    gappsmicro="$gappsmicro
actionsservices" # Include Actions Services with Android 10.0 for Pixel Launcher to work
  fi
}

api30hack(){
  if [ "$API" -ge "30" ]; then
    gappsmicro="$gappsmicro
quickaccesswallet" # Include QuickAccessWallet with Android 11.0 for Pixel Launcher to work
  fi
}

api31hack(){
  if [ "$API" -eq "31" ]; then
    continue # Nothing to add yet.
  fi
}

api32hack(){
  if [ "$API" -eq "32" ]; then
    continue # Nothing to add yet.
  fi
}

sdkversionhacks(){
  case "$package" in
    com.google.android.configupdater|com.google.android.feedback|com.google.android.gsf.login|com.google.android.partnersetup|com.google.android.setupwizard|com.google.android.syncadapters.contacts)
      case "$versioncode" in
        *23) sdkversion="23";;
        *24) sdkversion="24";;
        *25) sdkversion="25";;
        *26) sdkversion="26";;
        *27) sdkversion="27";;
        *28) sdkversion="28";;
        *29) sdkversion="29";;
        *30) sdkversion="30";;
        *31) sdkversion="31";;
        *32) sdkversion="32";;
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

gohack(){
  if [ "$API" -ge "27" ]; then
    gappscore_go=$gappscore
    gappscore_go_optional=$gappscore_optional
    gappspico_go=$gappspico
    gappsnano_go=$gappsnano
    gappsmicro_go=$gappsmicro
    gappsmini_go=$gappsmini
    gappsmini_go_optional=$gappsmini_optional
    gappsfull_go=$gappsfull
    gappsfull_go_optional=$gappsfull_optional
    gappsstock_go=$gappsstock
    gappsstock_go_optional=$gappsstock_optional

    gappscore_go=$(sed -e "s/\bdefaultetc\b/defaultetcgo/" <<< $gappscore_go)

    # -= Google GMS mandatory core packages =-
    #gappspico_go=$(sed -e "s/\bgearheadstub\b//" <<< $gappspico_go) # Remove AndroidAutoStub
    gappscore_go=$(sed -e "s/\bgmscore\b/gmscorego/" <<< $gappscore_go)

    # -= Google GMS mandatory application packages =-
    #Remove Drive, Photos, Velvet, YTMusic, Videos
    #Add AssistantGo, NavGo, GalleryGo, GoogleSearchGo
    #Replace Duo, Gmail, Maps, LatinImeGoogle
    #Keep YouTube

    gappsstock_go=$(sed -e "s/\bduo\b/duogo/" <<< $gappsstock_go)
    gappsmini_go=$(sed -e "s/\bphotos\b/gallerygo/" <<< $gappsmini_go) # Should also replace Gallery2
    gappsmicro_go=$(sed -e "s/\bgmail\b/gmailgo/" <<< $gappsmicro_go)
    gappsstock_go=$(sed -e "s/\bkeyboardgoogle\b/keyboardgooglego/" <<< $gappsstock_go)
    gappsmini_go=$(sed -e "s/\bmaps\b/mapsgo/" <<< $gappsmini_go)
    gappsmini_go="$gappsmini_go
navgo"

    # We replace Velvet (ie. search) by searchgo & google assistant go (as done in the GMS sources, which replaces Velvet (aka QuickSearchBox)
    gappsnano_go=$(sed -e "s/\bsearch\b/searchgo assistantgo/" <<< $gappsnano_go)

    # Personal addition: YouTubeGo (not listed in GMS packages in 12.0, but present)
    gappsmini_go="$gappsmini_go
youtubego"

    # CameraGo: Remove cameragooglelegacy & cameragoogle
    gappsstock_go_optional=$(sed -e "s/\bcameragooglelegacy\b//" <<< $gappsstock_go_optional)
    gappsstock_go=$(sed -e "s/\bcameragoogle\b/cameragooglego/" <<< $gappsstock_go)

    # -= Google Comms Suite =-
    if [ "$VARIANT" = "stock_go" ]; then
      #Remove : com.google.android.dialer.support.jar only if we replace dialergoogle by dialergooglego
      gappspico_go=$(sed -e "s/\bdialerframework\b//" <<< $gappspico_go)
    fi
    gappsstock_go=$(sed -e "s/\bdialergoogle\b/dialergooglego/" <<< $gappsstock_go)
    gappsmini_go=$(sed -e "s/\bmessenger\b/messengergo/" <<< $gappsmini_go)

    # -= Google GMS optional application packages =-
    # Add: FilesGoogle ; Remove: Keep
    gappsfull_go="$gappsfull_go
files"
    gappsfull_go=$(sed -e "s/\bkeep\b//" <<< $gappsfull_go)

    gappssuper="$gappssuper
gmscorego
assistantgo
duogo
gallerygo
gmailgo
keyboardgooglego
mapsgo
navgo
searchgo
youtubego
cameragooglego
dialergooglego
messengergo
files
"
  fi
}
