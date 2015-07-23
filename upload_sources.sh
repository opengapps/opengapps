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
command -v basename >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; }

getapkproperties(){
    apk="$(git status -suall | cut -c4- | head -n1)"
    dpis="$(printf "$apk" | awk -F/ '{print $(NF-1)}')"
    apkproperties="$(aapt dump badging "$apk" 2>/dev/null)"
    name="$(echo "$apkproperties" | grep "application-label:" | sed 's/application-label://g' | sed "s/'//g")"
    versionname="$(echo "$apkproperties" | grep "versionName" | awk '{print $4}' | sed s/versionName=// | sed "s/'//g")"
}

upload(){
    git add "$apk"
    git commit -am"$name $versionname ($dpis)"
    git push origin HEAD:master
    cd "$TOP"
}

for arch in $(ls "$SOURCES"); do
    cd "$SOURCES/$arch"
    getapkproperties
    upload
done
