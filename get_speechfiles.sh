#!/bin/bash
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
# shellcheck source=scripts/inc.buildhelper.sh
. "$SCRIPTS/inc.buildhelper.sh"
# shellcheck source=scripts/inc.tools.sh
. "$SCRIPTS/inc.tools.sh"

# Check tools
checktools coreutils gunzip wget

manifesturl="https://www.gstatic.com/android/voicesearch/production_2016_04_08_14_33_37_6f706ca387f0e3cce36bb34e19fa76338283fb206c10da9a9f90426e"
fileurls="$(wget -q -O - "$manifesturl" | grep -a en-US | grep -a -o -E "http.*en-US[^.]*.zip")"
versions="$(echo "$fileurls" | grep -o -E "/v[0-9]+/")"
useversion="0"
for version in $versions; do
  if [ "${version:2:-1}" -gt "$useversion" ]; then
    useversion="${version:2:-1}"
  fi
done
if [ "$useversion" -gt "0" ]; then
  tmpfile="$(mktemp)"
  wget -q -O "$tmpfile" "$(echo "$fileurls" | grep "$useversion" | head -n 1)"
  install -d "$SPEECHFOLDER"
  unzip "$tmpfile" -d "$SPEECHFOLDER"
  rm "$tmpfile"
else
  echo "No valid en-US version found in online manifest"
fi
