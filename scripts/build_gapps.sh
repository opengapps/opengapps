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
if { [ "x$1" != "xarm" ] && [ "x$1" != "xarm64" ] && [ "x$1" != "xx86" ] && [ "x$1" != "xx86_64" ]; } || [ "x$2" = "x" ]; then
	echo "Usage: $0 (arm|arm64|x86|x86_64) API_LEVEL"
	exit 1
fi
DATE=$(date +"%Y%m%d")
TOP="$(realpath .)"
ARCH="$1"
API="$2"
VARIANT="$3"
BUILD="$TOP/build"
OUT="$TOP/out"
SOURCES="$TOP/sources"
SCRIPTS="$TOP/scripts"
. "$SCRIPTS/inc.buildhelper.sh"
. "$SCRIPTS/inc.buildtarget.sh"
. "$SCRIPTS/inc.aromadata.sh"
. "$SCRIPTS/inc.installdata.sh"
. "$SCRIPTS/inc.packagetarget.sh"
. "$SCRIPTS/inc.updatebinary.sh"

#####---------CHECK FOR EXISTANCE OF SOME BINARIES---------
command -v aapt >/dev/null 2>&1 || { echo "aapt is required but it's not installed.  Aborting." >&2; exit 1; }
command -v install >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; }
#coreutils also contains the basename command
command -v openssl >/dev/null 2>&1 || { echo "openssl is required but it's not installed.  Aborting." >&2; exit 1; }
#necessary to use signapk
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but it's not installed.  Aborting." >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "zip is required but it's not installed.  Aborting." >&2; exit 1; }
command -v zipalign >/dev/null 2>&1 || { echo "zipalign is required but it's not installed.  Aborting." >&2; exit 1; }

case "$API" in
	19)	PLATFORM="4.4";;
	21)	PLATFORM="5.0";;
	22)	PLATFORM="5.1";;
	*)	echo "ERROR: Unknown API version! Aborting..."
		exit 1;;
esac

get_supported_variants "$VARIANT"
SUPPORTEDVARIANTS="$supported_variants"

if [ -z "$SUPPORTEDVARIANTS" ]; then
	echo "ERROR: Unknown variant! aborting..."; exit 1
fi
if [ "$FALLBACKARCH" != "arm" ];then #For all non-arm(64) platforms
	case "$VARIANT" in
		aroma|fornexus) echo "ERROR! Variant $VARIANT cannot be built on a non-arm platform";
		exit 1;;
	esac
fi

kitkathacks

buildtarget
alignbuild
commonscripts
variantscripts
if [ "$VARIANT" = "aroma" ]; then
	aromascripts
fi
createzip
