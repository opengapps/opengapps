#!/bin/sh
#This file is part of The PA GApps script of @mfonville.
#
#    The PA GApps scripts are free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    These scripts are distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
sources="sources"

if { [ "x$1" != "xarm" ] && [ "x$1" != "xarm64" ] && [ "x$1" != "xx86" ]; } || [ "x$2" = "x" ]; then
	echo "Usage: $0 (arm|arm64|x86) apks_to_add.apk [...]"
	exit 1
fi

command -v aapt v >/dev/null 2>&1 || { echo "aapt is required but it's not installed.  Aborting." >&2; exit 1; }
#aapt can be found in phablet-tools on Ubuntu
command -v install >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; }
#coreutils also contains the basename command

addapk() {
	name=`aapt dump badging $1 | grep "application-label:" |sed 's/application-label://g' |tr -d "/'"`
	package=`aapt dump badging $1 | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g | awk '{print tolower($0)}'`
	versionname=`aapt dump badging $1 | grep "versionName" |awk '{print $4}' |tr -d "versionName=" |tr -d "/'"`
	versioncode=`aapt dump badging $1 | grep "versionCode=" |awk '{print $3}' |tr -d "/versionCode='"`
	sdkversion=`aapt dump badging $1 | grep "sdkVersion:" |tr -d "/sdkVersion:'"`
	echo "Importing "$name
	echo "Package "$package" | VersionName "$versionname" | VersionCode "$versioncode" | API level "$sdkversion

	if [ "$package" = "com.google.android.backuptransport" ] \
	|| [ "$package" = "com.google.android.feedback" ] \
	|| [ "$package" = "com.google.android.gms" ] \
	|| [ "$package" = "com.google.android.gsf" ] \
	|| [ "$package" = "com.google.android.gsf.login" ] \
	|| [ "$package" = "com.google.android.onetimeinitializer" ] \
	|| [ "$package" = "com.google.android.partnersetup" ] \
	|| [ "$package" = "com.google.android.setupwizard" ] \
	; then
		type="priv-app"
	else
		type="app"
	fi

	#Keep track of specific version of the special DPI packages
	if [ "$package" = "com.google.android.gms" ] \
	|| [ "$package" = "com.google.android.play.games" ] \
	; then
		package="$package."`echo $versioncode | tail -c -2`
	fi
	

	#targetlocation: sources/platform/type/package/sdkversion/versioncode.apk
	target="$sources/$architecture/$type/$package/$sdkversion/"
	install -d $target
	if stat --printf='' $target* 2>/dev/null
	then
		existing=`find $target* | sort -r | head -1` 
		echo "Existing version "$existing
		existingversion=`basename -s.apk $existing`
		if [ "$versioncode" -gt "$existingversion" ]; then
			echo "Replaced with "$target$versioncode.apk
			rm $existing
			install -D $1 $target$versioncode.apk
		else
			echo "Aborting, APK is not newer than existing"
		fi
	else
		echo "Adding "$target$versioncode.apk
		install -D $1 $target$versioncode.apk
	fi
}

#Remove architecture argument, then run over all apks
architecture=$1
shift
for apk in $@
do
    addapk $apk
done
