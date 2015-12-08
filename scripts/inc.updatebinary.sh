makeupdatebinary(){
get_fallback_arch "$ARCH" #make sure that $fallback_arch will be available
echo '#!/sbin/ash
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
# This Open GApps Shell Script Installer file for Open GApps Installer is derived from the work of @TKruzze and @osm0sis,
# Their original work is used with permission, under the license that it may be re-used to continue the GApps package.
# This Open GApps Shell Script Installer includes code derived from the TK GApps of @TKruzze and @osm0sis,
# The TK GApps are available under the GPLv3 from http://forum.xda-developers.com/android/software/tk-gapps-t3116347
#
unzip -o "$3" '"$EXTRACTFILES"' -d /tmp;'> "$build/META-INF/com/google/android/update-binary"
case "$EXTRACTFILES" in
  *xzdec*) echo 'chmod +x /tmp/xzdec'>> "$build/META-INF/com/google/android/update-binary";; #xz-decompression binary bundled
esac
tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'
. /tmp/installer.data;
# _____________________________________________________________________________________________________________________
#                                                  Declare Variables
ZIP="$3";
zip_folder="$(dirname "$ZIP")";
OUTFD=/proc/self/fd/$2;
g_prop=/system/etc/g.prop;
bkup_tail=/tmp/bkup_tail.sh;
gapps_removal_list=/tmp/gapps-remove.txt;
g_log=/tmp/g.log;
calc_log=/tmp/calc.log;
conflicts_log=/tmp/conflicts.log;
rec_cache_log=/cache/recovery/log;
rec_tmp_log=/tmp/recovery.log;
user_remove_notfound_log=/tmp/user_remove_notfound.log;
user_remove_multiplefound_log=/tmp/user_remove_multiplefound.log;

log_close="# End Open GApps Install Log\n";

reclaimed_gapps_space_kb=0;
reclaimed_removal_space_kb=0;
reclaimed_aosp_space_kb=0;
total_install_size_kb=0;
# _____________________________________________________________________________________________________________________
#                                                  Define Functions
abort() {
  quit;
  ui_print "- NO changes were made to your device";
  ui_print " ";
  ui_print "Installer will now exit...";
  ui_print " ";
  ui_print "Error Code: $1";
  sleep 5;
  exxit "$1";
}

ch_con() {
  LD_LIBRARY_PATH=/system/lib /system/lib64 /system/toolbox chcon u:object_r:system_file:s0 "$1";
  LD_LIBRARY_PATH=/system/lib /system/lib64 /system/bin/toolbox chcon u:object_r:system_file:s0 "$1";
  chcon u:object_r:system_file:s0 "$1";
}

ch_con_recursive() {
  dirs=$(echo "$@" | awk '{ print substr($0, index($0,$1)) }');
  for i in $dirs; do
    find "$i" -exec LD_LIBRARY_PATH=/system/lib /system/lib64 /system/toolbox chcon u:object_r:system_file:s0 {} +;
    find "$i" -exec LD_LIBRARY_PATH=/system/lib /system/lib64 /system/bin/toolbox chcon u:object_r:system_file:s0 {} +;
    find "$i" -exec chcon u:object_r:system_file:s0 {} +;
  done;
}

complete_gapps_list() {
  cat <<EOF
$full_removal_list
EOF
}

contains() {
  case "$1" in
    *"$2"*) return 0;;
    *)      return 1;;
  esac;
}

clean_inst() {
  if [ -f /data/system/packages.xml ] && [ "$forceclean" != "true" ]; then
    return 1;
  fi;
  return 0;
}

extract_app() {
  tarpath="/tmp/$1.tar.xz"
  unzip -o "$ZIP" "$1.tar.xz" -d /tmp;
  app_name="$(basename "$1")";
  which_dpi "$app_name";
  if [ "$dpiapkpath" != "unknown" ]; then #technically not necessary, 'unknown' folder would not exist anyway
    folder_extract "$tarpath" "$dpiapkpath";
  fi
  folder_extract "$tarpath" "$app_name/common";
  rm -f "$tarpath";
}

