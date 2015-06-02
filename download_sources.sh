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
command -v git >/dev/null 2>&1 || { echo "git is required but it's not installed.  Aborting." >&2; exit 1; }
git pull --recurse-submodules 
if [ $? -eq 1 ]; then
	echo "ERROR during git execution, aborted!"
	exit 1
fi
git submodule update --init --remote
if [ $? -eq 1 ]; then
	echo "ERROR during git execution, aborted!"
        exit 1
fi
