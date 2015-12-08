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

#Check architecture
if { [ "$1" != "arm" ] && [ "$1" != "arm64" ] && [ "$1" != "x86" ] && [ "$1" != "x86_64" ]; } || [ -z "$2" ]; then
  echo "Usage: $0 (arm|arm64|x86|x86_64) API_LEVEL [VARIANT]"
  exit 1
fi

command -v realpath >/dev/null 2>&1 || { echo "realpath is required but it's not installed, aborting." >&2; exit 1; }
DATE=$(date +"%Y%m%d")
TOP="$(realpath .)"
ARCH="$1"
API="$2"
VARIANT="$3"
BUILD="$TOP/build"
CACHE="$TOP/cache"
OUT="$TOP/out"
SOURCES="$TOP/sources"
SCRIPTS="$TOP/scripts"
CERTIFICATES="$SCRIPTS/certificates"
. "$SCRIPTS/inc.aromadata.sh"
. "$SCRIPTS/inc.buildhelper.sh"
. "$SCRIPTS/inc.buildtarget.sh"
. "$SCRIPTS/inc.compatibility.sh"
. "$SCRIPTS/inc.installdata.sh"
. "$SCRIPTS/inc.packagetarget.sh"
. "$SCRIPTS/inc.updatebinary.sh"
. "$SCRIPTS/inc.tools.sh"

# Check tools
checktools aapt coreutils java jarsigner unzip zip tar xz realpath zipalign

case "$API" in
  19) PLATFORM="4.4";;
  21) PLATFORM="5.0";;
  22) PLATFORM="5.1";;
  23) PLATFORM="6.0";;
  *)  echo "ERROR: Unknown API version! Aborting..."
  exit 1;;
esac

get_supported_variants "$VARIANT"
SUPPORTEDVARIANTS="$supported_variants"

if [ -z "$SUPPORTEDVARIANTS" ]; then
  echo "ERROR: Unknown variant! aborting..."; exit 1
fi
if [ "$ARCH" != "arm" ] && [ "$ARCH" != "arm64" ]; then #For all non-arm(64) platforms
  case "$VARIANT" in
    aroma)              echo "ERROR! Variant $VARIANT cannot be built on a non-arm platform"; exit 1;;
    super|stock|full)   if [ "$API" -lt "21" ]; then
                          echo "ERROR! Variant $VARIANT cannot be built on a non-arm < 5.0 platform";
                          exit 1;
                        fi;; #because system wide libs will probably not work with libhoudini
  esac
fi
if [ "$API" -lt "22" ]; then
  case "$VARIANT" in
    super)  echo "ERROR! Variant $VARIANT cannot be built on API level $API"; exit 1;;
  esac
fi;

kitkatpathshack	#kitkat has different apk and lib paths which impact installer.data
kitkatdatahack #kitkat installs some applications on /data/ instead of /system/
keyboardlibhack #only 5.0+ has gestures for the aosp keyboard possible, which impact installer.data and an extra file in the package
api21hack #only 5.0+ supports google tag
api22hack #only 5.1+ supports google webview (Stock Google 5.0 ROMs too, but we merged stock and fornexus) and GCS
api23hack #only on 6.0+ we also include Google Contacts, Dialer, Calculator, Packageinstaller and Configupdater
buildtarget
alignbuild
commonscripts
if [ "$VARIANT" = "aroma" ]; then
  aromascripts
fi
createzip
