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
command -v git >/dev/null 2>&1 || { echo "git is required but it's not installed.  Aborting." >&2; exit 1; }

createcommit(){
    dpis="$(printf "%s" "$1" | awk -F/ '{print $(NF-1)}')"
    apkproperties="$(aapt dump badging "$1" 2>/dev/null)"
    name="$(echo "$apkproperties" | grep "application-label:" | sed 's/application-label://g' | sed "s/'//g")"
    versionname="$(echo "$apkproperties" | grep "versionName" | awk '{print $4}' | sed s/versionName=// | sed "s/'//g")"
    sdkversion="$(echo "$apkproperties" | grep "sdkVersion:" | sed 's/sdkVersion://' | sed "s/'//g")"

    git rm -q -r --ignore-unmatch "$(dirname "$1")"
    git add "$1"
    git status -s -uno
    echo "Do you want to commit these changes as $name $2 $sdkversion $versionname ($dpis)? [y/N]"
    IFS= read -r REPLY
    case "$REPLY" in
        y*|Y*)  git commit -q -m"$name $2 $sdkversion $versionname ($dpis)"
                echo "Committed $1";;
            *)  git reset -q HEAD
                echo "Did NOT commit $1";;
    esac
}

for arch in $(ls "$SOURCES"); do
    cd "$SOURCES/$arch"
    echo "Resetting $arch to HEAD before staging new commits..."
    git reset -q HEAD #make sure we are not including any other files are already tracked, output is silenced, not to confuse the user with the next output
    apks="$(git status -uall --porcelain | grep ".apk" | grep -e "?? " | cut -c4-)" #get the new apks
    for apk in $apks; do
        createcommit "$apk" "$arch"
    done
    changes="$(git shortlog origin/master..HEAD)"
    if [ -n "$changes" ]; then
        echo "$changes"
        echo "Do you want to push these commits to the $arch repository? [y/N]"
        IFS= read -r REPLY
        case "$REPLY" in
            y*|Y*)  git push origin HEAD:master ;;
                *)  echo "Did NOT push $arch";;
        esac
    fi
done
cd "$TOP"
