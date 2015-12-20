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
    echo '    A0001|bacon|find7) cameragoogle_compat=false;; # bacon or A0001=OnePlus One | find7=Oppo Find7 and Find7a' >> "$build/META-INF/com/google/android/update-binary"
  fi
}

keyboardgooglenotremovehack(){
  if [ "$API" -le "19" ]; then
    echo '  sed -i "\:/system/app/LatinImeGoogle.apk:d" $gapps_removal_list;'>> "$build/META-INF/com/google/android/update-binary"
  else
    echo '  sed -i "\:/system/app/LatinImeGoogle:d" $gapps_removal_list;'>> "$build/META-INF/com/google/android/update-binary"
  fi
}

keyboardlibhack(){
  case "$ARCH" in #only arm based platforms we have swypelibs
    arm*) gappsoptional="swypelibs $gappsoptional"
          if [ "$API" -gt "19" ]; then # on Lollipop there are symlinks in /LatinIME/lib/ and we don't need to remove the aosp lib
            REQDLIST="/system/lib/libjni_latinimegoogle.so
/system/lib64/libjni_latinimegoogle.so
/system/app/LatinIME/lib/$ARCH/libjni_latinimegoogle.so"
            KEYBDLIBS='keybd_lib_google="libjni_latinimegoogle.so";'
            # Only touch AOSP keyboard only if it is not removed
            KEYBDINSTALLCODE='if ( ! contains "$gapps_list" "keyboardgoogle" ); then
  extract_app "Optional/swypelibs";
  mkdir -p "/system/app/LatinIME/lib/'"$ARCH"'";
  ln -sfn "/system/'"$LIBFOLDER"'/$keybd_lib_google" "/system/app/LatinIME/lib/'"$ARCH"'/$keybd_lib_google"; # create required symlink

  # Add same code to backup script to insure symlinks are recreated on addon.d restore
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"/system/'"$LIBFOLDER"'/$keybd_lib_google\" \"/system/app/LatinIME/lib/'"$ARCH"'/$keybd_lib_google\"" $bkup_tail;
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    mkdir -p \"/system/app/LatinIME/lib/'"$ARCH"'\"" $bkup_tail;
fi;'
          else # on KitKat we need to replace the aosp lib with a symlink, it has no 64bit libs
            REQDLIST="/system/lib/libjni_latinime.so
/system/lib/libjni_latinimegoogle.so"
            KEYBDLIBS='keybd_lib_google="libjni_latinimegoogle.so";
keybd_lib_aosp="libjni_latinime.so";'
      # Only touch AOSP keyboard only if it is not removed
            KEYBDINSTALLCODE='if ( ! contains "$gapps_list" "keyboardgoogle" ); then
  extract_app "Optional/swypelibs";
  ln -sfn "/system/'"$LIBFOLDER"'/$keybd_lib_google" "/system/'"$LIBFOLDER"'/$keybd_lib_aosp"; # create required symlink

  # Add same code to backup script to insure symlinks are recreated on addon.d restore
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"/system/'"$LIBFOLDER"'/$keybd_lib_google\" \"/system/'"$LIBFOLDER"'/$keybd_lib_aosp\"" $bkup_tail;
fi;'
          fi;;
    *) REQDLIST=""
       KEYBDLIBS=""
       KEYBDINSTALLCODE="";;
  esac
}

