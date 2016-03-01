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

# set your own APKMIRROR_EMAIL and/or APKMIRROR_NAME environment variables if they differ from your git credentials

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
    for s in $(seq 1 "$((sdkversion))"); do
      paths="$(git ls-tree -r --name-only master "$type/$name/$s")"
      if [ -n "$paths" ]; then
        for d in $(printf "$dpis" | sed 's/-/ /g'); do
          existing="$(echo "$paths" | grep -o "$type/$name/$s/*$d*")"
          if [ -n "$existing" ]; then
            git rm -q -r --ignore-unmatch "$existing" # We are already in "$SOURCES/$arch"
          fi
        done
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

newapks=""
for arch in $(ls "$SOURCES"); do
  cd "$SOURCES/$arch"
  echo "Resetting $arch to HEAD before staging new commits..."
  git reset -q HEAD #make sure we are not including any other files are already tracked, output is silenced, not to confuse the user with the next output
  apks="$(git status -uall --porcelain | grep ".apk" | grep -e "?? " | cut -c4-)" #get the new apks
  for apk in $apks; do
    createcommit "$apk" "$arch"
  done
  changes="$(git shortlog origin/master..HEAD)"
  addnewapks="$(git diff --name-only --diff-filter=A origin/master..HEAD | cut -f 2 | sed "s#^#$SOURCES/$arch/#")"
  if [ -n "$addnewapks" ]; then
    newapks="$newapks
$addnewapks"
  fi

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
if [ -n "$newapks" ]; then
  if [ -n "$APKMIRROR_EMAIL" ]; then
    email="$APKMIRROR_EMAIL"
  else
    email="$(git config user.email)"
  fi
  if [ -n "$APKMIRROR_NAME" ]; then
    name="$APKMIRROR_NAME"
  else
    name="$(git config user.name)"
  fi
  echo "$newapks"
  echo "Do you want to submit these APKs to APKmirror.com using $name (OpenGApps.org) <$email>? [y/N]"
  IFS= read -r REPLY
  case "$REPLY" in
      y*|Y*)
            for apk in $newapks; do
              echo "Uploading $apk to APKmirror.com..."
              filename="$(basename "$apk")"
              curl -s -S -X POST -F "fullname=$name (OpenGApps.org)" -F "email=$email" -F "changes=" -F "file=@$apk;filename=$filename" "http://www.apkmirror.com/wp-content/plugins/UploadManager/inc/upload.php" > /dev/null
            done
            ;;
          *)  echo "Did NOT submit to APKmirror.com";;
  esac
fi
cd "$TOP"
