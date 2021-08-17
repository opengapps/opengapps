EOF
}

mount_generic() {
  local device_abpartition=$(getprop ro.build.ab_update)
  local partitions="$*"
  if [ -z "$device_abpartition" ]; then
    # We're on an A only device
    local partition
    for partition in $partitions; do
      if [ "$(getprop ro.boot.dynamic_partitions)" = "true" ]; then
        mount -o ro -t auto /dev/block/mapper/"$partition" /"$partition" 2> /dev/null
        blockdev --setrw /dev/block/mapper/"$partition" 2> /dev/null
        mount -o rw,remount -t auto /dev/block/mapper/"$partition" /"$partition" 2> /dev/null
      else
        mount -o ro -t auto /"$partition" 2> /dev/null
        mount -o rw,remount -t auto /"$partition" 2> /dev/null
      fi
    done
  fi
}

# Backup/Restore using /sdcard if the installed GApps size plus a buffer for other addon.d backups (204800=200MB) is larger than /tmp
installed_gapps_size_kb=$(grep "^installed_gapps_size_kb" $TMP/gapps.prop | cut -d '=' -f 2)
if [ ! "$installed_gapps_size_kb" ]; then
  installed_gapps_size_kb="$(cd $SYS; size=0; for n in $(du -ak $(list_files) | cut -f 1); do size=$((size+n)); done; echo "$size")"
  echo "installed_gapps_size_kb=$installed_gapps_size_kb" >> $TMP/gapps.prop
fi

free_tmp_size_kb=$(grep "^free_tmp_size_kb" $TMP/gapps.prop | cut -d '=' -f 2)
if [ ! "$free_tmp_size_kb" ]; then
  free_tmp_size_kb="$(echo $(df -k $TMP | tail -n 1) | cut -d ' ' -f 4)"
  echo "free_tmp_size_kb=$free_tmp_size_kb" >> $TMP/gapps.prop
fi

buffer_size_kb=204800
if [ $((installed_gapps_size_kb + buffer_size_kb)) -ge "$free_tmp_size_kb" ]; then
  C=/sdcard/tmp-gapps
fi

# Get ROM SDK from installed GApps
rom_build_sdk=$(grep "^rom_build_sdk" $TMP/gapps.prop | cut -d '=' -f 2)
if [ ! "$rom_build_sdk" ]; then
  rom_build_sdk="$(cd $SYS; grep "^ro.addon.sdk" etc/g.prop | cut -d '=' -f 2)"
  echo "rom_build_sdk=$rom_build_sdk" >> $TMP/gapps.prop
fi

case "$1" in
  backup)
    list_files | while read -r FILE DUMMY; do
      backup_file "$S"/"$FILE"
    done

    umount /system_ext /product /vendor 2> /dev/null
  ;;
  restore)
    list_files | while read -r FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file "$S"/"$FILE" "$R"
    done
  ;;
  pre-backup)
    mount_generic system_ext product vendor
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    mount_generic system_ext product vendor

    # Remove Stock/AOSP apps (from GApps Installer)

    # Remove 'other' apps (per installer.data)

    # Remove 'priv-app' apps from 'app' (per installer.data)

    # Remove 'required' apps (per installer.data)

    # Remove 'user requested' apps (from gapps-config)

  ;;
  post-restore)
    # Recreate required symlinks (from GApps Installer)

    # Apply build.prop changes (from GApps Installer)

    # Re-pre-ODEX APKs (from GApps Installer)

    # Remove any empty folders we may have created during the removal process
    for i in $SYS/app $SYS/priv-app $SYS/vendor/pittpatt $SYS/usr/srec; do
      if [ -d $i ]; then
        find $i -type d -exec rmdir -p '{}' \+ 2>/dev/null
      fi
    done

    # Fix ownership/permissions and clean up after backup and restore from /sdcard
    find $SYS/vendor/pittpatt -type d -exec chown 0:2000 '{}' \; 2>/dev/null # Change pittpatt folders to root:shell per Google Factory Settings
    for i in $(list_files); do
      chown root:root "$SYS/$i"
      chmod 644 "$SYS/$i"
      chmod 755 "$(dirname "$SYS/$i")" "$(dirname "$SYS/$i")/../"
      case $i in
        */overlay/*) chcon -h u:object_r:vendor_overlay_file:s0 "$SYS/$i";;
      esac
    done

    umount /system_ext /product /vendor 2> /dev/null

    if [ "$rom_build_sdk" -ge "26" ]; then # Android 8.0+ uses 0600 for its permission on build.prop
      chmod 600 "$SYS/build.prop"
    fi
    rm -rf /sdcard/tmp-gapps
  ;;
esac