exxit() {
  set_progress 0.98;
  if ( ! grep -qi "nodebug" "$g_conf" ); then
    if [ "$g_conf" ]; then # copy gapps-config files to debug logs folder
      cp -f "$g_conf_orig" /tmp/logs/gapps-config_original.txt;
      cp -f "$g_conf" /tmp/logs/gapps-config_processed.txt;
    fi;
    ls -alZR /system > /tmp/logs/System_Files_After.txt;
    df -k > /tmp/logs/Device_Space_After.txt;
    cp -f "$log_folder/open_gapps_log.txt" /tmp/logs;
    cp -f $b_prop /tmp/logs;
    cp -f /system/addon.d/70-gapps.sh /tmp/logs;
    cp -f $gapps_removal_list "/tmp/logs/gapps-remove_revised.txt";
    cp -f $rec_cache_log /tmp/logs/Recovery_cache.log;
    cp -f $rec_tmp_log /tmp/logs/Recovery_tmp.log;
    cd /tmp;
    tar -cz -f "$log_folder/open_gapps_debug_logs.tar.gz" logs/*;
    cd /;
  fi;
  rm -rf /tmp/*;
  set_progress 1.0;
  ui_print "- Unmounting /system, /data, /cache, /persist";
  ui_print " ";
  umount /system;
  umount /data;
  umount /cache;
  umount /persist;
  exit "$1";
}

file_getprop() {
  grep "^$2" "$1" | cut -d= -f2;
}

folder_extract() {
  if [ "$bundled_xz" = "true" ]; then
    /tmp/xzdec "$1" | tar -x -C /tmp -f - "$2"
  else
    tar -xJf "$1" -C /tmp "$2";
  fi
  bkup_list=$'\n'"$(find "/tmp/$2/" -type f | cut -d/ -f5-)${bkup_list}";
  cp -rf /tmp/$2/. /system/;
  rm -rf /tmp/$2;
}

get_appsize() {
  app_name="$(basename "$1")";
  which_dpi "$app_name";
  app_density="$(basename "$dpiapkpath")";
  appsize="$(cat /tmp/app_sizes.txt | grep -E "$app_name.*($app_density|common)" | awk 'BEGIN { app_size=0; } { folder_size=$3; app_size=app_size+folder_size; } END { printf app_size; }')";
}

log() {
  printf "%30s | %s\n" "$1" "$2" >> $g_log;
}

log_add() {
  printf "%7s | %26s | + %7d | %7d\n" "$1" "$2" "$3" "$4">> $calc_log;
}

log_sub() {
  printf "%7s | %26s | - %7d | %7d\n" "$1" "$2" "$3" "$4">> $calc_log;
}

obsolete_gapps_list() {
  cat <<EOF
$remove_list
EOF
}

quit() {
  set_progress 0.94;
  install_note=$(echo "${install_note}" | sort -r | sed '/^$/d'); # sort Installation Notes & remove empty lines
  echo ----------------------------------------------------------------------------- >> $g_log;
  echo -e "$log_close" >> $g_log;

  # Add Installation Notes to log to help user better understand conflicts/errors
  for note in $install_note; do
    eval "error_msg=\$${note}";
    echo -e "$error_msg" >> $g_log;
  done;

  # Add User App Removals NotFound Log if it exists
  if [ -r $user_remove_notfound_log ]; then
    echo -e "$user_notfound_msg" >> $g_log;
    echo "# Begin User App Removals NOT Found (from gapps-config)" >> $g_log;
    cat $user_remove_notfound_log >> $g_log;
    rm -f $user_remove_notfound_log;
    echo -e "# End User App Removals NOT Found (from gapps-config)\n" >> $g_log;
  fi;
  # Add User App Removals MultipleFound Log if it exists
  if [ -r $user_remove_multiplefound_log ]; then
    echo -e "$user_multiplefound_msg" >> $g_log;
    echo "# Begin User App Removals MULTIPLE Found (from gapps-config)" >> $g_log;
    cat $user_remove_multiplefound_log >> $g_log;
    rm -f $user_remove_multiplefound_log;
    echo -e "# End User App Removals MULTIPLE Found (from gapps-config)\n" >> $g_log;
  fi;

  # Add Duplicate Files Log if it exists
  if [ -r $conflicts_log ]; then
    echo -e "$del_conflict_msg" >> $g_log;
    echo "# Begin GApps <> ROM Duplicate File List" >> $g_log;
    cat $conflicts_log >> $g_log;
    rm -f $conflicts_log;
    echo -e "# End GApps <> ROM Duplicate File List\n" >> $g_log;
  fi;

  # Add Installation Calculations to the log if they were performed
  if [ -r $calc_log ]; then
    echo "# Begin GApps Size Calculations" >> $g_log;
    cat $calc_log >> $g_log;
    rm -f $calc_log;
    echo -e "\n# End GApps Size Calculations" >> $g_log;
  fi;

  # Add list of Raw User Application Removals back to end of processed gapps-config for display in gapps log
  if [ -n "$user_remove_list" ]; then
    for user_remove_app_raw in $user_remove_list; do
      echo "(${user_remove_app_raw})" >> "$g_conf";
    done;
  fi;

  set_progress 0.96;
  # Add gapps-config information to the log
  echo -e "\n# Begin User's gapps-config" >> $g_log;
  if [ "$g_conf" ]; then
    cat "$g_conf" >> $g_log;
  else
    echo -n "   *** NOT USED ***" >> $g_log;
  fi;
  echo -e "\n# End User's gapps-config" >> $g_log;

  # Copy logs to proper folder (Same as gapps-config or same as Zip)
  ui_print "- Copying Log to $log_folder";
  ui_print " ";
  cp -f $g_log "$log_folder/open_gapps_log.txt";
  rm -f $g_log;
  set_progress 0.97;
}

set_perm() {
  chown "$1.$2" "$4";
  chown "$1:$2" "$4";
  chmod "$3" "$4";
}

set_perm_recursive() {
  dirs=$(echo "$@" | awk '{ print substr($0, index($0,$5)) }');
  for i in $dirs; do
    chown -R "$1.$2" "$i"; chown -R "$1:$2" "$i";
    find "$i" -type d -exec chmod "$3" {} +;
    find "$i" -type f -exec chmod "$4" {} +;
  done;
}

set_progress() { echo "set_progress $1" > "$OUTFD"; }

sys_app() {
  if ( grep -q "codePath=\"/system/app/$1" /data/system/packages.xml ); then
    return 0;
  fi;
  return 1;
}

ui_print() {
  echo "ui_print $1" > "$OUTFD";
  echo "ui_print" > "$OUTFD";
}

which_dpi() {
  # Calculate available densities
  app_densities="";
  app_densities="$(cat /tmp/app_densities.txt | grep -E "$1/([0-9-]+|nodpi)/" | sed -r 's#.*/([0-9-]+|nodpi)/.*#\1#' | sort)";
  # Check if in the package there is a version for our density, or a universal one.
  for densities in $app_densities; do
    case "$densities" in
      *"$density"*) dpiapkpath="$1/$densities"; break;;
      *nodpi*)      dpiapkpath="$1/nodpi"; break;;
      *)            dpiapkpath="unknown";;
    esac;
  done;
  # Check if density is unknown or set to nopdi and there is not a universal package and select the package with higher density.
  if { [ "$density" = "unknown" ] || [ "$density" = "nopdi" ]; } && [ "$dpiapkpath" = "unknown" ] && [ -n "$app_densities" ]; then
    app_densities="$(echo "$app_densities" | sort -r)"
    for densities in $app_densities; do
      dpiapkpath="$1/$densities";
      break;
    done;
  fi;
  # If there is no package for our density nor a universal one, we will look for the one with closer, but higher density.
  if [ "$dpiapkpath" = "unknown" ] && [ -n "$app_densities" ]; then
    app_densities="$(echo "$app_densities" | sort)"
    for densities in $app_densities; do
      all_densities="$(echo "$densities" | sed 's/-/ /g' | tr ' ' '\n' | sort | tr '\n' ' ')";
      for d in $all_densities; do
        if [ "$d" -ge "$density" ]; then
          dpiapkpath="$1/$densities";
          break 2;
        fi;
      done;
    done;
  fi;
  # If there is no package for our density nor a universal one or one for higher density, we will use the one with closer, but lower density.
  if [ "$dpiapkpath" = "unknown" ] && [ -n "$app_densities" ]; then
    app_densities="$(echo "$app_densities" | sort -r)"
    for densities in $app_densities; do
      all_densities="$(echo "$densities" | sed 's/-/ /g' | tr ' ' '\n' | sort -r | tr '\n' ' ')";
      for d in $all_densities; do
        if [ "$d" -le "$density" ]; then
          dpiapkpath="$1/$densities";
          break 2;
        fi;
      done;
    done;
  fi;
}
# _____________________________________________________________________________________________________________________
#                                                  Gather Pre-Install Info
# Get GApps Version and GApps Type from g.prop extracted at top of script
gapps_version=$(file_getprop /tmp/g.prop ro.addon.open_version);
gapps_type=$(file_getprop /tmp/g.prop ro.addon.open_type);
# _____________________________________________________________________________________________________________________
#                                                  Begin GApps Installation
ui_print " ";
ui_print '##############################';
ui_print '  _____   _____   ___   ____  ';
ui_print ' /  _  \ |  __ \ / _ \ |  _ \ ';
ui_print '|  / \  || |__) | |_| || | \ \';
ui_print '| |   | ||  ___/|  __/ | | | |';
ui_print '|  \ /  || |    \ |__  | | | |';
ui_print ' \_/ \_/ |_|     \___| |_| |_|';
ui_print '       ___   _   ___ ___  ___ ';
ui_print '      / __| /_\ | _ \ _ \/ __|';
ui_print '     | (_ |/ _ \|  _/  _/\__ \';
ui_print '      \___/_/ \_\_| |_|  |___/';
ui_print '##############################';
ui_print " ";
ui_print "$installer_name$gapps_version";
ui_print " ";
ui_print "- Mounting /system, /cache, /data, /persist";
ui_print " ";
set_progress 0.01;
mount /system;
mount /cache;
mount /data;
mount /persist;
mount -o rw,remount /system;
mount -o rw,remount /system /system;
mount -o rw,remount /;
mount -o rw,remount / /;
# _____________________________________________________________________________________________________________________
#                                                  Gather Device & GApps Package Information
if [ -e "/system/build.prop" ]; then
  b_prop=/system/build.prop;
elif [ -e "/system/default.prop" ]; then
  b_prop=/system/default.prop;
else
  ui_print "*** No build.prop ***";
  ui_print " ";
  ui_print "Your ROM has no build.prop or default.prop";
  ui_print " ";
  ui_print "******* GApps Installation failed *******";
  ui_print " ";
  install_note="${install_note}nobuildprop"$'\n'; # make note that there is no build.prop
  abort "$E_NOBUILDPROP";
fi
# Check if build.prop is not compressed and thus unprocessable
if [ "$(head -c4 "$b_prop")" = "zzzz" ]; then
  ui_print "*** Recovery does not support transparent compression ***";
  ui_print " ";
  ui_print "Your ROM uses transparent compression, but your recovery";
  ui_print "does not support this feature, resulting in corrupt files.";
  ui_print " ";
  ui_print "BEFORE INSTALLING ANYTHING ANYMORE YOU SHOULD UPDATE YOUR";
  ui_print "RECOVERY AS SOON AS POSSIBLE, TO PREVENT FILE CORRUPTION.";
  ui_print " ";
  ui_print "******* GApps Installation failed *******";
  ui_print " ";
  install_note="${install_note}recovery_compression_msg"$'\n'; # make note that recovery does not support transparent compression
  abort "$E_RECCOMPR";
fi

