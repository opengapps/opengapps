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
APKTOOL="$SCRIPTS/apktool-resources/apktool_2.1.1.jar"
# shellcheck source=scripts/inc.compatibility.sh
. "$SCRIPTS/inc.compatibility.sh"
# shellcheck source=scripts/inc.sourceshelper.sh
. "$SCRIPTS/inc.sourceshelper.sh"
# shellcheck source=scripts/inc.tools.sh
. "$SCRIPTS/inc.tools.sh"
BETA=""

# Check tools
PATH="$SCRIPTS/androidsdk-resources-$(uname):$PATH"  # temporary hack to prefer our own older (x86_64) aapt that gives the application label correctly
checktools aapt file coreutils java jarsigner keytool openssl unzip

installapk() {
  architecture="$1"
  eval "lowestapi=\$LOWESTAPI_$architecture"
  if [ -n "$leanback" ] && [ "$lowestapi" -lt "$LOWESTAPI_leanback" ]; then
    lowestapi="$LOWESTAPI_leanback"
  fi
  existing=""

  if [ "$sdkversion" -lt "$lowestapi" ]; then
    for s in $(seq "$((sdkversion + 1))" "$lowestapi"); do
      for d in $(printf "%s" "$dpis" | sed 's/-/ /g'); do
        existing="$(find "$SOURCES/$architecture/$type/$package/$s/" -type d -name "*$d*" | sort -r | cut -c1-)" 2>/dev/null
        if [ -e "$existing" ];then
          echo "ERROR: API level is lower than minimum level $lowestapi and lower than existing level $s of the same package"
          return 1;
        fi
      done
    done
  fi

  #targetlocation: sources/platform/type/package/sdkversion/dpi1-dpi2-dpi3/versioncode.apk
  target="$SOURCES/$1/$type/$package/$sdkversion/$dpis"

  for d in $(printf "%s" "$dpis" | sed 's/-/ /g'); do
    existingpath="$(find "$SOURCES/$architecture/$type/$package/$sdkversion/" -type d -name "*$d*" | sort -r | cut -c1-)" 2>/dev/null
    if [ -n "$existingpath" ]; then
      existing="$(find "$existingpath/" -name "*.apk" | sort -r | cut -c1-)" 2>/dev/null #we only look for lowercase .apk, since basename later assumes the same
      if [ -e "$existing" ]; then
        echo "Existing version $existing"
        existingversion=$(basename -s.apk "$existing")
        if [ "$versioncode" -gt "$existingversion" ]; then
          rm "$existing"
          rmdir -p --ignore-fail-on-non-empty "$existingpath"
          install -D "$apk" "$target/$versioncode.apk"
          echo "Replaced with $target/$versioncode.apk"
        else
          echo "ERROR: APK is not newer than existing"
        fi
        break
      fi
    fi
  done
  if [ -z "$existing" ]; then
    install -D "$apk" "$target/$versioncode.apk"
    echo "SUCCESS: Added $target/$versioncode.apk"
  fi

  if [ "$sdkversion" -le "$lowestapi" ]; then
    for s in $(seq 1 "$((sdkversion - 1))"); do
      for d in $(printf "%s" "$dpis" | sed 's/-/ /g'); do
        remove="$(find "$SOURCES/$architecture/$type/$package/$s/" -type d -name "*$d*" | sort -r | cut -c1-)" 2>/dev/null
        if [ -e "$remove" ]; then
          rm -rf "$remove"
          rmdir --ignore-fail-on-non-empty "$(dirname "$remove")"
          echo "Cleaned up old API: $remove"
        fi
      done
    done
  fi
}

