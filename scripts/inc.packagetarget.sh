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
    zopfli=""
    if [ -n "$ZIPALIGNRECOMPRESS" ]; then
      zopfli="-z"
    fi
    zipalign -f -p $zopfli 4 "$f.orig" "$f"
    rm "$f.orig"
  done
}

commonscripts() {
  copy "$SCRIPTS/bkup_tail.sh" "$build"
  EXTRACTFILES="$EXTRACTFILES bkup_tail.sh"

  install -d "$build/META-INF/com/google/android"
  echo "# Dummy file; update-binary is a shell script.">"$build/META-INF/com/google/android/updater-script"

  makegappsremovetxt "gapps-remove.txt"
  makegprop "g.prop"
  makeinstallersh "installer.sh"
  bundlebusybox
  bundlexzdec
  bundlezip
  makeupdatebinary "META-INF/com/google/android/update-binary" "busybox" "installer.sh" "$EXTRACTFILES" "$CHMODXFILES" # execute as last so that $EXTRACTFILES and $CHMODXFILES are complete
  bundlelicense #optionally add a LICENSE file to the package
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

bundlebusybox() {
  case "$ARCH" in #Include busybox binary
    arm*) busyboxbin="busybox-arm";;
    x86*) busyboxbin="busybox-x86";;
  esac
  copy "$SCRIPTS/busybox-resources/$busyboxbin" "$build/$busyboxbin"
  EXTRACTFILES="$EXTRACTFILES $busyboxbin"
  CHMODXFILES="$CHMODXFILES $busyboxbin"
}

bundlexzdec() {
  case "$ARCH" in #Include xzdec binary
    arm*) xzdecbin="xzdec-arm";;
    x86*) xzdecbin="xzdec-x86";;
  esac
  copy "$SCRIPTS/xz-resources/$xzdecbin" "$build/$xzdecbin"
  EXTRACTFILES="$EXTRACTFILES $xzdecbin"
  CHMODXFILES="$CHMODXFILES $xzdecbin"
}

bundlezip() {
  case "$ARCH" in #Include zip binary
    arm*) zipbin="zip-arm";;
    x86*) zipbin="zip-x86";;
  esac
  copy "$SCRIPTS/infozip-resources/$zipbin" "$build/$zipbin"
  EXTRACTFILES="$EXTRACTFILES $zipbin"
  CHMODXFILES="$CHMODXFILES $zipbin"
}

bundlelicense() {
  if [ -n "$OPENGAPPSLICENSEFILE" ] && [ -e "$OPENGAPPSLICENSEFILE" ]; then
    echo "INFO: using $OPENGAPPSLICENSEFILE as LICENSE file"
    copy "$OPENGAPPSLICENSEFILE" "$build/LICENSE"
  elif [ -e "LICENSE" ]; then
    copy "LICENSE" "$build/LICENSE"
  fi
}

compressapp() {
  compression="$COMPRESSION"
  case "$compression" in
    xz) checktools xz
        csuf=".xz"
        compress() {
          XZ_OPT='-9e -C crc32' tar --remove-files -cJf "$1.tar.xz" "$1"
        }
    ;;
    lz) checktools lzip
        csuf=".lz"
        compress() {
          tar --remove-files -cf - "$1" | lzip -m 273 -s 128MiB -o "$1.tar" #.lz is added by lzip; specify the compression parameters manually to get good results
        }
    ;;
    none)
        csuf=""
        compress() {
          tar --remove-files -cf "$1.tar" "$1"
        }
    ;;
    *)  echo "ERROR: Unsupported compression method! Aborting..."; exit 1;;
  esac
  hash="$(tar -cf - "$2" | md5sum | cut -f1 -d' ')"

  if [ -f "$CACHE/$hash.tar$csuf" ]; then #we have this compressed app in cache
    echo "Fetching $1$2 from the cache"
    rm -rf "$2" #remove the folder
    touch -a "$CACHE/$hash.tar$csuf" #mark this cache object as recently accessed
    cp "$CACHE/$hash.tar$csuf" "$2.tar$csuf" #copy from the cache
  else
    if [ -n "$3" ] && [ -n "$4" ]; then
      echo "Thread: $3 | FreeRAM: $4 | Compressing Package: $1$2"
    else
      echo "Compressing Package: $1$2"
    fi
    compress "$2"
    if [ $? != 0 ]; then
      echo "ERROR: compressing $1$2 failed, aborting."
      exit 1
    fi
    cp "$2.tar$csuf" "$CACHE/$hash.tar$csuf" #copy into the cache
  fi
  touch -d "2008-02-28 21:33:46.000000000 +0100" "$2.tar$csuf"
  sync
}