# Get device name any which way we can
for field in ro.product.device ro.build.product ro.product.name; do
  for file in $b_prop /default.prop; do
    device_name=$(file_getprop $file $field);
    if [ ${#device_name} -ge 2 ]; then
      break 2;
    fi;
  done;
  device_name="Bad ROM/Recovery";
done;

# Locate gapps-config (if used)
for i in "/tmp/aroma/.gapps-config"\
 "$zip_folder/.gapps-config-$device_name"\
 "$zip_folder/gapps-config-$device_name.txt"\
 "/sdcard/Open-GApps/.gapps-config-$device_name"\
 "/sdcard/Open-GApps/gapps-config-$device_name.txt"\
 "$zip_folder/.gapps-config"\
 "$zip_folder/gapps-config.txt"\
 "/sdcard/Open-GApps/.gapps-config"\
 "/sdcard/Open-GApps/gapps-config.txt"\
 "$zip_folder/.gapps-config-$device_name.txt"\
 "/sdcard/Open-GApps/.gapps-config-$device_name.txt"\
 "$zip_folder/.gapps-config.txt"\
 "/sdcard/Open-GApps/.gapps-config.txt"\
 "/persist/.gapps-config-$device_name"\
 "/persist/gapps-config-$device_name.txt"\
 "/persist/.gapps-config"\
 "/persist/gapps-config.txt"\
 "/persist/.gapps-config-$device_name.txt"\
 "/persist/.gapps-config.txt"; do
  if [ -r "$i" ]; then
    g_conf="$i";
    break;
  fi;
done;

# We log in the same diretory as the gapps-config file, unless it is aroma
if [ -n "$g_conf" ] && [ "$g_conf" != "/tmp/aroma/.gapps-config" ]; then
  log_folder="$(dirname "$g_conf")";
else
  log_folder="$zip_folder";
fi

if [ "$g_conf" ]; then
  config_file="$g_conf";
  g_conf_orig="$g_conf";
  # Create processed gapps-config with user comments stripped and user app removals removed and stored in variable for processing later
  g_conf="/tmp/proc_gconf";
  sed -e 's|#.*||g' -e 's/\r//g' -e '/^$/d'  "$g_conf_orig" > "$g_conf"; # Strip user comments from gapps-config
  user_remove_list=$(awk -F "[()]" '{ for (i=2; i<NF; i+=2) print $i }' "$g_conf"); # Get users list of apk's to remove from gapps-config
  sed -i s/'([^)]*)'/''/g "$g_conf"; # Remove all instances of user app removals (stuff between parentheses)
  sed -i '/^$/d' "$g_conf"; # Remove all empty lines for cleaner appearance
else
  config_file="Not Used";
  g_conf="/tmp/proc_gconf";
  touch "$g_conf";
fi;

# Unless this is a NoDebug install - create folder and take 'Before' snapshots
if ( ! grep -qi "nodebug" "$g_conf" ); then
  mkdir /tmp/logs;
  ls -alZR /system > /tmp/logs/System_Files_Before.txt;
  df -k > /tmp/logs/Device_Space_Before.txt;
fi;

# Get ROM android version from build.prop
ui_print "- Gathering device & ROM information";
ui_print " ";
rom_android_version=$(file_getprop $b_prop ro.build.version.release);

# Get Device Type (phone or tablet) from build.prop
if echo "$(file_getprop $b_prop ro.build.characteristics)" | grep -qi "tablet"; then
  device_type=tablet;
elif echo "$(file_getprop $b_prop ro.build.characteristics)" | grep -qi "tv"; then
  device_type=tv;
else
  device_type=phone;
fi;

# Get Rom Version from build.prop
for field in ro.modversion ro.build.version.incremental; do
  rom_version="$(file_getprop $b_prop $field)";
  if [ ${#rom_version} -ge 2 ]; then
    break;
  fi;
  rom_version="non-standard build.prop";
done;

echo "# Begin Open GApps Install Log" > $g_log;
echo ----------------------------------------------------------------------------- >> $g_log;
log "ROM Android Version" "$rom_android_version";

# Check to make certain user has proper version ROM Installed
if [ ! "${rom_android_version:0:3}" = "$req_android_version" ]; then
  ui_print "*** Incompatible Android ROM detected ***";
  ui_print " ";
  ui_print "This GApps pkg is for Android $req_android_version.x ONLY";
  ui_print " ";
  ui_print "******* GApps Installation failed *******";
  ui_print " ";
  install_note="${install_note}rom_version_msg"$'\n'; # make note that ROM Version is not compatible with these GApps
  abort "$E_ROMVER";
fi;

# Check to make certain that user device matches the architecture
device_architecture="$(file_getprop $b_prop "ro.product.cpu.abilist=")"
# If the recommended field is empty, fall back to the deprecated one
if [ -z "$device_architecture" ]; then
  device_architecture="$(file_getprop $b_prop "ro.product.cpu.abi=")"
fi
EOFILE
printf 'if ! (echo "$device_architecture" | '>> "$build/META-INF/com/google/android/update-binary"
case "$ARCH" in
  arm)    printf 'grep -i "armeabi" | grep -qiv "arm64"'>> "$build/META-INF/com/google/android/update-binary";;
  arm64)  printf 'grep -qi "arm64"'>> "$build/META-INF/com/google/android/update-binary";;
  x86)    printf 'grep -i "x86" | grep -qiv "x86_64"'>> "$build/META-INF/com/google/android/update-binary";;
  x86_64) printf 'grep -qi "x86_64"'>> "$build/META-INF/com/google/android/update-binary";;
esac
tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'
); then
  ui_print "***** Incompatible Device Detected *****";
  ui_print " ";
  ui_print "This Open GApps package cannot be";
  ui_print "installed on this device's architecture.";
  ui_print "Please download the correct version for";
  ui_print "your device: $device_architecture";
  ui_print " ";
  ui_print "******* GApps Installation failed *******";
  ui_print " ";
  install_note="${install_note}arch_compat_msg"$'\n'; # make note that Open GApps are not compatible with architecture
  abort "$E_ARCH";
fi;

# Determine Recovery Type and Version
for rec_log in $rec_tmp_log $rec_cache_log; do
  recovery=$(busybox grep -m 2 -E " Recovery v|Starting TWRP|Welcome to|PhilZ" $rec_log);
  case "$recovery" in
    *Welcome*)  recovery="$(grep -m 1 "Welcome to" $rec_log | awk '{ print substr($0, index($0,$3)) }')$(grep -m 1 "^ext.version" $rec_log | cut -d\" -f2)"; break;;
    *Recovery*) recovery=$(grep -m 1 "Recovery v" $rec_log); recovery=${recovery/Recovery v/Recovery }; break;;
    *PhilZ*)    recovery=$(grep -m 2 -E "PhilZ|ClockworkMod" $rec_log); recovery="${recovery/ClockworkMod v/(ClockworkMod })"; break;;
    Starting*)  recovery=$(echo "$recovery" | awk -F"Starting " '{ print $2 }' | awk -F" on " '{ print $1 }'); break;;
  esac;
done;

# Check for the presence of the tar binary
if [ -z "$(command -v tar)" ]; then
  ui_print "Your recovery is missing the tar";
  ui_print "binary. Please update your recovery";
  ui_print "to the latest version or switch to";
  ui_print "another recovery like TWRP.";
  ui_print "See:'$log_folder/open_gapps_log.txt'";
  ui_print "for complete details and information.";
  ui_print " ";
  install_note="${install_note}no_tar_message"$'\n'; # make note that there is no TAR support
  abort "$E_TAR";
fi;

# Check for the presence of the xz binary and tar parameter
if [ -z "$(command -v xz)" ] || [ -z "$(tar --help 2>&1 | grep -e "J.*xz")" ]; then
EOFILE
case "$EXTRACTFILES" in
  *xzdec*) echo '  bundled_xz=true'>> "$build/META-INF/com/google/android/update-binary";; #xz-decompression binary bundled
  *)       echo '  ui_print "Your recovery is missing the xz";
  ui_print "binary. Please update your recovery";
  ui_print "to the latest version or switch to";
  ui_print "another recovery like TWRP.";
  ui_print "See:'"'"'$log_folder/open_gapps_log.txt'"'"'";
  ui_print "for complete details and information.";
  ui_print " ";
  install_note="${install_note}no_xz_message"$'"'\n'"'; # make note that there is no XZ support
  abort "$E_XZ";'>> "$build/META-INF/com/google/android/update-binary";;
esac
echo 'else'>> "$build/META-INF/com/google/android/update-binary"
if [ "$VARIANT" = "aroma" ]; then
  echo '  bundled_xz=true #aroma needs bundled xz'>> "$build/META-INF/com/google/android/update-binary" #aroma always needs to use bundled xz, otherwise it crashes
else
  echo '  bundled_xz=false'>> "$build/META-INF/com/google/android/update-binary"
fi
tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'
fi;
# Check for the -f - tar support
if [ -z "$(tar --help 2>&1 | grep -e "f.*stdin")" ]; then
  ui_print "Your recovery does not support stdin";
  ui_print "for the tar binary. Please update your";
  ui_print "recovery to the latest version or";
  ui_print "switch to another recovery like TWRP.";
  ui_print "See:'"'"'$log_folder/open_gapps_log.txt'"'"'";
  ui_print "for complete details and information.";
  ui_print " ";
  install_note="${install_note}no_stdin_message"$'"'\n'"'; # make note that there is no stdin tar support
  abort "$E_STDIN";
fi;

# Get display density using getprop from Recovery
density=$(getprop ro.sf.lcd_density);

# If the density returned by getprop is empty or non-standard - read from default.prop instead
case $density in
  120|160|213|240|280|320|400|480|560|640) ;;
  *) density=$(file_getprop /default.prop ro.sf.lcd_density);;
esac;

# If the density from default.prop is still empty or non-standard - read from build.prop instead
case $density in
  120|160|213|240|280|320|400|480|560|640) ;;
  *) density=$(file_getprop $b_prop ro.sf.lcd_density);;
esac;