addapk() {
  apk="$1"
  getapkproperties "$apk"

  if [ "$package" = "com.google.android.setupwizard" ]; then
    if getsetupwizardproduct "$apk"; then
      if [ -n "$product" ]; then
        package="$package.$product"
      fi
    else
      echo "ERROR: Failed to retrieve SetupWizard product-type of $apk"
      return 1
    fi
  fi

  echo "Importing $name"
  echo "Package $package | VersionName $versionname | VersionCode $versioncode | API level $sdkversion"
  if [ "$dpis" = "nodpi" ]; then
    echo "Universal DPI package"
  else
    echo "Package supports DPIs: $(echo "$dpis" | tr '-' ' ')"
  fi

  # So an extra check is necessary before declaring it suitable for all platforms
  if [ "$(echo $native)" = ""  ]; then # we can't use -z here, because there can be a spaces in it
    getarchitecturesfromlib "$apk"
    if [ "$architectures" = "all" ]; then
      echo "No native code"
    else
      echo "Found native libraries for architecture(s): $architectures"
    fi
  else
    architectures=""
    altarchitectures=""
    for arch in $native; do
      architectures="$architectures$arch "
    done
    echo "Native code for architecture(s): $architectures"
    for altarch in $altnative; do
      altarchitectures="$altarchitectures$altarch "
    done
    if [ -n "$altarchitectures" ]; then
      echo "Alternative native code for architecture(s): $altarchitectures"
    fi
  fi

  verifyapk "$apk"
  verified="$?"
  if [ "$verified" != 0 ]; then
    case "$verified" in
      $INCOMPLETEFILES) echo "ERROR: The following files were mentioned in the signed manifest of $apk but are not present in the APK:
$notinzip";;
      $INVALIDCERT)     echo "ERROR: $apk contains files or a certificate not signed by Google. APK not imported";;
      $UNSIGNEDFILES)   echo "ERROR: Unsigned or incomplete APKs are not allowed. APK is not imported.";;
    esac
    return 1
  fi
  echo "APK is complete, certificate is valid and signed by Google"

  #We manually check for each of our set of supported architectures
  #We assume NO universal packages for 32vs64 bit, so start with the 'highest' architectures first, if it matches one of those, we will NOT add it to a lower architecture
  if { echo "$architectures" | grep -q "armeabi" && ! echo "$architectures" | grep -q "arm64"; } ||\
       echo "$native" | grep -q "armeabi"; then #no space, all armearbi* are valid
    installapk "arm"
  fi
  if echo "$architectures" | grep -q "arm64"; then
    installapk "arm64"
  fi
  if { echo "$architectures" | grep -q "x86 " && ! echo "$architectures" | grep -q "x86_64"; } ||\
       echo "$native" | grep -q "x86 "; then #x86 with space, make sure x86 is not a substring of x86_64
    installapk "x86"
  fi
  if echo "$architectures" | grep -q "x86_64"; then
    installapk "x86_64"
  fi
  if echo "$architectures" | grep -q "all"; then #no space (single entry)
    installapk "all"
  fi
}

addlib() {
  lib="$1"
  libname="$(basename "$lib")"
  architecture="$2"
  case "$libname" in
    libfrsdk.so)  prefix="vendor/";;
    *)            prefix="";;
  esac
  case $architecture in
    arm64|x86_64)  libfolder="lib64";;
    *)             libfolder="lib";;
  esac
  path="$SOURCES/$architecture/$prefix$libfolder/API/$libname"

  echo "For which API level should $path be installed? [#]"
  IFS= read -r REPLY
  case "$REPLY" in
    (*[!0-9]*|'') echo "ERROR: $REPLY is not a valid API level";;
    (*)           install -D "$lib" "$SOURCES/$architecture/$prefix$libfolder/$REPLY/$libname"
                  echo "SUCCESS: Added $libname to $architecture/$prefix$libfolder/$REPLY/";;
  esac
}

for argument in "$@"; do
  if [ "$argument" = "beta" ]; then
    BETA="beta"
    continue
  fi
  file="$(readlink -f "$argument")"
  if [ -f "$file" ]; then
    filetype="$(file -b -0 "$file" | tr '[:upper:]' '[:lower:]')"
    case "$filetype" in
      *jar*|*zip*)
        if aapt dump configurations "$file" >/dev/null; then
          addapk "$file"
        else
          echo "ERROR: File $file not a valid APK!"
        fi;;
      *x86-64*)       addlib "$file" "x86_64";;
      *aarch64*)      addlib "$file" "arm64";;
      *32-bit*intel*) addlib "$file" "x86";;
      *32-bit*arm*)   addlib "$file" "arm";;
      *)              echo "ERROR: File $file has an unrecognized filetype!";;
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
