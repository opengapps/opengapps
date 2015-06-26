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

command -v aapt >/dev/null 2>&1 || { echo "aapt is required but it's not installed.  Aborting." >&2; exit 1; }
command -v install >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; }
#coreutils also contains the basename command

result="$(printf "%45s|%7s|%3s|%18s|%11s" "Application Name" "Arch." "SDK" "Version Name" "Version")
----------------------------------------------------------------------------------------"
allapks="$(find "$SOURCES/" -iname "*.apk" | awk -F '/' '{print $(NF-2)}' | sort | uniq)"
for appname in $allapks;do
	appnamefiles="$(find "$SOURCES/" -iname "*.apk" -ipath "*/$appname/*")"
	apparchs="$(printf "$appnamefiles" | awk -F '/' '{print $(NF-4)}' | sort | uniq)"

	for arch in $apparchs;do
		appsdkfiles="$(find "$SOURCES/$arch/" -iname "*.apk" -ipath "*/$appname/*")"
		appsdks="$(printf "$appsdkfiles" | awk -F '/' '{print $(NF-1)}' | sort | uniq)"

		for sdk in $appsdks;do
			appversionfile="$(find "$SOURCES/$arch/" -iname "*.apk" -ipath "*/$appname/$sdk/*" | tail -n 1)"
			appversion="$(basename -s ".apk" "$appversionfile")"
			appversionname="$(aapt dump badging "$appversionfile" | grep "versionName" |awk '{print $4}' |tr -d "versionName=" |tr -d "/'")"
			result="$result
$(printf "%45s| %6s| %2s| %17s| %10s" "$appname" "$arch" "$sdk" "$appversionname" "$appversion")"
		done
	done
done
echo "$result"