# Check for DPI Override in gapps-config
if ( grep -qiE "forcedpi(120|160|213|240|280|320|400|480|560|640|nodpi)" "$g_conf" ); then # user wants to override the DPI selection
  density=$( grep -iEo "forcedpi(120|160|213|240|280|320|400|480|560|640|nodpi)" "$g_conf" | tr '[:upper:]'  '[:lower:]' );
  density=${density#forcedpi};
fi;

# Check for Clean Override in gapps-config
if ( grep -qiE "^forceclean$" "$g_conf" ); then # true or false to override the default selection
  forceclean="true"
else
  forceclean="false"
fi;

# Set density to unknown if it's still empty
test -z "$density" && density=unknown;

# Remove any files from gapps-remove.txt that should not be processed for automatic removal
for bypass_file in $removal_bypass_list; do
  sed -i "\:${bypass_file}:d" $gapps_removal_list;
done;

# Is this a 'Clean' or 'Dirty' install
if ( clean_inst ); then
  install_type="Clean[Data Wiped]";
  cameragoogle_inst=Clean;
else
  install_type="Dirty[Data NOT Wiped]";

  # Was Google Camera previously installed (in /system)
  if ( sys_app GoogleCamera ); then
    cameragoogle_inst=true;
  else
    cameragoogle_inst=false;
  fi;

fi;

# Is device FaceUnlock compatible
if ( ! grep -qE "Victory|herring|sun4i" /proc/cpuinfo ); then
  for xml in /system/etc/permissions/android.hardware.camera.front.xml /system/etc/permissions/android.hardware.camera.xml; do
    if ( grep -q "feature name=\"android.hardware.camera.front" $xml ); then
      faceunlock_compat=true;
      break;
    fi;
    faceunlock_compat=false;
  done;
else
  faceunlock_compat=false;
fi;

# Check device name for devices that are incompatible with Google Camera
case $device_name in
EOFILE
cameracompatibilityhack #in kitkat we don't have google camera compatibility with some phones
tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'
  *) cameragoogle_compat=true;;
esac;

log "ROM ID" "$(file_getprop $b_prop ro.build.display.id)";
log "ROM Version" "$rom_version";
log "Device Recovery" "$recovery";
log "Using Bundled XZdec" "$bundled_xz"
log "Device Name" "$device_name";
log "Device Model" "$(file_getprop $b_prop ro.product.model)";
log "Device Type" "$device_type";
log "Device CPU" "$device_architecture";
log "getprop Density" "$(getprop ro.sf.lcd_density)";
log "default.prop Density" "$(file_getprop /default.prop ro.sf.lcd_density)";
log "build.prop Density" "$(file_getprop $b_prop ro.sf.lcd_density)";
log "Display Density Used" "${density}dpi";
log "Install Type" "$install_type";
log "Google Camera Installed¹" "$cameragoogle_inst";
log "FaceUnlock Compatible" "$faceunlock_compat";
log "Google Camera Compatible" "$cameragoogle_compat";
log_close="                  ¹ Previously installed with Open GApps\n$log_close";

# Determine if a GApps package is installed and
# the version, type, and whether it's a Open GApps package
if [ -e /system/priv-app/GoogleServicesFramework/GoogleServicesFramework.apk -a -e /system/priv-app/GoogleLoginService/GoogleLoginService.apk ]; then
  if $(grep -q -e ro.addon.open_version $g_prop); then
    log "Current GApps Version" "$(file_getprop $g_prop ro.addon.open_version)";
    if $(grep -q ro.addon.open_type $g_prop); then
      log "Current Open GApps Package" "$(file_getprop $g_prop ro.addon.open_type)";
    else
      log "Current Open GApps Package" "Unknown";
    fi;
  elif [ -e /system/etc/g.prop ]; then
    log "Current GApps Version" "NON Open GApps Package Currently Installed (FAILURE)";
    ui_print "* Incompatible GApps Currently Installed *";
    ui_print " ";
    ui_print "This Open GApps package can ONLY be installed";
    ui_print "on top of an existing installation of Open GApps";
    ui_print "or a clean AOSP/CyanogenMod ROM installation,";
    ui_print "or a Stock ROM that conforms to Nexus standards.";
    ui_print "You must wipe (format) your system partition";
    ui_print "and flash your ROM BEFORE installing Open GApps.";
    ui_print " ";
    ui_print "******* GApps Installation failed *******";
    ui_print " ";
    install_note="${install_note}non_open_gapps_msg"$'\n'; # make note that currently installed GApps are non-Open
    abort "$E_NONOPEN";
  else
    log "Current GApps Version" "Stock ROM GApps Currently Installed (NOTICE)";
    ui_print "* Stock ROM GApps Currently Installed *";
    ui_print " ";
    ui_print "The installer detected that Stock ROM GApps are";
    ui_print "already installed. If you are flashing over a";
    ui_print "Nexus-compatible ROM there is no problem, but if";
    ui_print "you are flashing over a custom ROM, you may want";
    ui_print "to contact the developer to request the removal of";
    ui_print "the included GApps. The installation will now";
    ui_print "continue, but please be aware that any problems";
    ui_print "that may occur depend on your ROM.";
    ui_print " ";
    install_note="${install_note}fornexus_open_gapps_msg"$'\n'; # make note that currently installed GApps are Stock ROM
  fi;
else
  # User does NOT have a GApps package installed on their device
  log "Current GApps Version" "No GApps Installed";

  # Use the opportunity of No GApps installed to check for potential ROM conflicts when deleting existing GApps files
  while read gapps_file; do
    if [ -e "$gapps_file" ] && [ "$gapps_file" != "/system/lib/$WebView_lib_filename" ] && [ "$gapps_file" != "/system/lib64/$WebView_lib_filename" ]; then
      echo "$gapps_file" >> $conflicts_log;
    fi;
  done < $gapps_removal_list;
fi;
# _____________________________________________________________________________________________________________________
#                                                  Prepare the list of GApps being installed and AOSP/Stock apps being removed
# Build list of available GApps that can be installed (and check for a user package preset)
for pkg in $pkg_names; do
  eval "addto=\$${pkg}_gapps_list"; # Look for method to combine this with line below
  all_gapps_list=${all_gapps_list}${addto}; # Look for method to combine this with line above
  if ( grep -qi "${pkg}gapps" "$g_conf" ); then # user has selected a 'preset' install
    gapps_type=$pkg;
    sed -i "/ro.addon.open_type/c\ro.addon.open_type=$pkg" /tmp/g.prop; # modify g.prop to new package type
    break;
  fi;
done;

# Prepare list of User specified GApps that will be installed
if [ "$g_conf" ]; then
  if ( grep -qi "include" "$g_conf" ); then # User is indicating the apps they WANT installed
    config_type=include;
    for gapp_name in $all_gapps_list; do
      if ( grep -qi "$gapp_name" "$g_conf" ); then
        gapps_list="$gapps_list$gapp_name"$'\n';
      fi;
    done;
  else # User is indicating the apps they DO NOT WANT installed
    config_type=exclude;
    for gapp_name in $all_gapps_list; do
      if ( ! grep -qi "$gapp_name" "$g_conf" ); then
        gapps_list="$gapps_list$gapp_name"$'\n';
      fi;
    done;
  fi;
else # User is not using a gapps-config and we're doing the 'full monty'
  config_type="[Default]";
  gapps_list=$all_gapps_list;
fi;

# Configure default removal of Stock/AOSP apps - if we're installing Stock GApps
if [ "$gapps_type" = "super" ] || [ "$gapps_type" = "stock" ] || [ "$gapps_type" = "aroma" ]; then
  for default_name in $default_aosp_remove_list; do
    eval "remove_${default_name}=true[default]";
  done;
else
  # Do not perform any default removals - but make them optional
  for default_name in $default_aosp_remove_list; do
    eval "remove_${default_name}=false[default]";
  done;
fi;

# Prepare list of AOSP/ROM files that will be deleted using gapps-config
# We will look for +Browser, +Email, +Gallery, +Launcher, +MMS, +PicoTTS and more to prevent their removal
set_progress 0.03;
if [ "$g_conf" ]; then
  for default_name in $default_aosp_remove_list; do
    if ( grep -qi "+$default_name" "$g_conf" ); then
      eval "remove_${default_name}=false[gapps-config]";
    elif [ "$gapps_type" = "super" ] || [ "$gapps_type" = "stock" ] || [ "$gapps_type" = "aroma" ]; then
      aosp_remove_list="$aosp_remove_list$default_name"$'\n';
      if ( grep -qi "$default_name" "$g_conf" ); then
        eval "remove_${default_name}=true[gapps-config]";
      fi;
    else
      if ( grep -qi "$default_name" "$g_conf" ); then
        eval "remove_${default_name}=true[gapps-config]";
        aosp_remove_list="$aosp_remove_list$default_name"$'\n';
      fi;
    fi;
  done;
  # Check gapps-config for other optional AOSP/ROM files that will be deleted
  for opt_name in $optional_aosp_remove_list; do
    if ( grep -qi "$opt_name" "$g_conf" ); then
      aosp_remove_list="$aosp_remove_list$opt_name"$'\n';
    fi;
  done;
