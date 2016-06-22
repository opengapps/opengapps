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

# set your own OPENGAPPSGIT_EMAIL and/or OPENGAPPSGIT_NAME environment variables if they differ from your regular git credentials
# set your own APKMIRROR_EMAIL and/or APKMIRROR_NAME environment variables if they differ from your git credentials

command -v realpath >/dev/null 2>&1 || { echo "realpath is required but it's not installed, aborting." >&2; exit 1; }
SCRIPT="$(readlink -f "$0")"
TOP="$(dirname "$SCRIPT")"
SOURCES="$TOP/sources"
SCRIPTS="$TOP/scripts"
# shellcheck source=scripts/inc.compatibility.sh
. "$SCRIPTS/inc.compatibility.sh"
# shellcheck source=scripts/inc.sourceshelper.sh
. "$SCRIPTS/inc.sourceshelper.sh"
# shellcheck source=scripts/inc.tools.sh
. "$SCRIPTS/inc.tools.sh"

# Check tools
PATH="$SCRIPTS/androidsdk-resources-$(uname):$PATH"  # temporary hack to prefer our own older (x86_64) aapt that gives the application label correctly
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
      paths="$(git ls-tree -r --name-only master "$type/$package/$s")"
      if [ -n "$paths" ]; then
        for d in $(printf "%s" "$dpis" | sed 's/-/ /g'); do
          existing="$(echo "$paths" | grep -o "$type/$package/$s/*$d*")"
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
  echo "Commit changes as '$name $2-$sdkversion $versionname ($dpis)' by $username <$email>? [y/N]"
  IFS= read -r REPLY
  case "$REPLY" in
    y*|Y*)  git commit -q -m "$name $2-$sdkversion $versionname ($dpis)" --author="$username <$email>"
            echo "Committed $1";;
        *)  git reset -q HEAD
            echo "Did NOT commit $1";;
  esac
}

newapks=""
modules=""

for arg in "$@"; do
  modules="$modules $arg"
done

if [ -z "$modules" ]; then
  modules="all arm arm64 x86 x86_64"
fi

for arch in $modules; do
  cd "$SOURCES/$arch" || continue

  # We set this per architecture repo, because the settings might differ per submodule
  if [ -n "$OPENGAPPSGIT_EMAIL" ]; then
    email="$OPENGAPPSGIT_EMAIL"
  else
    email="$(git config user.email)"
  fi
  if [ -n "$OPENGAPPSGIT_NAME" ]; then
    username="$OPENGAPPSGIT_NAME"
  else
    username="$(git config user.name)"
  fi

  echo "Resetting $arch to HEAD before staging new commits..."
  git reset -q HEAD #make sure we are not including any other files are already tracked, output is silenced, not to confuse the user with the next output
  apks="$(git status -uall --porcelain | grep '.apk$' | grep -e "?? " | cut -c4-)" #get the new apks
  for apk in $apks; do
    createcommit "$apk" "$arch"
  done
  changes="$(git shortlog origin/master..HEAD)"
  addnewapks="$(git diff --name-only --diff-filter=AM origin/master..HEAD | grep '.apk$' | cut -f 2 | sed "s#^#$SOURCES/$arch/#")"
  if [ -n "$addnewapks" ]; then
    newapks="$newapks
$addnewapks"
  fi

  if [ -n "$changes" ]; then
    echo "$changes"
    echo "Push these commits to the '$arch' repository? [y/N]"
    IFS= read -r REPLY
    case "$REPLY" in
        y*|Y*)  git push origin HEAD:master;;
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
      *)    echo "Did NOT submit to APKmirror.com";;
  esac
fi
cd "$TOP"
