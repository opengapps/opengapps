EOF
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

case "$1" in
  backup)
    list_files | while read -r FILE DUMMY; do
      backup_file "$S"/"$FILE"
    done
  ;;
  restore)
    list_files | while read -r FILE REPLACEMENT; do
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

    # Remove 'user requested' apps (from gapps-config)

  ;;
  post-restore)
    # Recreate required symlinks (from GApps Installer)

    # Apply build.prop changes (from GApps Installer)

    # Re-pre-ODEX APKs (from GApps Installer)

    # Remove any empty folders we may have created during the removal process
    for i in $SYS/app $SYS/priv-app $SYS/vendor/pittpatt $SYS/usr/srec; do
      if [ -d $i ]; then
        find $i -type d -exec rmdir -p '{}' \+ 2>/dev/null;
      fi
    done;
    # Fix ownership/permissions and clean up after backup and restore from /sdcard
    find $SYS/vendor/pittpatt -type d -exec chown 0:2000 '{}' \; # Change pittpatt folders to root:shell per Google Factory Settings
    for i in $(list_files); do
      chown root:root "$SYS/$i"
      chmod 644 "$SYS/$i"
      chmod 755 "$(dirname "$SYS/$i")"
        if [ "$API" -ge "26" ]; then # Android 8.0+ uses 0600 for its permission on build.prop
          chmod 600 "$SYS/build.prop"
        fi
    done
    rm -rf /sdcard/tmp-gapps
  ;;
esac
