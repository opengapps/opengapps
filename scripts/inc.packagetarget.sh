#This file is part of The Open GApps script of @mfonville.
#
#	The Open GApps scripts are free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	These scripts are distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
alignbuild() {
  for f in $(find "$build" -name '*.apk'); do
    mv "$f" "$f.orig"
    zipalign -f -p 4 "$f.orig" "$f" #consider recompression with Zopfli using -z for production use
    rm "$f.orig"
  done
}

commonscripts() {
  copy "$SCRIPTS/bkup_tail.sh" "$build"
  EXTRACTFILES="$EXTRACTFILES bkup_tail.sh"

  install -d "$build/META-INF/com/google/android"
  echo "# Dummy file; update-binary is a shell script.">"$build/META-INF/com/google/android/updater-script"

  makegappsremovetxt
  makegprop
  makeinstallerdata
  bundlexz # on arm platforms we can include our own xz binary
  makeupdatebinary # execute as last, it contains $EXTRACTFILES from the previous commands
}

aromascripts() {
  aromaupdatebinary
  makearomaconfig
  install -d "$build/META-INF/com/google/android/aroma" #not necessary, but is safe
  copy "$SCRIPTS/aroma-resources/fonts" "$build/META-INF/com/google/android/aroma/fonts"
  copy "$SCRIPTS/aroma-resources/icons" "$build/META-INF/com/google/android/aroma/icons"
  copy "$SCRIPTS/aroma-resources/langs" "$build/META-INF/com/google/android/aroma/langs"
  copy "$SCRIPTS/aroma-resources/scripts" "$build/META-INF/com/google/android/aroma/scripts"
  copy "$SCRIPTS/aroma-resources/themes" "$build/META-INF/com/google/android/aroma/themes"
  copy "$SCRIPTS/aroma-resources/ttf" "$build/META-INF/com/google/android/aroma/ttf"
  copy "$SCRIPTS/aroma-resources/open.png" "$build/META-INF/com/google/android/aroma"
}

aromaupdatebinary() {
  if [ -f "$build/META-INF/com/google/android/update-binary-installer" ]
  then
    rm "$build/META-INF/com/google/android/update-binary-installer"
  fi
  mv "$build/META-INF/com/google/android/update-binary" "$build/META-INF/com/google/android/update-binary-installer"
  copy "$SCRIPTS/aroma-resources/update-binary" "$build/META-INF/com/google/android/update-binary"
}

bundlexz() {
  case "$ARCH" in #Include our own 32-bit xz-decompression binary
    arm*) xzbin="xzdec-arm";;
    x86*) xzbin="xzdec-x86";;
  esac
  copy "$SCRIPTS/xz-resources/$xzbin" "$build/xzdec"
  EXTRACTFILES="$EXTRACTFILES xzdec"
}

createxz() {
      hash="$(tar -cf - "$f" | md5sum | cut -f1 -d' ')"

      if [ -f "$CACHE/$hash.tar.xz" ]; then #we have this xz in cache
        echo "Fetching $d$f from the cache"
        rm -rf "$f" #remove the folder
        touch -a "$CACHE/$hash.tar.xz" #mark this xz as accessed
        cp "$CACHE/$hash.tar.xz" "$f.tar.xz" #copy from the cache
      else
        echo "Thread: $threads | FreeRAM: $memory | Compressing Package: $d$f"
        XZ_OPT=-9e tar --remove-files -cJf "$f.tar.xz" "$f"
        if [ $? != 0 ]; then
          echo "ERROR: XZ compression failed, aborting."
          exit 1
        fi
        cp "$f.tar.xz" "$CACHE/$hash.tar.xz" #copy into the cache
      fi
      touch -d "2008-02-28 21:33:46.000000000 +0100" "$f.tar.xz"
      sync
}

