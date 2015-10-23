EOF
}

# Backup/Restore using /sdcard if the installed GApps size plus a buffer for other addon.d backups (204800=200MB) is larger than /tmp
installed_gapps_size_kb=$(grep "^installed_gapps_size_kb" /tmp/gapps.prop | cut -d= -f2)
if [ ! "$installed_gapps_size_kb" ]; then
  installed_gapps_size_kb=$(cd /system; du -ak $(list_files) | awk '{ i+=$1 } END { print i }')
  echo "installed_gapps_size_kb=$installed_gapps_size_kb" >> /tmp/gapps.prop
fi

free_tmp_size_kb=$(grep "^free_tmp_size_kb" /tmp/gapps.prop | cut -d= -f2)
if [ ! "$free_tmp_size_kb" ]; then
  free_tmp_size_kb=$(df -k /tmp | tail -n 1 | awk '{ print $4 }')
  echo "free_tmp_size_kb=$free_tmp_size_kb" >> /tmp/gapps.prop
fi

buffer_size_kb=204800
if [ $((installed_gapps_size_kb + buffer_size_kb)) -ge "$free_tmp_size_kb" ]; then
  C=/sdcard/tmp-gapps
fi

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      backup_file "$S"/"$FILE"
    done
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file "$S"/"$FILE" "$R"
    done
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Remove Stock/AOSP apps (from GApps Installer)

    # Remove 'other' apps (per installer.data)

    # Remove 'priv-app' apps from 'app' (per installer.data)

    # Remove 'required' apps (per installer.data)

  ;;
  post-restore)
    # Recreate required symlinks (from GApps Installer)

    # Remove any empty folders we may have created during the removal process
    for i in /system/app /system/priv-app /system/vendor/pittpatt /system/usr/srec; do
        find $i -type d | xargs rmdir -p --ignore-fail-on-non-empty;
    done;
    # Fix ownership/permissions and clean up after backup and restore from /sdcard
    for i in $(list_files); do
      busybox chown root.root "/system/$i"
      busybox chmod 644 "/system/$i"
      busybox chmod 755 $(busybox dirname "/system/$i")
    done
    rm -rf /sdcard/tmp-gapps
  ;;
esac
