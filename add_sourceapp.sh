#!/bin/sh
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
TOP="$(realpath .)"
SOURCES="$TOP/sources"
LOWESTAPI_all="19"
LOWESTAPI_arm="19"
LOWESTAPI_arm64="21"
LOWESTAPI_x86="19"
LOWESTAPI_x86_64="21"
command -v aapt >/dev/null 2>&1 || { echo "aapt is required but it's not installed.  Aborting." >&2; exit 1; }
command -v file >/dev/null 2>&1 || { echo "file is required but it's not installed.  Aborting." >&2; exit 1; }
command -v install >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; } #coreutils also contains the basename command
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but it's not installed.  Aborting." >&2; exit 1; }

getarchitectures() {
  architectures=""
  if [ -z "$native" ]; then
    echo "No native-code specification defined"
    #Some packages don't have native-code specified, but are still depending on it.
    #So an extra check is necessary before declaring it suitable for all platforms
    libfiles=$(unzip -qql "$1" lib/* | tr -s ' ' | cut -d ' ' -f5-)
    for lib in $libfiles; do
      #this gives all files found in the lib-folder(s), check their paths for which architectures' libs are included
      arch="$(echo "$lib" | awk 'BEGIN { FS = "/" } ; {print $2}')"
      echo "$architectures" | grep -q "$arch"
      if [ $? -eq 1 ]; then #only add if this architecture is not yet in the list
        architectures="$architectures$arch "
        echo "Manually found native code for: $arch"
      fi
    done
    if [ -z "$architectures" ]; then #If the package really has no native code
      architectures="all"
    fi
  else
    for arch in $native; do
      architectures="$architectures$arch "
    done
  fi
  echo "Native code for architecture(s): $architectures"
}

getapkproperties(){
  apkproperties="$(aapt dump badging "$1" 2>/dev/null)"
  name="$(echo "$apkproperties" | grep "application-label:" | sed 's/application-label://g' | sed "s/'//g")"
  package="$(echo "$apkproperties" | grep package: | awk '{print $2}' | sed s/name=//g | sed s/\'//g | awk '{print tolower($0)}')"
  versionname="$(echo "$apkproperties" | grep "versionName" | awk '{print $4}' | sed s/versionName=// | sed "s/'//g")"
  versioncode="$(echo "$apkproperties" | grep "versionCode=" | awk '{print $3}' | sed s/versionCode=// | sed "s/'//g")"
  sdkversion="$(echo "$apkproperties" | grep "sdkVersion:" | sed 's/sdkVersion://' | sed "s/'//g")"
  compatiblescreens="$(echo "$apkproperties" | grep "compatible-screens:")"
  native="$(echo "$apkproperties" | grep "native-code:" | sed 's/native-code://g' | sed "s/'//g")"
  leanback="$(echo "$apkproperties" | grep "android.software.leanback" | awk -F [.\'] '{print $(NF-1)}')"
  case "$versionname" in
    *leanback*) leanback="leanback";;
  esac
}

installapk() {
  architecture="$1"
  eval "lowestapi=\$LOWESTAPI_$architecture"

  if [ -n "$leanback" ]; then
    package="$package.$leanback" #special leanback versions need a different packagename
    echo "Leanback edition"
  fi

  if [ "$sdkversion" -lt "$lowestapi" ]; then
    for i in $(seq "$(($sdkversion + 1))" "$lowestapi")
    do
      existing="$SOURCES/$architecture/$type/$package/$i/$dpis"
      if [ -e "$existing" ];then
        echo "ERROR: API level is lower than minimum level $lowestapi and lower than existing level $i of the same package"
        return 1;
      fi
    done
  fi

  #targetlocation: sources/platform/type/package/sdkversion/dpi1-dpi2-dpi3/versioncode.apk
  target="$SOURCES/$1/$type/$package/$sdkversion/$dpis"
  install -d "$target"
  if stat --printf='' "$target/"* 2>/dev/null; then
    existing=$(find "$target/" -name "*.apk" | sort -r | cut -c1-) #we only look for lowercase .apk, since basename later assumes the same
    echo "Existing version $existing"
    existingversion=$(basename -s.apk "$existing")
    if [ "$versioncode" -gt "$existingversion" ]; then
      echo "Replaced with $target/$versioncode.apk"
      rm "$existing"
      install -D "$apk" "$target/$versioncode.apk"
    else
      echo "ERROR: APK is not newer than existing"
    fi
  else
    install -D "$apk" "$target/$versioncode.apk"
    echo "SUCCESS: Added $target/$versioncode.apk"
  fi

  if [ "$sdkversion" -le "$lowestapi" ]; then
    for i in $(seq 1 "$((sdkversion - 1))")
    do
      remove="$SOURCES/$architecture/$type/$package/$i/$dpis"
      if [ -e "$remove" ];then
        rm -rf "$remove"
        rmdir --ignore-fail-on-non-empty "$(dirname "$remove")"
        echo "Cleaned up old API: $remove"
      fi
    done
  fi
}

addapk() {
  apk="$1"
  getapkproperties "$apk"

  echo "Importing $name"
  echo "Package $package | VersionName $versionname | VersionCode $versioncode | API level $sdkversion"

  if [ "$compatiblescreens" = "" ]; then # we can't use -z here, because there can be a linecontrol character or such in it
    dpis="nodpi"
    echo "Universal DPI package"
  else
    dpis=$(echo "$compatiblescreens" | grep "compatible-screens:" | grep -oE "/([0-9][0-9])[0-9]" | uniq | tr -d '\012\015' | tr '/' '-' | cut -c 2-)
    echo "Package supports DPIs: $(echo "$dpis" | tr '-' ' ')"
  fi

  if [ "$package" = "com.google.android.backuptransport" ] \
  || [ "$package" = "com.google.android.feedback" ] \
  || [ "$package" = "com.google.android.gms" ] \
  || [ "$package" = "com.google.android.googlequicksearchbox" ] \
  || [ "$package" = "com.google.android.gsf" ] \
  || [ "$package" = "com.google.android.gsf.login" ] \
  || [ "$package" = "com.google.android.launcher" ] \
  || [ "$package" = "com.google.android.onetimeinitializer" ] \
  || [ "$package" = "com.google.android.partnersetup" ] \
  || [ "$package" = "com.google.android.setupwizard" ] \
  || [ "$package" = "com.google.android.tag" ] \
  || [ "$package" = "com.google.android.talk" ] \
  || [ "$package" = "com.google.android.apps.walletnfcrel" ]; then
    type="priv-app"
  else
    type="app"
  fi

  getarchitectures "$apk"
  #We manually check for each of our set of supported architectures
  #We assume NO universal packages for 32vs64 bit, so start with the 'highest' architectures first, if it matches one of those, we will NOT add it to a lower architecture
  if echo "$architectures" | grep -q "arm64"; then #no space, all arm64 types are valid
    installapk "arm64"
  else
    if echo "$architectures" | grep -q "armeabi"; then #no space, all armearbi types are valid
      installapk "arm"
    fi
  fi
  if echo "$architectures" | grep -q "x86_64 "; then
    installapk "x86_64"
  else
    if echo "$architectures" | grep -q "x86 "; then
      installapk "x86"
    fi
  fi
  if echo "$architectures" | grep -q "all"; then #no space (single entry)
    installapk "all"
  fi
}

for argument in "$@"; do
  file="$(readlink -f "$argument")"
  if [ -f "$file" ]
  then
    filetype="$(file -b -0 "$file" | tr '[:upper:]' '[:lower:]')"
    case "$filetype" in
      *jar*|*zip*)
        if aapt dump configurations "$file" >/dev/null
        then
          addapk "$file"
        else
          echo "ERROR: File $file not a valid APK!"
        fi;;
      *x86-64*)
        install -D "$file" "$SOURCES/x86_64/lib64/$(basename "$file")"
        echo "SUCCESS: Added $file to x86_64/lib64/";;
      *aarch64*)
        if [ "$(basename "$file")" = "libfrsdk.so" ]; then
          install -D "$file" "$SOURCES/arm/vendor/lib64/$(basename "$file")"
          echo "SUCCESS: Added $file to arm64/vendor/lib64/"
        else
          install -D "$file" "$SOURCES/arm64/lib64/$(basename "$file")"
          echo "SUCCESS: Added $file to arm64/lib64/"
        fi;;
      *32-bit*intel*)
        install -D "$file" "$SOURCES/x86/lib/$(basename "$file")"
        echo "SUCCESS: Added $file to x86/lib/";;
      *32-bit*arm*)
        if [ "$(basename "$file")" = "libfrsdk.so" ]; then
          install -D "$file" "$SOURCES/arm/vendor/lib/$(basename "$file")"
          echo "SUCCESS: Added $file to arm/vendor/lib/"
        else
          install -D "$file" "$SOURCES/arm/lib/$(basename "$file")"
          echo "SUCCESS: Added $file to arm/lib/"
        fi;;
      *)
        echo "ERROR: File $f has an unrecognized filetype!";;
    esac
  else
    echo "ERROR: File $file does not exist!"
  fi
done

#Full list of 'our' architecture classification compared to the Android NDK architectures:
#arm:
#	armeabi - ARMv5TE based CPU with software floating point operations;
#	armeabi-v7a - ARMv7 based devices with hardware FPU instructions
#arm64:
#	arm64-v8a - ARMv8 AArch64 instruction set
#x86:
#	x86 - IA-32 instruction set
#x86_64:
#	x86_64 - Intel64 instruction set
#
#unsupported at the moment:
#mips - MIPS32 instruction set
#mips64 - MIPS64 instruction set