createzip() {
  echo "INFO: Total size uncompressed applications: $(du -hs "$build" | awk '{ print $1 }')"

  find "$build" -exec touch -d "2008-02-28 21:33:46.000000000 +0100" {} \;
  cd "$build"

  MEMORY_MIN=800000 # Minimum of RAM required (for single thread) on x86_64 machine based on XZ's documentation (which is a comparable algorithm to lzip)
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
      apk="$(find "$f/" -name "*.apk" -type f | head -n 1)"  # we assume the classes*.dex are around the same size in all APK variants
      if [ -f "$apk" ] && ! (unzip -ql "$apk" | grep -q "META-INF/MANIFEST.MF" && unzip -p "$apk" "META-INF/MANIFEST.MF" | grep -q "$classes.dex"); then
        printf "%s\t%s\t%d\n" "$f" "odex" "$(($(echo "$(unzip -ql "$apk" "classes*.dex" | tail -n 1)" | awk '{print $1"*(("$2"/2)+2)/1024"}')))" >> "$build/app_sizes.txt"  # estimation heuristic: size-dexfiles * ((#-dexfiles/2)+2); bytes -> KiB
      fi
      for g in $(ls "$f"); do
        foldersize="$(du -ck "$f/$g/" | tail -n1 | awk '{ print $1 }')"
        printf "%s\t%s\t%d\n" "$f" "$g" "$foldersize" >> "$build/app_sizes.txt"
      done

      # Use parallel mode only if we have memory metric and have more than 1 CPU
      if [ $THREADS -gt 1 ] && [ $MEMORY -gt 0 ]; then
        # Wait if we reached RAM or THREADS limit
        tries=0; while true; do
          # Count still running compressapp instances
          threads=0; for p in $pidlist; do test -d /proc/$p && threads=$((threads+1)); done
          memory=$(grep "MemAvailable:" /proc/meminfo | awk '{print $2}')

          # Check if reached our limits (3/4 of RAM or THREADS), wait if we are
          if [ $threads -ge $THREADS ] || [ $MEMORY -ge $memory ] || [ $memory -lt $MEMORY_MIN ]; then
            sleep 5
            # Update tries counter
            tries=$((tries+1))
            # If we are trying for more then 180*5 seconds, we bail out (in case machine is to low on memory or CPU we won't run forever!)
            if [ $tries -gt 180 ]; then
              echo "ERROR: Seems like this machine is too slow or was unable to collect enought usable memory for compression, aborting."
              exit 1
            fi
            continue
          else
            break
         fi
        done

        # Spawn compressapp thread
        compressapp "$d" "$f" "$threads" "$memory" &
        # Collect resulting PID
        pidlist="$pidlist $!"
      else
        # Call compressapp
        compressapp "$d" "$f"
      fi
    done
  done

  for p in $pidlist; do wait $p; done

  echo "INFO: Total size compressed applications: $(du -hs "$build" | awk '{ print $1 }')"

  unsignedzip="$BUILD/$ARCH/$API/$VARIANT.zip"
  if [ -n "$OUTFILE" ]; then
    signedzip="$( eval "echo \"$OUTFILE\"")"
  else
    signedzip="$OUTFOLDER/open_gapps-$ARCH-$PLATFORM-$VARIANT-$DATE-UNOFFICIAL.zip"
  fi

  if [ -f "$unsignedzip" ]; then
    rm "$unsignedzip"
  fi
  cd "$build"
  echo "Packaging and signing $signedzip..."
  zip -q -r -D -X -$ZIPCOMPRESSIONLEVEL "$unsignedzip" ./* #don't doublequote zipfolders, contains multiple (safe) arguments
  cd "$TOP"
  signzip
}

signzip() {
  install -d "$(dirname "$signedzip")"
  if [ -f "$signedzip" ]
  then
    rm "$signedzip"
  fi

  if [ -z "$CERTIFICATEFILE" ] || [ ! -e "$CERTIFICATEFILE" ]; then
    CERTIFICATEFILE="$CERTIFICATES/testkey.x509.pem"
  else
    echo "INFO: using $CERTIFICATEFILE as certificate file"
  fi
  if [ -z "$KEYFILE" ] || [ ! -e "$KEYFILE" ]; then
    KEYFILE="$CERTIFICATES/testkey.pk8"
  else
    echo "INFO: using $KEYFILE as cryptographic key file"
  fi

  if java -Xmx3072m -jar "$SCRIPTS/inc.signapk.jar" -w "$CERTIFICATEFILE" "$KEYFILE" "$unsignedzip" "$signedzip"; then #if signing did succeed
    rm "$unsignedzip"
  else
    echo "ERROR: Creating Flashable ZIP-file failed, unsigned file can be found at $unsignedzip"
    exit 1
  fi
  echo "SUCCESS: Built Open GApps variation $VARIANT with API $API level for $ARCH as $signedzip"
}
