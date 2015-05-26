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
command -v aapt >/dev/null 2>&1 || { echo "aapt is required but it's not installed.  Aborting." >&2; exit 1; }
#aapt can be found in phablet-tools on Ubuntu
command -v install >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; }
#coreutils also contains the basename command
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but it's not installed.  Aborting." >&2; exit 1; }

getarchitectures() {
	architectures=""
	native=`aapt dump badging "$1" | grep "native-code:" |sed 's/native-code://g' | tr -d "'"`
	if [ "$native" = "" ]
	then
		echo "No native-code specification defined"
		#Some packages don't have native-code specified, but are still depending on it.
		#So an extra check is necessary before declaring it suitable for all platforms
		libfiles=`unzip -qql "$1" lib* | tr -s ' ' | cut -d ' ' -f5-`
		for lib in $libfiles
		do
			#this gives all files found in the lib-folder(s), check their paths for which architectures' libs are included
			IFS='/'
			arch="`echo $lib | awk '{print $2}'`"
			echo "$architectures" | grep -q "$arch"
			if [ $? -eq 1 ] #only add if this architecture is not yet in the list
			then
				architectures="$architectures$arch "
				echo "Manually found native code for: $arch"
			fi
		done
		if [ "$architectures" = "" ] #If the package really has no native code
		then
			architectures="all"
		fi
	else
	for arch in $native
		do
			architectures="$architectures$arch "
		done
	fi
	echo "Supported architecture(s): $architectures"
}

installapk() {
	architecture="$1"
	#targetlocation: sources/platform/type/package/sdkversion/versioncode.apk
	target="$sources/$architecture/$type/$package/$sdkversion/"
	install -d "$target"
	if stat --printf='' "$target"* 2>/dev/null
	then
		existing=`find "$target"* | sort -r | cut -c1-` 
		echo "Existing version $existing"
		existingversion=`basename -s.apk "$existing"`
		if [ "$versioncode" -gt "$existingversion" ]; then
			echo "Replaced with $target$versioncode.apk"
			rm "$existing"
			install -D "$apk" "$target$versioncode.apk"
		else
			echo "ERROR: APK is not newer than existing"
		fi
	else
		install -D "$apk" "$target$versioncode.apk"
		echo "SUCCESS: Added $target$versioncode.apk"
	fi
}

addapk() {
	apk="$1"
	name=`aapt dump badging "$apk" | grep "application-label:" |sed 's/application-label://g' |tr -d "/'"`
	package=`aapt dump badging "$apk" | grep package: | awk '{print $2}' | sed s/name=//g | sed s/\'//g | awk '{print tolower($0)}'`
	versionname=`aapt dump badging "$apk" | grep "versionName" |awk '{print $4}' |tr -d "versionName=" |tr -d "/'"`
	versioncode=`aapt dump badging "$apk" | grep "versionCode=" |awk '{print $3}' |tr -d "/versionCode='"`
	sdkversion=`aapt dump badging "$apk" | grep "sdkVersion:" |tr -d "/sdkVersion:'"`
	echo "Importing "$name
	echo "Package "$package" | VersionName "$versionname" | VersionCode "$versioncode" | API level "$sdkversion

	if [ "$package" = "com.google.android.backuptransport" ] \
	|| [ "$package" = "com.google.android.feedback" ] \
	|| [ "$package" = "com.google.android.gms" ] \
	|| [ "$package" = "com.google.android.gsf" ] \
	|| [ "$package" = "com.google.android.gsf.login" ] \
	|| [ "$package" = "com.google.android.launcher" ] \
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
		package="$package.`echo $versioncode| rev | cut -c 1 | rev`"
	fi
	
	getarchitectures "$file"
	#We manually check for each of our set of supported architectures
	echo "$architectures" | grep -q "armeabi" #no space, all armearbi types are valid
	if [ $? -eq 0 ]
	then
		installapk "arm"
	fi
	echo "$architectures" | grep -q "arm64-v8a "
	if [ $? -eq 0 ]
	then
		installapk "arm64"
	fi
	echo "$architectures" | grep -q "x86 "
	if [ $? -eq 0 ]
	then
		installapk "x86"
	fi
	echo "$architectures" | grep -q "all" #no space (single entry)
	if [ $? -eq 0 ]
	then
		installapk "all"
	fi
}

for file in "$@"
do
	if [ -f "$file" ]
	then
		aapt dump configurations "$file" >/dev/null
		if [ $? -eq 0 ]
		then
			addapk "$file"
		else
			echo "ERROR: File $file not a valid APK!"
		fi
	else
		echo "ERROR: File $file does not exist!"
	fi
done


#Full list of 'our' architecture classification compared to the Android NDK architectures:
#arm:
#	armeabi - ARMv5TE based CPU with software floating point operations;
#	armeabi-v7a - ARMv7 based devices with hardware FPU instructions
#arm64:
#	arm64-v8a - ARMv8 AArch64 instruction set - only for NDK r10 and newer
#x86:
#	x86 - IA-32 instruction set
#
#unsupported at the moment:
#x86-64 - Intel64 instruction set (r1) - only for NDK r10 and newer
#mips - MIPS32 instruction set
#mips64 - MIPS64 instruction set (r6) - only for NDK r10 and newer
