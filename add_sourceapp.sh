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

command -v realpath >/dev/null 2>&1 || { echo "realpath is required but it's not installed, aborting." >&2; exit 1; }
TOP="$(realpath .)"
SOURCES="$TOP/sources"
SCRIPTS="$TOP/scripts"
CERTIFICATES="$SCRIPTS/certificates"
. "$SCRIPTS/inc.sourceshelper.sh"
. "$SCRIPTS/inc.tools.sh"
BETA=""

# Check tools
checktools aapt file coreutils jarsigner keytool openssl unzip

installapk() {
  architecture="$1"
  eval "lowestapi=\$LOWESTAPI_$architecture"

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
  if [ "$dpis" = "nodpi" ]; then
    echo "Universal DPI package"
  else
    echo "Package supports DPIs: $(echo "$dpis" | tr '-' ' ')"
  fi

  getarchitectures "$apk"
  echo "Native code for architecture(s): $architectures"

  if ! verifyapk "$apk"; then
    if [ -n "$notinzip" ]; then
      echo "ERROR: The following files were mentioned in the signed manifest of $1 but are not present in the APK:
$notinzip"
    else
      echo "ERROR: $1 contains files or a certificate not signed by Google. APK not imported";
    fi
    echo "ERROR: Unsigned or incomplete APKs are not allowed. APK is not imported."
    return 1
  fi
  echo "APK is complete, certificate is valid and signed by Google"

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
  if [ "$argument" = "beta" ]; then
    BETA="beta"
    continue
  fi
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
      #*x86-64*)
      #  install -D "$file" "$SOURCES/x86_64/lib64/$(basename "$file")"
      #  echo "SUCCESS: Added $file to x86_64/lib64/";;
      #*aarch64*)
      #  if [ "$(basename "$file")" = "libfrsdk.so" ]; then
      #    install -D "$file" "$SOURCES/arm/vendor/lib64/$(basename "$file")"
      #    echo "SUCCESS: Added $file to arm64/vendor/lib64/"
      #  else
      #    install -D "$file" "$SOURCES/arm64/lib64/$(basename "$file")"
      #    echo "SUCCESS: Added $file to arm64/lib64/"
      #  fi;;
      #*32-bit*intel*)
      #  install -D "$file" "$SOURCES/x86/lib/$(basename "$file")"
      #  echo "SUCCESS: Added $file to x86/lib/";;
      #*32-bit*arm*)
      #  if [ "$(basename "$file")" = "libfrsdk.so" ]; then
      #    install -D "$file" "$SOURCES/arm/vendor/lib/$(basename "$file")"
      #    echo "SUCCESS: Added $file to arm/vendor/lib/"
      #  else
      #    install -D "$file" "$SOURCES/arm/lib/$(basename "$file")"
      #    echo "SUCCESS: Added $file to arm/lib/"
      #  fi;;
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