else
  if [ "$gapps_type" = "super" ] || [ "$gapps_type" = "stock" ] || [ "$gapps_type" = "aroma" ]; then
      aosp_remove_list=$default_aosp_remove_list;
  fi;
fi;

# Verify device is FaceUnlock compatible BEFORE we allow it in $gapps_list
if ( contains "$gapps_list" "faceunlock" ) && [ $faceunlock_compat = "false" ]; then
  gapps_list=${gapps_list/faceunlock};
  install_note="${install_note}faceunlock_msg"$'\n'; # make note that FaceUnlock will NOT be installed as user requested
fi;

# If we're NOT installing chrome make certain 'browser' is NOT in $aosp_remove_list UNLESS 'browser' is in $g_conf
if ( ! contains "$gapps_list" "chrome" ) && ( ! grep -qi "browser" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/browser};
  remove_browser="false[NO_Chrome]";
fi;

# If we're NOT installing gmail make certain 'email' is NOT in $aosp_remove_list UNLESS 'email' is in $g_conf
if ( ! contains "$gapps_list" "gmail" ) && ( ! grep -qi "email" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/email};
  remove_email="false[NO_Gmail]";
fi;

# If we're NOT installing photos make certain 'gallery' is NOT in $aosp_remove_list UNLESS 'gallery' is in $g_conf
if ( ! contains "$gapps_list" "photos" ) && ( ! grep -qi "gallery" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/gallery};
  remove_gallery="false[NO_Photos]";
fi;

# If $device_type is 'tablet' make certain we're not installing messenger
if ( contains "$gapps_list" "messenger" ) && [ $device_type = "tablet" ]; then
  gapps_list=${gapps_list/messenger}; # we'll prevent messenger from being installed since this isn't a phone
fi;

# If we're NOT installing hangouts or messenger make certain 'mms' is NOT in $aosp_remove_list UNLESS 'mms' is in $g_conf
if ( ! contains "$gapps_list" "hangouts" )  && ( ! contains "$gapps_list" "messenger" ) && ( ! grep -qi "mms" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/mms};
  remove_mms="false[NO_Hangouts]";
fi;

# If we're NOT installing hangouts or messenger and mms is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "hangouts" ) && ( ! contains "$gapps_list" "messenger" ) && ( contains "$aosp_remove_list" "mms" ) && ( ! grep -qi "override" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/mms}; # we'll prevent mms from being removed so user isn't left with no way to receive text messages
  remove_mms="false[NO_Override]";
  install_note="${install_note}nomms_msg"$'\n'; # make note that MMS can't be removed unless user Overrides
fi;

# If we're NOT installing googletts make certain 'picotts' is NOT in $aosp_remove_list UNLESS 'picotts' is in $g_conf
if ( ! contains "$gapps_list" "googletts" ) && ( ! grep -qi "picotts" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/picotts};
  remove_picotts="false[NO_GoogleTTS]";
fi;

# If we're NOT installing search then we MUST REMOVE googlenow from  $gapps_list (if it's currently there)
if ( ! contains "$gapps_list" "search" ) && ( contains "$gapps_list" "googlenow" ); then
  gapps_list=${gapps_list/googlenow};
  install_note="${install_note}googlenow_msg"$'\n'; # make note that Google Now Launcher will NOT be installed as user requested
fi;

# If we're NOT installing googlenow make certain 'launcher' is NOT in $aosp_remove_list UNLESS 'launcher' is in $g_conf
if ( ! contains "$gapps_list" "googlenow" ) && ( ! grep -qi "launcher" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/launcher};
  remove_launcher="false[NO_GoogleNow]";
fi;

# If we're NOT installing googlenow and launcher is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "googlenow" ) && ( contains "$aosp_remove_list" "launcher" ) && ( ! grep -qi "override" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/launcher}; # we'll prevent launcher from being removed so user isn't left with no Launcher
  remove_launcher="false[NO_Override]";
  install_note="${install_note}nolauncher_msg"$'\n'; # make note that Launcher can't be removed unless user Overrides
fi;

# If we're installing calendargoogle we must ADD calendarstock to $aosp_remove_list (if it's not already there) and NOT install calsync
if ( contains "$gapps_list" "calendargoogle" ) && ( ! contains "$aosp_remove_list" "calendarstock" ); then
  aosp_remove_list="${aosp_remove_list}calendarstock"$'\n';
  gapps_list=${gapps_list/calsync};
fi;

# If we're installing keyboardgoogle we must ADD keyboardstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "keyboardgoogle" ) && ( ! contains "$aosp_remove_list" "keyboardstock" ); then
  aosp_remove_list="${aosp_remove_list}keyboardstock"$'\n';
fi;

# If we're NOT installing keyboardgoogle and keyboardstock is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "keyboardgoogle" ) && ( contains "$aosp_remove_list" "keyboardstock" ) && ( ! grep -qi "override" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/keyboardstock}; # we'll prevent keyboardstock from being removed so user isn't left with no keyboard
  install_note="${install_note}nokeyboard_msg"$'\n'; # make note that Stock Keyboard can't be removed unless user Overrides
fi;

# Verify device is Google Camera compatible BEFORE we allow it in $gapps_list
if ( contains "$gapps_list" "cameragoogle" ) && [ $cameragoogle_compat = "false" ]; then
  gapps_list=${gapps_list/cameragoogle}; # we must DISALLOW cameragoogle from being installed
  install_note="${install_note}camera_compat_msg"$'\n'; # make note that Google Camera will NOT be installed as user requested
fi;

# If user wants to install cameragoogle then it MUST be a Clean Install OR cameragoogle was previously installed in system partition
if ( contains "$gapps_list" "cameragoogle" ) && ( ! clean_inst ) && [ $cameragoogle_inst = "false" ]; then
  gapps_list=${gapps_list/cameragoogle}; # we must DISALLOW cameragoogle from being installed
  aosp_remove_list=${aosp_remove_list/camerastock}; # and we'll prevent camerastock from being removed so user isn't left with no camera
  install_note="${install_note}camera_sys_msg"$'\n'; # make note that Google Camera will NOT be installed as user requested
fi;

# If we're installing cameragoogle we MUST ADD camerastock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "cameragoogle" ) && ( ! contains "$aosp_remove_list" "camerastock" ); then
  aosp_remove_list="${aosp_remove_list}camerastock"$'\n';
fi;

# If we're installing clockgoogle we must ADD clockstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "clockgoogle" ) && ( ! contains "$aosp_remove_list" "clockstock" ); then
  aosp_remove_list="${aosp_remove_list}clockstock"$'\n';
  remove_clockstock="true[ClockGoogle]";
fi;

# If we're installing exchangegoogle we must ADD exchangestock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "exchangegoogle" ) && ( ! contains "$aosp_remove_list" "exchangestock" ); then
  aosp_remove_list="${aosp_remove_list}exchangestock"$'\n';
fi;

# If we're installing taggoogle we must ADD tagstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "taggoogle" ) && ( ! contains "$aosp_remove_list" "tagstock" ); then
  aosp_remove_list="${aosp_remove_list}tagstock"$'\n';
  remove_tagstock="true[TagGoogle]";
fi;

# If we're installing webviewgoogle we MUST ADD webviewstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "webviewgoogle" ) && ( ! contains "$aosp_remove_list" "webviewstock" ); then
  aosp_remove_list="${aosp_remove_list}webviewstock"$'\n';
fi;

# If we're NOT installing webviewgoogle and webviewstock is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "webviewgoogle" ) && ( contains "$aosp_remove_list" "webviewstock" ) && ( ! grep -qi "override" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/webviewstock}; # we'll prevent webviewstock from being removed so user isn't left with no WebView
  remove_webviewstock="false[NO_WebViewGoogle]";
  install_note="${install_note}nowebview_msg"$'\n'; # make note that Stock Webview can't be removed unless user Overrides
fi;

# If we're installing calculatorgoogle we MUST ADD calculatorstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "calculatorgoogle" ) && ( ! contains "$aosp_remove_list" "calculatorstock" ); then
  aosp_remove_list="${aosp_remove_list}calculatorstock"$'\n';
fi;

# If we're installing contactsgoogle we MUST ADD contactsstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "contactsgoogle" ) && ( ! contains "$aosp_remove_list" "contactsstock" ); then
  aosp_remove_list="${aosp_remove_list}contactsstock"$'\n';
