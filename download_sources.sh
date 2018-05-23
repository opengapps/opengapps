#!/bin/bash
# This file is part of The Open GApps script of @mfonville.
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

case $(uname -s) in
  Darwin|Macintosh) readlink() { perl -MCwd -e 'print Cwd::abs_path shift' "$2"; };;
esac;

SCRIPT="$(readlink -f "$0")"
TOP="$(dirname "$SCRIPT")"
SCRIPTS="$TOP/scripts"

# shellcheck source=scripts/inc.tools.sh
. "$SCRIPTS/inc.tools.sh"

# Check tools
checktools git lzip

argument() {
  case $1 in
    arm)
      modules="all $1"
    ;;
    arm64|x86)
      modules="all arm $1"
    ;;
    x86_64)
      modules="all arm x86 $1"
    ;;
    --shallow)
      depth="--depth=1 --checkout"  # checkout instead of rebasing, to avoid that it tries to rebase a huge number of commits in one go, resulting in failures (experimental!)
    ;;
    --i-would-really-like-my-diskspace-back)
      for module in $modules; do
        git submodule deinit -f sources/$module
        rm -rf .git/modules/sources/$module
      done
      echo "NOTICE: All local sources removed! Find more donations for a larger hard disk..."
      exit 0
    ;;
  esac
}

depth=""
modules="all arm arm64 x86 x86_64"

for arg in "$@"; do
  argument $arg
done

pushd "$TOP" > /dev/null
for module in $modules; do
  git submodule update --init --remote $depth -- "sources/$module" # --rebase is specifed in .gitmodules
  if [ $? -ne 0 ]; then
    echo "ERROR during git execution, aborted!"
    exit 1
  fi
  lzfiles="$(find "sources/$module/" -name "*.apk.lz")" 2>/dev/null
  for f in $lzfiles; do
    if ! [ -e "$(dirname "$f")/$(basename -s.lz "$f")" ]; then  # if this archive was not extracted yet
      rm -f "$(dirname "$f")/"*.apk  # clean-up any old left over outdated APKs
      lzip -d -k -f "$f"  # put our new APK in place
    fi
  done
done
git submodule foreach -q 'branch="$(git config -f "$toplevel/.gitmodules" "submodule.$name.branch")"; git checkout -q "$branch"; git pull -q $depth --rebase'
popd > /dev/null