createzip() {
  find "$build" -exec touch -d "2008-02-28 21:33:46.000000000 +0100" {} \;
  cd "$build"

  MEMORY_MIN=800000 # Minimum of RAM required (for single thread) on x86_64 machine [~701MB for xz, 2*25KB for bash and some spare]
  THREADS="$(($(nproc)))"

  if ! grep -q "MemAvailable:" /proc/meminfo; then
    MEMORY=0
  else
    MEMORY="$(($(grep "MemAvailable:" /proc/meminfo | awk '{print $2}') / 4))"
  fi

  if [ $MEMORY = 0 ] || [ $MEMORY -lt $MEMORY_MIN ]; then
    echo "WARNING: Can't establish if enough free memory is available: parallel compression mode disabled."
    MEMORY=0
    THREADS=1
  fi

  pidlist=""
  for d in $(ls -d */ | grep -v "META-INF"); do #notice that d will end with a slash, ls is safe here because there are no directories with spaces
    cd "$build/$d"
    for f in $(ls); do # ls is safe here because there are no directories with spaces
      for g in $(ls "$f"); do
        foldersize="$(du -ck "$f/$g/" | tail -n1 | awk '{ print $1 }')"
        printf "%s\t%s\t%d\n" "$f" "$g" "$foldersize" >> "$build/app_sizes.txt"
      done

      # Use parallel mode only if we have memory metric and have more then 1 CPU
      if [ $THREADS -gt 1 ] && [ $MEMORY -gt 0 ]; then
        # Wait if we reached RAM or THREADS limit
        tries=0; while true; do
          # Count still running createxz instances
          threads=0; for p in $pidlist; do test -d /proc/$p && threads=$((threads+1)); done
          memory=$(grep "MemAvailable:" /proc/meminfo | awk '{print $2}')

          # Check if reached our limits (3/4 of RAM or THREADS), wait if we are
          if [ $threads -ge $THREADS ] || [ $MEMORY -ge $memory ] || [ $memory -lt $MEMORY_MIN ]; then
            sleep 5
            # Update tries counter
            tries=$((tries+1))
            # If we are trying for more then 180*5 seconds, we bail out (in case machine is to low on memory or CPU we won't run forever!)
            if [ $tries -gt 180 ]; then
              echo "Seems like this machine is too slow or was unable to collect enought usable memory for compression, aborting."
              exit 1
            fi
            continue
          else
            break
         fi
        done

        # Spawn xz creation
        createxz $d &
        # Collect resulting PID
        pidlist="$pidlist $!"
      else
        # Call xz creation
        createxz $d
      fi
    done
  done

  echo "Waiting for components to be prepared..."
  for p in $pidlist; do wait $p; done
  echo "All components are ready."

  unsignedzip="$BUILD/$ARCH/$API/$VARIANT.zip"
  signedzip="$OUT/open_gapps-$ARCH-$PLATFORM-$VARIANT-$DATE.zip"

  if [ -f "$unsignedzip" ]; then
    rm "$unsignedzip"
  fi
  cd "$build"
  echo "Packaging and signing $signedzip..."
  # Store only the files in the zip without compressing them (-0 switch): further compression will be useless and will slow down the building process
  zip -q -r -D -X -0 "$unsignedzip" ./* #don't doublequote zipfolders, contains multiple (safe) arguments
  cd "$TOP"
  signzip
}

signzip() {
  install -d "$OUT"
  if [ -f "$signedzip" ]
  then
    rm "$signedzip"
  fi

  if java -Xmx3072m -jar "$SCRIPTS/inc.signapk.jar" -w "$CERTIFICATES/testkey.x509.pem" "$CERTIFICATES/testkey.pk8" "$unsignedzip" "$signedzip"; then #if signing did succeed
    rm "$unsignedzip"
  else
    echo "ERROR: Creating Flashable ZIP-file failed, unsigned file can be found at $unsignedzip"
    exit 1
  fi
  echo "SUCCESS: Built Open GApps variation $VARIANT with API $API level for $ARCH as $signedzip"
}
