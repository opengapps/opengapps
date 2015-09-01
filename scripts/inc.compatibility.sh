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

keyboardlibhack(){ #only on lollipop and higher
  if [ "$API" -gt "19" ] && [ "$FALLBACKARCH" = "arm" ]; then
    gappsoptional="keybdlib $gappsoptional"
    REQDLIST="/system/lib/libjni_latinime.so
/system/lib/libjni_latinimegoogle.so
/system/lib64/libjni_latinimegoogle.so
/system/app/LatinIME/lib/$ARCH/libjni_latinime.so
/system/app/LatinIME/lib/$ARCH/libjni_latinimegoogle.so"
    KEYBDLIBS='keybd_lib_filename1="libjni_latinimegoogle.so";
keybd_lib_filename2="libjni_latinime.so";'
    KEYBDINSTALLCODE='if ( ! contains "$gapps_list" "keyboardgoogle" ); then
    extract_app "Optional/keybdlib";
    ln -sf "/system/'"$LIBFOLDER"'/$keybd_lib_filename1" "/system/'"$LIBFOLDER"'/$keybd_lib_filename2"; # create required symlink
    mkdir -p "/system/app/LatinIME/lib/'"$ARCH"'";
    ln -sf "/system/'"$LIBFOLDER"'/$keybd_lib_filename1" "/system/app/LatinIME/lib/'"$ARCH"'/$keybd_lib_filename1"; # create required symlink
    ln -sf "/system/'"$LIBFOLDER"'/$keybd_lib_filename1" "/system/app/LatinIME/lib/'"$ARCH"'/$keybd_lib_filename2"; # create required symlink

    # Add same code to backup script to insure symlinks are recreated on addon.d restore
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sf \"/system/'"$LIBFOLDER"'/$keybd_lib_filename1\" \"/system/app/LatinIME/lib/'"$ARCH"'/$keybd_lib_filename2\"" $bkup_tail;
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sf \"/system/'"$LIBFOLDER"'/$keybd_lib_filename1\" \"/system/app/LatinIME/lib/'"$ARCH"'/$keybd_lib_filename1\"" $bkup_tail;
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    mkdir -p \"/system/app/LatinIME/lib/'"$ARCH"'\"" $bkup_tail;
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sf \"/system/'"$LIBFOLDER"'/$keybd_lib_filename1\" \"/system/'"$LIBFOLDER"'/$keybd_lib_filename2\"" $bkup_tail;
fi;'
  else
    REQDLIST=""
    KEYBDLIBS=""
    KEYBDINSTALLCODE=""
  fi
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
  esac
}

taghack(){
  if [ "$API" -ge "21" ]; then
    gappsmini="$gappsmini
taggoogle"
  fi
}

webviewhack(){
  if [ "$API" -ge "22" ] || { [ "$API" -ge "21" ] && [ "$VARIANT" = "fornexus" ]; }; then #on AOSP we only support Webview on 5.1+, on fornexus 5.0+ is valid
    gappsstock="$gappsstock
webviewgoogle"
    stockremove="$stockremove
webviewstock"
  fi
}