fi;

# If we're installing dialergoogle we MUST ADD dialerstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "dialergoogle" ) && ( ! contains "$aosp_remove_list" "dialerstock" ); then
  aosp_remove_list="${aosp_remove_list}dialerstock"$'\n';
fi;

# If we're installing packageinstallergoogle we MUST ADD packageinstallerstock to $aosp_remove_list (if it's not already there)
if ( contains "$core_gapps_list" "packageinstallergoogle" ) && ( ! contains "$aosp_remove_list" "packageinstallerstock" ); then
  aosp_remove_list="${aosp_remove_list}packageinstallerstock"$'\n';
fi;

# If we're NOT installing gcs then we MUST REMOVE projectfi from  $gapps_list (if it's currently there)
if ( ! contains "$gapps_list" "gcs" ) && ( contains "$gapps_list" "projectfi" ); then
  gapps_list=${gapps_list/projectfi};
  install_note="${install_note}projectfi_msg"$'\n'; # make note that Project Fi will NOT be installed as user requested
fi;

# Some ROMs bundle Google Apps or the user might have installed a Google replacement app during an earlier install
# Some of these apps are crucial to a functioning system and should NOT be removed if no AOSP/Stock equivalent is available
# Unless override keyword is used, make sure they are not removed
# NOTICE: Only for Google Keyboard we need to take KitKat support into account, others are only Lollipop+
ignoregooglecontacts="true"
for f in $contactsstock_list; do
  if [ -e "$f" ]; then
    ignoregooglecontacts="false"
    break; #at least 1 aosp stock file is present
  fi
done;
if [ "$ignoregooglecontacts" = "true" ]; then
  if ( ! contains "$gapps_list" "contactsgoogle" ) && ( ! grep -qi "override" "$g_conf" ); then
    sed -i "\:/system/priv-app/GoogleContacts:d" $gapps_removal_list;
    ignoregooglecontacts="true[NoRemove]"
    install_note="${install_note}nogooglecontacts_removal"$'\n'; # make note that Google Contacts will not be removed
  else
    ignoregooglecontacts="false[ContactsGoogle]"
  fi
fi

#ignoregoogledialer="true"
#for f in $dialerstock_list; do
#  if [ -e "$f" ]; then
#    ignoregoogledialer="false"
#    break; #at least 1 aosp stock file is present
#  fi
#done;
#if [ "$ignoregoogledialer" = "true" ]; then
#  if ( ! contains "$gapps_list" "dialergoogle" ) && ( ! grep -qi "override" "$g_conf" ); then
#    sed -i "\:/system/priv-app/GoogleDialer:d" $gapps_removal_list;
#    ignoregoogledialer="true[NoRemove]"
#    install_note="${install_note}nogoogledialer_removal"$'\n'; # make note that Google Dialer will not be removed
#  else
#    ignoregoogledialer="false[DialerGoogle]"
#  fi
#fi

ignoregooglekeyboard="true"
for f in $keyboardstock_list; do
  if [ -e "$f" ]; then
    ignoregooglekeyboard="false"
    break; #at least 1 aosp stock file is present
  fi
done;
if [ "$ignoregooglekeyboard" = "true" ]; then
  if ( ! contains "$gapps_list" "keyboardgoogle" ) && ( ! grep -qi "override" "$g_conf" ); then
EOFILE
keyboardgooglenotremovehack
tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'
    ignoregooglekeyboard="true[NoRemove]"
    install_note="${install_note}nogooglekeyboard_removal"$'\n'; # make note that Google Keyboard will not be removed
  else
    ignoregooglekeyboard="false[KeyboardGoogle]"
  fi
fi

ignoregooglepackageinstaller="true"
for f in $packageinstallerstock_list; do
  if [ -e "$f" ]; then
    ignoregooglepackageinstaller="false"
    break; #at least 1 aosp stock file is present
  fi
done;
if [ "$ignoregooglepackageinstaller" = "true" ]; then
  if ( ! contains "$gapps_list" "packageinstallergoogle" ) && ( ! grep -qi "override" "$g_conf" ); then
    sed -i "\:/system/priv-app/GooglePackageInstaller:d" $gapps_removal_list;
    ignoregooglepackageinstaller="true[NoRemove]"
    install_note="${install_note}nogooglepackageinstaller_removal"$'\n'; # make note that Google Package Installer will not be removed
  else
    ignoregooglepackageinstaller="false[PackageInstallerGoogle]"
  fi
fi

ignoregoogletag="true"
for f in $tagstock_list; do
  if [ -e "$f" ]; then
    ignoregoogletag="false"
    break; #at least 1 aosp stock file is present
  fi
done;
if [ "$ignoregoogletag" = "true" ]; then
  if ( ! contains "$gapps_list" "taggoogle" ) && ( ! grep -qi "override" "$g_conf" ); then
    sed -i "\:/system/priv-app/TagGoogle:d" $gapps_removal_list;
    ignoregoogletag="true[NoRemove]"
    install_note="${install_note}nogoogletag_removal"$'\n'; # make note that Google Tag will not be removed
  else
    ignoregoogletag="false[TagGoogle]"
  fi
fi

ignoregooglewebview="true"
for f in $webviewstock_list; do
  if [ -e "$f" ]; then
    ignoregooglewebview="false"
    break; #at least 1 aosp stock file is present
  fi
done;
if [ "$ignoregooglewebview" = "true" ]; then #No AOSP WebView
  if ( ! contains "$gapps_list" "webviewgoogle" ) && ( ! grep -qi "override" "$g_conf" ); then #Don't remove Google WebView components if no Google WebView selected
    sed -i "\:/system/lib/$WebView_lib_filename:d" $gapps_removal_list;
    sed -i "\:/system/lib64/$WebView_lib_filename:d" $gapps_removal_list;
    sed -i "\:/system/app/WebViewGoogle:d" $gapps_removal_list;
    ignoregooglewebview="true[NoRemove]"
    install_note="${install_note}nogooglewebview_removal"$'\n'; # make note that Google WebView will not be removed
  else #No AOSP WebView, but Google WebView is being installed, no reason to protect the current components
    ignoregooglewebview="false[WebViewGoogle]"
  fi
elif ( ! contains "$gapps_list" "webviewgoogle" ); then #AOSP WebView, and no Google WebView being installed, make sure to protect the current AOSP components that share name with Google WebView components
  sed -i "\:/system/lib/$WebView_lib_filename:d" $gapps_removal_list;
  sed -i "\:/system/lib64/$WebView_lib_filename:d" $gapps_removal_list;
fi

# Process User Application Removals for calculations and subsequent removal
if [ -n "$user_remove_list" ]; then
  for remove_apk in $user_remove_list; do
    testapk=$( echo "$remove_apk" | tr '[:upper:]'  '[:lower:]' );
    # Add apk extension if user didn't include it
    case $testapk in
      *".apk" ) ;;
      * )       testapk="${testapk}.apk" ;;
    esac;
    # Create user_remove_folder_list if this is a system/ROM application
    for folder in /system/app /system/priv-app; do # Check all subfolders in /system/app /system/priv-app for the apk
      file_count=0; # Reset Counter
      file_count=$(find $folder -iname "$testapk" | wc -l);
      case $file_count in
        0)  continue;;
EOFILE
universalremoverhack #on kitkat the paths for the universalremover are different
tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'
            break;;
        *)  echo "$remove_apk" >> $user_remove_multiplefound_log; # Add app to user_remove_multiplefound_log since we found more than 1 instance
            break;;
      esac;
    done;
    if [ "$file_count" -eq 0 ]; then
      echo "$remove_apk" >> $user_remove_notfound_log;
    fi; # Add 'not found' app to user_remove_notfound_log
  done;
fi;

# Removing old Chrome libraries
obsolete_libs_list="";
for f in $(find /system/lib /system/lib64 -name 'libchrome*.so' 2>/dev/null); do
  obsolete_libs_list="${obsolete_libs_list}$f"$'\n';
done;

# Read in gapps removal list from file and append old Chrome libs
full_removal_list="$(cat $gapps_removal_list)"$'\n'"${obsolete_libs_list}";

# Clean up and sort our lists for space calculations and installation
set_progress 0.04;
gapps_list=$(echo "${gapps_list}" | sort | sed '/^$/d'); # sort GApps list & remove empty lines
aosp_remove_list=$(echo "${aosp_remove_list}" | sort | sed '/^$/d'); # sort AOSP Remove list & remove empty lines
full_removal_list=$(echo "${full_removal_list}" | sed '/^$/d'); # Remove empty lines from FINAL GApps Removal list
remove_list=$(echo "${remove_list}" | sed '/^$/d'); # Remove empty lines from remove_list
user_remove_folder_list=$(echo "${user_remove_folder_list}" | sed '/^$/d'); # Remove empty lines from User Application Removal list

