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
SPEECHFOLDER="$SOURCES/all/usr/srec/en-US"
. "$SCRIPTS/inc.buildhelper.sh"
. "$SCRIPTS/inc.tools.sh"

# Check tools
checktools gunzip wget

getapksforapi "com.google.android.googlequicksearchbox" "arm" "22"

for firstapk in $(echo "$sourceapks" | tr ' ' ''); do #we replace the spaces with a special char to survive the for-loop
  firstapk="$(echo "$firstapk" | tr '' ' ')" #and we place the spaces back again
  manifesturl="$(unzip -p "$firstapk" "res/raw/configuration" | grep -oa 'http://cache.pack.google.com/edgedl/android/voice/en-us/manifest_v[0-9]*.txt')"
  fileurls="$(wget -q -O - "$manifesturl")"
  for fileurl in $fileurls; do
    filename="$(printf "$fileurl" | cut -d '-' -f 1)"
    case "$fileurl" in
      *.gz) wget -q -O "$SPEECHFOLDER/$filename.gz" "http://cache.pack.google.com/edgedl/android/voice/en-us/$fileurl"
            gunzip -f "$SPEECHFOLDER/$filename.gz";;
      *)    wget -q -O "$SPEECHFOLDER/$filename" "http://cache.pack.google.com/edgedl/android/voice/en-us/$fileurl";;
    esac
  done
  break
done
