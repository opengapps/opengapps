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

# Check tools
checktools aapt coreutils jarsigner

argument(){
  case $1 in
    hash)   hash="hash";;
    nohelp) nohelp="nohelp";;
    nosig)  nosig="nosig";;
    all)    filterapparchs="${filterapparchs} all";;
    arm)    filterapparchs="${filterapparchs} arm";;
    arm64)  filterapparchs="${filterapparchs} arm64";;
    x86)    filterapparchs="${filterapparchs} x86";;
    x86_64) filterapparchs="${filterapparchs} x86_64";;
    *-*)    buildarch="$(echo "$1" | cut -f 1 -d '-')"
            maxsdk="$(echo "$1" | cut -f 2 -d '-')";;
    *)      maxsdk="$1";;
  esac
}

hash=""
nohelp=""
nosig=""
filterapparchs=""
buildarch=""
maxsdk="99"

for arg in "$@"; do
  argument "$arg"
done

if [ -z "$hash" ] && [ -z "$nohelp" ]; then
  echo "=== Simple How To ===:
* No arguments: Show all packages of all architectures and SDK-levels
=== OR ===
* SDK-level as a argument:  Show packages that are eligable to be picked when building for specified SDK-level
* all|arm|arm64|x86|x86_64: Show only packages of given architecture
* These arguments can be combined in any order and multiple architectures can be supplied
* Example command: './report_sources.sh 22 all arm arm64'
=== OR ===
* (all|arm|arm64|x86|x86_64)-(SDK-level): Show packages that will be selected when building for specified architecture and SDK-level
* Example command: './report_sources.sh arm-22'
=== AND ===
* hash: If you add hash as an extra argument, the result will not be returned as human readable, but with a unique hash for the resultset
* nohelp: If you add nohelp as an extra argument, the result will not include this helptext (not necessary if hash is used)
* nosig: Skips signature checking (which takes a lot of CPU power); NB: this does change the hash result!
* Example command: './report_sources.sh arm-22 hash'
---------------------------------------------------------------------------------------------------------------"
fi

case "$buildarch" in
  arm64|x86)  fallbackarchs="arm";;
  x86_64) fallbackarchs="x86 arm";;
  *)      fallbackarchs="";;
esac

result="$(printf "%45s|%6s|%3s|%15s|%27s|%10s|%4s" "Application Name" "Arch." "SDK" "DPI" "Version Name" "Version" "Sig.")
---------------------------------------------------------------------------------------------------------------"
allapps="$(find "$SOURCES/" -iname "*.apk" | awk -F '/' '{print $(NF-3)}' | sort | uniq)"
for appname in $allapps;do
  appnamefiles="$(find "$SOURCES/" -iname "*.apk" -ipath "*/$appname/*")"
  if [ -n "$buildarch" ]; then
    apparchs="$buildarch $fallbackarchs all"
  elif [ -n "$filterapparchs" ];then
    apparchs="$filterapparchs"
  else
    apparchs="$(printf "%s" "$appnamefiles" | awk -F '/' '{print $(NF-5)}' | sort | uniq)"
  fi

  for arch in $apparchs;do
    appsdkfiles="$(find "$SOURCES/$arch/" -iname "*.apk" -ipath "*/$appname/*")"
    appsdks="$(printf "%s" "$appsdkfiles" | awk -F '/' '{print $(NF-2)}' | sort -r -g | uniq)"

    for sdk in $appsdks;do
      if [ "$sdk" -le "$maxsdk" ];then
        appdpifiles="$(find "$SOURCES/$arch/" -iname "*.apk" -ipath "*/$appname/$sdk/*")"
        appdpis="$(printf "%s" "$appdpifiles" | awk -F '/' '{print $(NF-1)}' | sort | uniq)"
        for dpi in $appdpis;do
          appversionfile="$(find "$SOURCES/$arch/" -iname "*.apk" -ipath "*/$appname/$sdk/$dpi/*" | head -n 1)"
          appversion="$(basename -s ".apk" "$appversionfile")"
          appversionname="$(aapt dump badging "$appversionfile" 2>/dev/null | awk '/versionName=/ {print $4}' | sed s/versionName=// | sed "s/'//g")"
          if [ -z "$nosig" ];then
            if verifyapk "$appversionfile";then
              signed="pass"
            else
              signed="fail"
            fi
          else
            signed="skip"
          fi
          result="$result
$(printf "%45s|%6s|%3s|%15s|%27s|%10s|%4s" "$appname" "$arch" "$sdk" "$dpi" "$appversionname" "$appversion" "$signed")"
        done
        if [ -n "$buildarch" ]; then
          break 2 #when selecting for the build of a specified architeture and sdk, only one architecture result is enough
        elif [ "$maxsdk" != "99" ];then
          break #if a specific sdk level is supplied, we only show 1 relevant version
        fi
      fi
    done
  done
done
if [ -z "$hash" ]; then
  echo "$result"
else
  printf "%s" "$result" | md5sum | cut -f1 -d' '
fi
