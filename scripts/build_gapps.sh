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
  echo "Usage: $0 (arm|arm64|x86|x86_64) API_LEVEL"
  exit 1
fi
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
. "$SCRIPTS/inc.aromadata.sh"
. "$SCRIPTS/inc.buildhelper.sh"
. "$SCRIPTS/inc.buildtarget.sh"
. "$SCRIPTS/inc.compatibility.sh"
. "$SCRIPTS/inc.installdata.sh"
. "$SCRIPTS/inc.packagetarget.sh"
. "$SCRIPTS/inc.updatebinary.sh"

#####---------CHECK FOR EXISTANCE OF SOME BINARIES---------
command -v aapt >/dev/null 2>&1 || { echo "aapt is required but it's not installed.  Aborting." >&2; exit 1; }
command -v install >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; } #coreutils also contains the basename command
command -v java >/dev/null 2>&1 || { echo "java is required but it's not installed.  Aborting." >&2; exit 1; } #necessary to use signapk
command -v md5sum >/dev/null 2>&1 || { echo "md5sum is required but it's not installed.  Aborting." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but it's not installed.  Aborting." >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "zip is required but it's not installed.  Aborting." >&2; exit 1; }
command -v zipalign >/dev/null 2>&1 || { echo "zipalign is required but it's not installed.  Aborting." >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "tar is required but it's not installed.  Aborting." >&2; exit 1; }
command -v xz >/dev/null 2>&1 || { echo "xz is required but it's not installed.  Aborting." >&2; exit 1; }

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
if [ "$FALLBACKARCH" != "arm" ]; then #For all non-arm(64) platforms
  case "$VARIANT" in
    aroma|fornexus) echo "ERROR! Variant $VARIANT cannot be built on a non-arm platform";
    exit 1;;
  esac
fi

kitkatpathshack	#kitkat has different apk and lib paths which impact installer.data
kitkatdatahack #kitkat installs some applications on /data/ instead of /system/
taghack #only 5.0+ supports google tag
webviewhack #only 5.1+ supports google webview (but fornexus 5.0 does too)
keyboardlibhack #only 5.0+ has gestures for the aosp keyboard possible, which impact installer.data and an extra file in the package
buildtarget
alignbuild
commonscripts
if [ "$VARIANT" = "aroma" ]; then
  aromascripts
fi
createzip