kitkatdatahack(){
  if [ "$API" -le "19" ]; then
    DATASIZESCODE='    # Broken lib configuration on KitKat, so some apps do not count for the /system space because they are on /data
    if [ "$gapp_name" = "hangouts" ] || [ "$gapp_name" = "googleplus" ] || [ "$gapp_name" = "photos" ] || [ "$gapp_name" = "youtube" ]; then
        appsize=0;
    fi'
    DATAINSTALLCODE='install -d /data/app/
install -d /data/app-lib/
# Handle broken lib configuration on KitKat by putting Hangouts on /data/
if ( contains "$gapps_list" "hangouts" ); then
  unzip -o "$ZIP" "GApps/hangouts.tar.xz" -d /tmp;
  tarpath="/tmp/GApps/hangouts.tar.xz";
  which_dpi "hangouts";
  tar -xJf "$tarpath" -C /tmp "$dpiapkpath";
  cp -rf /tmp/$dpiapkpath/priv-app/Hangouts.apk /data/app/com.google.android.talk.apk;
  rm -rf /tmp/$dpiapkpath;
  tar -xJf "$tarpath" -C /tmp "common";
  cp -rf /tmp/hangouts/common/lib. /data/app-lib/com.google.android.talk/;
  rm -rf /tmp/hangouts/common;
  rm -f "$tarpath";
  gapps_list=${gapps_list/hangouts};
fi;
# Handle broken lib configuration on KitKat by putting Google+ on /data/
if ( contains "$gapps_list" "googleplus" ); then
  unzip -o "$ZIP" "GApps/googleplus.tar.xz" -d /tmp;
  tarpath="/tmp/GApps/googleplus.tar.xz";
  which_dpi "googleplus";
  tar -xJf "$tarpath" -C /tmp "$dpiapkpath";
  cp -rf /tmp/$dpiapkpath/app/PlusOne.apk /data/app/com.google.android.apps.plus.apk;
  rm -rf /tmp/$dpiapkpath;
  tar -xJf "$tarpath" -C /tmp "common";
  cp -rf /tmp/googleplus/common/lib. /data/app-lib/com.google.android.apps.plus/;
  rm -rf /tmp/googleplus/common;
  rm -f "$tarpath";
  gapps_list=${gapps_list/googleplus};
fi;
# Handle broken lib configuration on KitKat by putting Photos on /data/
if ( contains "$gapps_list" "photos" ); then
  unzip -o "$ZIP" "GApps/photos.tar.xz" -d /tmp;
  tarpath="/tmp/GApps/photos.tar.xz";
  which_dpi "photos";
  tar -xJf "$tarpath" -C /tmp "$dpiapkpath";
  cp -rf /tmp/$dpiapkpath/app/Photos.apk /data/app/com.google.android.apps.photos.apk;
  rm -rf /tmp/$dpiapkpath;
  tar -xJf "$tarpath" -C /tmp "common";
  cp -rf /tmp/photos/common/lib. /data/app-lib/com.google.android.apps.photos/;
  rm -rf /tmp/photos/common;
  rm -f "$tarpath";
  gapps_list=${gapps_list/photos};
fi;
# Handle broken lib configuration on KitKat by putting YouTube on /data/
if ( contains "$gapps_list" "youtube" ); then
  unzip -o "$ZIP" "GApps/youtube.tar.xz" -d /tmp;
  tarpath="/tmp/GApps/youtube.tar.xz";
  which_dpi "youtube";
  tar -xJf "$tarpath" -C /tmp "$dpiapkpath";
  cp -rf /tmp/$dpiapkpath/app/YouTube.apk /data/app/com.google.android.youtube.apk;
  rm -rf /tmp/$dpiapkpath;
  tar -xJf "$tarpath" -C /tmp "common";
  cp -rf /tmp/youtube/common/lib. /data/app-lib/com.google.android.youtube/;
  rm -rf /tmp/youtube/common;
  rm -f "$tarpath";
  gapps_list=${gapps_list/youtube};
fi;'
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
    tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'
                    1)  user_remove_folder_list="${user_remove_folder_list}$(find "$folder" -type f -iname "$testapk")"$'\n'; # Add found file to list
                        user_remove_folder_list="${user_remove_folder_list}$(printf "$(find "$folder" -type f -iname "$testapk")" | rev | cut -c 4- | rev)odex"$'\n'; # Add odex to list
EOFILE
  else
    tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'
                    1)  user_remove_folder_list="${user_remove_folder_list}$(dirname "$(find "$folder" -type f -iname "$testapk")")"$'\n'; # Add found folder to list
EOFILE
  fi
}

versionnamehack(){
  case "$package" in
    #the Drive/Docs/Sheets/Slides variate even the last two different digits of the versionName per DPI variant, so we only take the first 10 chars
    com.google.android.apps.docs*) versionname="$(echo "$versionname" | cut -c 1-10)";;
    #the Fitness variate the last 3 digits per DPI variant
    com.google.android.apps.fitness) versionname="$(echo "$versionname" | cut -c 1-7)";;
  esac
}

api21hack(){
  if [ "$API" -ge "21" ]; then
    gappsmini="$gappsmini
taggoogle"
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
    gappscore="$gappscore
packageinstallergoogle"
    gappspico="$gappspico
googletts"
    gappsmini="$gappsmini
calculatorgoogle"
    gappsstock="$gappsstock
contactsgoogle"
#dialergoogle"

    stockremove="$stockremove
contactsstock"
#dialergoogle"
    miniremove="$miniremove
calculatorstock"

    webviewstocklibs='lib/$WebView_lib_filename
lib64/$WebView_lib_filename
' #on Marshmallow the AOSP WebViewlibs must be removed, since they are embedded in the Google WebView APK; this assumes also any pre-bundled Google WebView with the ROM uses embedded libs; use single quote to not replace variable names
    webviewgappsremove=""
  else
    gappsmicro="$gappsmicro
googletts"
    webviewstocklibs="" # on non-Marshmallow the WebViewlibs should not be considered part of the Stock/AOSP WebView, since they are shared with the Google WebView
    webviewgappsremove="lib/libwebviewchromium.so
lib64/libwebviewchromium.so" #on non-Marshmallow the WebViewlibs are to be explictly included as a Google WebView file in gapps-remove.txt
  fi
}
