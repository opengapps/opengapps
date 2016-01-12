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
. "$SCRIPTS/inc.compatibility.sh"
. "$SCRIPTS/inc.sourceshelper.sh"
. "$SCRIPTS/inc.tools.sh"

# Check tools
checktools aapt coreutils git

createcommit(){
  getapkproperties "$1"

  if [ -n "$leanback" ]; then
    name="$name ($leanback)" #special leanback versions should be named like that in their commit
  fi

  if [ -n "$beta" ]; then
    name="$name ($beta)" #beta versions should be named like that in their commit
  fi

  git rm -q -r --ignore-unmatch "$(dirname "$1")"
  eval "lowestapi=\$LOWESTAPI_$2"
  if [ "$sdkversion" -le "$lowestapi" ]; then
    for i in $(seq 1 "$((sdkversion - 1))")
    do
      if [ -n "$(git ls-tree -r --name-only master "$type/$package/$i")" ]; then
        git rm -q -r --ignore-unmatch "$type/$package/$i/$dpis" # We are already in "$SOURCES/$arch"
      fi
    done
  fi
  # We don't have to care about empty direcories with git (see http://stackoverflow.com/a/10075480/3315861 for more details.)
  git add "$1"
  git status -s -uno
  echo "Do you want to commit these changes as $name $2-$sdkversion $versionname ($dpis)? [y/N]"
  IFS= read -r REPLY
  case "$REPLY" in
    y*|Y*)  git commit -q -m"$name $2-$sdkversion $versionname ($dpis)"
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
