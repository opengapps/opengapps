#!/bin/sh
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
command -v git >/dev/null 2>&1 || { echo "git is required but it's not installed.  Aborting." >&2; exit 1; }

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
      depth="--depth 1"
    ;;
  esac
}

depth=""
modules="all arm arm64 x86 x86_64"

for arg in "$@"; do
  argument $arg
done

for module in $modules; do
  git submodule update --init --remote --rebase $depth -- sources/$module
  if [ $? -ne 0 ]; then
    echo "ERROR during git execution, aborted!"
    exit 1
  fi
done
