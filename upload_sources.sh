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
CACHE="$TOP/cache"
SOURCES="$TOP/sources"
SCRIPTS="$TOP/scripts"
# shellcheck source=scripts/inc.tools.sh
. "$SCRIPTS/inc.tools.sh"
# shellcheck source=scripts/inc.compatibility.sh
. "$SCRIPTS/inc.compatibility.sh"
# shellcheck source=scripts/inc.sourceshelper.sh
. "$SCRIPTS/inc.sourceshelper.sh"

# Check tools
checktools aapt coreutils git lzip

createcommit(){
  getapkproperties "$1"

  if [ -n "$leanback" ]; then
    case "$package" in
      *inputmethod*) ;;  # if package is an inputmethod, it will have leanback as feature described, but we don't want it recognized as such
      *) name="$name ($leanback)"  # special leanback versions should be named like that in their commit
    esac
  fi

  if [ -n "$vrmode" ]; then
    case "$package" in
      com.google.android.apps.photos* |\
      com.google.android.videos*)
          name="$name ($vrmode)" ;;  # if package is whitelisted, we can add vrmode to the commit
      *)                         ;;  # Otherwise ignore the vrmode flag
    esac
  fi

  if [ -n "$watch" ]; then
    case "$package" in
      com.android.vending* |\
      com.google.android.apps.enterprise.dmagent* |\
      com.google.android.apps.fitness* |\
      com.google.android.apps.maps* |\
      com.google.android.apps.messaging* |\
      com.google.android.apps.walletnfcrel* |\
      com.google.android.calculator* |\
      com.google.android.deskclock* |\
      com.google.android.gms* |\
      com.google.android.googlequicksearchbox* |\
      com.google.android.inputmethod.latin* |\
      com.google.android.keep* |\
      com.google.android.marvin.talkback* |\
      com.google.android.music* |\
      com.google.android.talk*)
            name="$name ($watch)" ;;  # special watch versions need a different packagename
      *)                          ;;  # Otherwise ignore the watch flag
    esac
  fi

  if [ -n "$stub" ]; then
    name="$name ($stub)"  # stub versions should be named like that in their commit
  fi

  if [ -n "$beta" ]; then
    name="$name ($beta)"  # beta versions should be named like that in their commit
  fi

  git rm -q -r --ignore-unmatch "$(dirname "$1")"
  eval "lowestapi=\$LOWESTAPI_$2"
  if [ "$sdkversion" -le "$lowestapi" ]; then
    for s in $(seq 1 "$lowestapi"); do
      paths="$(git ls-tree -r --name-only master "$type/$package/$s")"
      if [ -n "$paths" ]; then
        for d in $(printf "%s" "$dpis" | sed 's/-/ /g'); do
          existing="$(echo "$paths" | grep -o "$type/$package/$s/*$d*/*" | cut -f -4 -d '/')"
          if [ -n "$existing" ]; then
            git rm -q -r --ignore-unmatch -- "$existing*" # We are already in "$SOURCES/$arch"
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

setprecommithook(){
  tee "$(git rev-parse --git-dir)/hooks/pre-commit" > /dev/null <<'EOFILE'
#!/bin/sh
#
for f in $(git diff --cached --name-only --diff-filter=ACMR | grep '.apk$'); do
  size="$(wc -c "$f" | awk '{print $1}')"  # slow, but available with same syntax on both linux and mac
  if [ "$size" -gt "95000000" ]; then # Limit set at 95MB
    echo "Compressing $f with lzip for GitHub"
    lzip -9 -k -f "$f"
    echo "$(basename "$f")" >> "$(dirname "$f")/.gitignore"
    git rm -q --cached "$f"
    git add "$f.lz"
    git add "$(dirname "$f")/.gitignore"
  fi
done
EOFILE
chmod +x "$(git rev-parse --git-dir)/hooks/pre-commit"
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

  setprecommithook  # Make sure we are using lzip pre-commit hook

  echo "Resetting $arch to HEAD before staging new commits..."
  git reset -q HEAD #make sure we are not including any other files are already tracked, output is silenced, not to confuse the user with the next output
  apks="$(git status -uall --porcelain | grep '.apk$' | grep -e "?? " | cut -c4-)" #get the new apks
  for apk in $apks; do
    createcommit "$apk" "$arch"
  done
  changes="$(git shortlog origin/master..HEAD)"
  addnewapks="$(git diff --name-only --diff-filter=ACMR origin/master..HEAD | grep '.apk$' | cut -f 2 | sed "s#^#$SOURCES/$arch/#")"
  addnewlzapks="$(git diff --name-only --diff-filter=ACMR origin/master..HEAD | grep '.apk.lz$' | cut -f 2 | sed "s#^#$SOURCES/$arch/#" | sed 's#.lz$##')"  # cut off the .lz, we want to upload the actual APK to APKMirror
  if [ -n "$addnewapks" ]; then
    newapks="$newapks
$addnewapks"
  fi
  if [ -n "$addnewlzapks" ]; then
    newapks="$newapks
$addnewlzapks"
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
              if $(curl -s -S -A "OpenGAppsUploader" "https://www.apkmirror.com/wp-json/apkm/v1/apk_uploadable/$(md5sum "$apk" | cut -f 1 -d ' ')" | grep -q "uploadable"); then
                echo "Uploading $apk to APKmirror.com..."
                filename="$(basename "$apk")"
                curl -s -S -A "OpenGAppsUploader" -X POST -F "fullname=$name (OpenGApps.org)" -F "email=$email" -F "changes=" -F "file=@$apk;filename=$filename" "https://www.apkmirror.com/wp-content/plugins/UploadManager/inc/upload.php" > /dev/null
              else
                echo "Skipping $apk, already exists on APKmirror.com..."
              fi
            done
            ;;
      *)    echo "Did NOT submit to APKmirror.com";;
  esac
fi
cd "$TOP"