log "Installing GApps Version" "$gapps_version";
log "Installing GApps Type" "$gapps_type";
log "Config Type" "$config_type";
log "Using gapps-config" "$config_file";
log "Remove Stock/AOSP Browser" "$remove_browser";
log "Remove Stock/AOSP Clock" "$remove_clockstock";
log "Remove Stock/AOSP Email" "$remove_email";
log "Remove Stock/AOSP Gallery" "$remove_gallery";
log "Remove Stock/AOSP Launcher" "$remove_launcher";
log "Remove Stock/AOSP MMS App" "$remove_mms";
log "Remove Stock/AOSP Pico TTS" "$remove_picotts";
log "Remove Stock/AOSP NFC Tag" "$remove_tagstock";
log "Remove Stock/AOSP WebView" "$remove_webviewstock";
log "Ignore Google Contacts" "$ignoregooglecontacts";
#log "Ignore Google Dialer" "$ignoregoogledialer";
log "Ignore Google Keyboard" "$ignoregooglekeyboard";
log "Ignore Google Package Installer" "$ignoregooglepackageinstaller";
log "Ignore Google NFC Tag" "$ignoregoogletag";
log "Ignore Google WebView" "$ignoregooglewebview";
# _____________________________________________________________________________________________________________________
#                                                  Perform space calculations
ui_print "- Performing system space calculations";
ui_print " ";

# Perform calculations of core applications
core_size=0;
for gapp_name in $core_gapps_list; do
  get_appsize "Core/$gapp_name";
  core_size=$((core_size + appsize));
done;

# Add swypelibs size to core, if it will be installed
if ( ! contains "$gapps_list" "keyboardgoogle" ); then
  unzip -o "$ZIP" "Optional/swypelibs.tar.xz" -d /tmp;
  keybd_lib_size=$(tar -tvJf "/tmp/Optional/swypelibs.tar.xz" "swypelibs" 2>/dev/null | awk 'BEGIN { app_size=0; } { file_size=$3; app_size=app_size+file_size; } END { printf "%.0f\n", app_size / 1024; }');
  rm -f "/tmp/Optional/swypelibs.tar.xz";
  core_size=$((core_size + keybd_lib_size)); # Add Keyboard Lib size to core, if it exists
fi

# Read and save system partition size details
df=$(busybox df -k /system | tail -n 1);
case $df in
  /dev/block/*) df=$(echo "$df" | awk '{ print substr($0, index($0,$2)) }');;
esac;
total_system_size_kb=$(echo "$df" | awk '{ print $1 }');
used_system_size_kb=$(echo "$df" | awk '{ print $2 }');
free_system_size_kb=$(echo "$df" | awk '{ print $3 }');
log "Total System Size (KB)" "$total_system_size_kb";
log "Used System Space (KB)" "$used_system_size_kb";
log "Current Free Space (KB)" "$free_system_size_kb";

# Perform storage space calculations of existing GApps that will be deleted/replaced
reclaimed_gapps_space_kb=$(du -ck $(complete_gapps_list) | tail -n1 | awk '{ print $1 }');

# Perform storage space calculations of other Removals that need to be deleted (Obsolete and Conflicting Apps)
set_progress 0.05;
reclaimed_removal_space_kb=$(du -ck $(obsolete_gapps_list) | tail -n1 | awk '{ print $1 }');

# Add information to calc.log that will later be added to open_gapps.log to assist user with app removals
post_install_size_kb=$((free_system_size_kb + reclaimed_gapps_space_kb)); # Add opening calculations
echo ----------------------------------------------------------------------------- > $calc_log;
printf "%7s | %26s |   %7s | %7s\n" "TYPE " "DESCRIPTION       " "SIZE" "  TOTAL" >> $calc_log;
printf "%7s | %26s |   %7d | %7d\n" "" "Current Free Space" "$free_system_size_kb" "$free_system_size_kb" >> $calc_log;
printf "%7s | %26s | + %7d | %7d\n" "Remove" "Existing GApps" "$reclaimed_gapps_space_kb" $post_install_size_kb >> $calc_log;
post_install_size_kb=$((post_install_size_kb + reclaimed_removal_space_kb)); # Add reclaimed_removal_space_kb
printf "%7s | %26s | + %7d | %7d\n" "Remove" "Obsolete Files" "$reclaimed_removal_space_kb" $post_install_size_kb >> $calc_log;

# Perform calculations of AOSP/ROM files that will be deleted
set_progress 0.07;
for aosp_name in $aosp_remove_list; do
  eval "list_name=\$${aosp_name}_list";
  aosp_size_kb=0; # Reset counter
  for file_name in $list_name; do
    if [ -e "/system/$file_name" ]; then
      file_size_kb=$(du -ck "/system/$file_name" | tail -n1 | awk '{ print $1 }');
      aosp_size_kb=$((file_size_kb + aosp_size_kb));
      post_install_size_kb=$((post_install_size_kb + file_size_kb));
    fi;
  done;
  log_add "Remove" "$aosp_name" $aosp_size_kb $post_install_size_kb;
done;

# Perform calculations of User App Removals that will be deleted
for remove_folder in $user_remove_folder_list; do
  if [ -e "$remove_folder" ]; then
    folder_size_kb=$(du -ck "$remove_folder" | tail -n1 | awk '{ print $1 }');
    post_install_size_kb=$((post_install_size_kb + folder_size_kb));
    log_add "Remove" "$(basename "$remove_folder")°" "$folder_size_kb" $post_install_size_kb;
  fi;
done;

# Perform calculations of GApps files that will be installed
set_progress 0.09;
post_install_size_kb=$((post_install_size_kb - core_size)); # Add Core GApps
log_sub "Install" "Core²" $core_size $post_install_size_kb;

for gapp_name in $gapps_list; do
  get_appsize "GApps/$gapp_name";
EOFILE
echo "$DATASIZESCODE" >> "$build/META-INF/com/google/android/update-binary"
tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'
  post_install_size_kb=$((post_install_size_kb - appsize));
  log_sub "Install" "$gapp_name³" "$appsize" $post_install_size_kb;
done;

# Perform calculations of required Buffer Size
set_progress 0.11;
if ( grep -qi "smallbuffer" "$g_conf" ); then
  buffer_size_kb=$small_buffer_size;
fi;

post_install_size_kb=$((post_install_size_kb - buffer_size_kb));
log_sub "" "Buffer Space²" "$buffer_size_kb" $post_install_size_kb;
echo ----------------------------------------------------------------------------- >> $calc_log;

if [ "$post_install_size_kb" -ge 0 ]; then
  printf "%47s | %7d\n" "  Post Install Free Space" $post_install_size_kb >> $calc_log;
  log "Post Install Free Space (KB)" "$post_install_size_kb       << See Calculations Below";
else
  additional_size_kb=$((post_install_size_kb * -1));
  printf "%47s | %7d\n" "Additional Space Required" $additional_size_kb >> $calc_log;
  log "Additional Space Required (KB)" "$additional_size_kb       << See Calculations Below";
fi;

# Finish up Calculation Log
echo ----------------------------------------------------------------------------- >> $calc_log;
if [ -n "$user_remove_folder_list" ]; then
  echo "              ° User Requested Removal" >> $calc_log;
fi;
echo "              ² Required (ALWAYS Installed)" >> $calc_log;
echo "              ³ Optional (may be removed)" >> $calc_log;

# Check whether there's enough free space to complete this installation
if [ "$post_install_size_kb" -lt 0 ]; then
  # We don't have enough system space to install everything user requested
  ui_print "Insufficient storage space available in";
  ui_print "System partition. You may want to use a";
  ui_print "smaller Open GApps package or consider";
  ui_print "removing some apps using gapps-config.";
  ui_print "See:'$log_folder/open_gapps_log.txt'";
  ui_print "for complete details and information.";
  ui_print " ";
  install_note="${install_note}system_space_msg"$'\n'; # make note that there is insufficient space in system to install
  abort "$E_NOSPACE";
fi;

# Check to see if this is the 'real thing' or only a test
if ( grep -qi "test" "$g_conf" ); then # user has selected a 'test' install ONLY
  ui_print "- Exiting Simulated Install";
  ui_print " ";
  install_note="${install_note}simulation_msg"$'\n'; # make note that this is only a test installation
  quit;
  exxit 0;
fi;
# _____________________________________________________________________________________________________________________
#                                                  Perform Removals
# Remove ALL Existing GApps files
set_progress 0.13;
ui_print "- Removing existing/obsolete Apps";
ui_print " ";
rm -rf $(complete_gapps_list);

# Remove Obsolete and Conflicting Apps
rm -rf $(obsolete_gapps_list);

# Remove Stock/AOSP Apps and add Removals to addon.d script
aosp_remove_list=$(echo "${aosp_remove_list}" | sort -r); # reverse sort list for more readable output
for aosp_name in $aosp_remove_list; do
  eval "list_name=\$${aosp_name}_list";
  list_name=$(echo "${list_name}" | sort -r); # reverse sort list for more readable output
  for file_name in $list_name; do
    rm -rf "/system/$file_name";
    sed -i "\:# Remove Stock/AOSP apps (from GApps Installer):a \    rm -rf /system/$file_name" $bkup_tail;
  done;
done;

# Perform User App Removals and add Removals to addon.d script
user_remove_folder_list=$(echo "${user_remove_folder_list}" | sort -r); # reverse sort list for more readable output
for user_app in $user_remove_folder_list; do
  rm -rf "$user_app";
  sed -i "\:# Remove 'user requested' apps (from gapps-config):a \    rm -rf $user_app" $bkup_tail;
done;

# Remove any empty folders we may have created during the removal process
for i in /system/app /system/priv-app /system/vendor/pittpatt /system/usr/srec /system/etc/preferred-apps; do
  find "$i" -type d | xargs rmdir -p --ignore-fail-on-non-empty;
done;
# _____________________________________________________________________________________________________________________
#                                                  Perform Installs
ui_print "- Installing updated GApps";
ui_print " ";
set_progress 0.15;
for gapp_name in $core_gapps_list; do
  extract_app "Core/$gapp_name";
done;
set_progress 0.25;

EOFILE
echo "$KEYBDINSTALLCODE" >> "$build/META-INF/com/google/android/update-binary"
echo "$DATAINSTALLCODE" >> "$build/META-INF/com/google/android/update-binary"
tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'
# Progress Bar increment calculations for GApps Install process
set_progress 0.30;
gapps_count=$(echo "${gapps_list}" | wc -w); # Count number of GApps left to be installed
if [ "$gapps_count" -lt 1 ]; then gapps_count=1; fi; # Prevent division by zero
incr_amt=$(( 5000 / gapps_count )); # Determine increment factor of progress bar during GApps installation
prog_bar=3000; # Set Progress Bar start point (0.3000) for below

# Install the rest of GApps still in $gapps_list
for gapp_name in $gapps_list; do
  extract_app "GApps/$gapp_name"; # Installing User Selected GApps
  prog_bar=$((prog_bar + incr_amt));
  set_progress 0.$prog_bar;
done;

EOFILE
echo '# Create FaceLock lib symlink if FaceLock was installed
if ( contains "$gapps_list" "faceunlock" ); then
  mkdir -p "/system/app/FaceLock/lib/'"$ARCH"'";
  ln -sfn "/system/'"$LIBFOLDER"'/$faceLock_lib_filename" "/system/app/FaceLock/lib/'"$ARCH"'/$faceLock_lib_filename"; # create required symlink
  # Add same code to backup script to insure symlinks are recreated on addon.d restore
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"/system/'"$LIBFOLDER"'/$faceLock_lib_filename\" \"/system/app/FaceLock/lib/'"$ARCH"'/$faceLock_lib_filename\"" $bkup_tail;
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    mkdir -p \"/system/app/FaceLock/lib/'"$ARCH"'\"" $bkup_tail;
fi;
' >> "$build/META-INF/com/google/android/update-binary"
if [ "$API" -lt "23" ]; then
  echo '# Create WebView lib symlink if WebView was installed
if ( contains "$gapps_list" "webviewgoogle" ); then
  mkdir -p "/system/app/WebViewGoogle/lib/'"$ARCH"'";
  ln -sfn "/system/'"$LIBFOLDER"'/$WebView_lib_filename" "/system/app/WebViewGoogle/lib/'"$ARCH"'/$WebView_lib_filename"; # create required symlink' >> "$build/META-INF/com/google/android/update-binary"
  if [ "$LIBFOLDER" = "lib64" ]; then #on 64bit we also need to add 32 bit libs
    echo '  mkdir -p "/system/app/WebViewGoogle/lib/'"$fallback_arch"'";
  ln -sfn "/system/lib/$WebView_lib_filename" "/system/app/WebViewGoogle/lib/'"$fallback_arch"'/$WebView_lib_filename"; # create required symlink' >> "$build/META-INF/com/google/android/update-binary"
  fi
  echo '  # Add same code to backup script to insure symlinks are recreated on addon.d restore' >> "$build/META-INF/com/google/android/update-binary"
  if [ "$LIBFOLDER" = "lib64" ]; then #on 64bit we also need to add 32 bit libs
    echo '  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"/system/lib/$WebView_lib_filename\" \"/system/app/WebViewGoogle/lib/'"$fallback_arch"'/$WebView_lib_filename\"" $bkup_tail;
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    mkdir -p \"/system/app/WebViewGoogle/lib/'"$fallback_arch"'\"" $bkup_tail;' >> "$build/META-INF/com/google/android/update-binary"
  fi
  echo '  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"/system/'"$LIBFOLDER"'/$WebView_lib_filename\" \"/system/app/WebViewGoogle/lib/'"$ARCH"'/$WebView_lib_filename\"" $bkup_tail;
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    mkdir -p \"/system/app/WebViewGoogle/lib/'"$ARCH"'\"" $bkup_tail;
fi;' >> "$build/META-INF/com/google/android/update-binary"
fi
tee -a "$build/META-INF/com/google/android/update-binary" > /dev/null <<'EOFILE'

# Copy g.prop over to /system/etc
cp -f /tmp/g.prop $g_prop;
# _____________________________________________________________________________________________________________________
#                                                  Build and Install Addon.d Backup Script
# Add 'other' Removals to addon.d script
set_progress 0.80;
other_list=$(echo "${other_list}" | sort -r); # reverse sort list for more readable output
for other_name in $other_list; do
  sed -i "\:# Remove 'other' apps (per installer.data):a \    rm -rf $other_name" $bkup_tail;
done;

# Add 'priv-app' Removals to addon.d script
privapp_list=$(echo "${privapp_list}" | sort -r); # reverse sort list for more readable output
for privapp_name in $privapp_list; do
  sed -i "\:# Remove 'priv-app' apps from 'app' (per installer.data):a \    rm -rf $privapp_name" $bkup_tail;
done;

# Add 'required' Removals to addon.d script
reqd_list=$(echo "${reqd_list}" | sort -r); # reverse sort list for more readable output
for reqdapp_name in $reqd_list; do
  sed -i "\:# Remove 'required' apps (per installer.data):a \    rm -rf $reqdapp_name" $bkup_tail;
done;

# Create final addon.d script in system
bkup_header="#!/sbin/sh\n# \n# /system/addon.d/70-gapps.sh\n#\n. /tmp/backuptool.functions\n\nlist_files() {\ncat <<EOF"
bkup_list="$bkup_list"$'\n'"etc/g.prop"; # add g.prop to backup list
bkup_list=$(echo "${bkup_list}" | sort -u| sed '/^$/d'); # sort list & remove duplicates and empty lines
mkdir -p /system/addon.d;
echo -e "$bkup_header" > /system/addon.d/70-gapps.sh;
echo -e "$bkup_list" >> /system/addon.d/70-gapps.sh;
cat $bkup_tail >> /system/addon.d/70-gapps.sh;
# _____________________________________________________________________________________________________________________
#                                                  Fix Permissions
set_progress 0.83;
ui_print "- Fixing permissions & contexts";
ui_print " ";
set_perm_recursive 0 0 755 644 "/system/app" "/system/framework" "/system/lib" "/system/lib64" "/system/priv-app" "/system/usr/srec" "/system/vendor/pittpatt" "/system/etc/permissions" "/system/etc/preferred-apps";

set_progress 0.85;
set_perm_recursive 0 0 755 755 "/system/addon.d";

set_progress 0.87;
find /system/vendor/pittpatt -type d -exec chown 0.2000 '{}' \; -exec chown 0:2000 '{}' \; # Change pittpatt folders to root:shell per Google Factory Settings

set_perm 0 0 644 $g_prop;

# Set contexts on all files we installed
set_progress 0.88;
ch_con_recursive "/system/app" "/system/framework" "/system/lib" "/system/lib64" "/system/priv-app" "/system/usr/srec" "/system/vendor/pittpatt" "/system/etc/permissions" "/system/etc/preferred-apps" "/system/addon.d";
ch_con $g_prop;

set_progress 0.92;
quit;

ui_print "- Installation complete!";
ui_print " ";
exxit 0;
EOFILE
}
