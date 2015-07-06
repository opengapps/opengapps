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
LOWESTAPI="19"
command -v aapt >/dev/null 2>&1 || { echo "aapt is required but it's not installed.  Aborting." >&2; exit 1; }
command -v install >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; }
#coreutils also contains the basename command
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but it's not installed.  Aborting." >&2; exit 1; }

getarchitectures() {
	architectures=""
	if [ -z "$native" ]
	then
		echo "No native-code specification defined"
		#Some packages don't have native-code specified, but are still depending on it.
		#So an extra check is necessary before declaring it suitable for all platforms
		libfiles=$(unzip -qql "$1" lib/* | tr -s ' ' | cut -d ' ' -f5-)
		for lib in $libfiles
		do
			#this gives all files found in the lib-folder(s), check their paths for which architectures' libs are included
			arch="$(echo "$lib" | awk 'BEGIN { FS = "/" } ; {print $2}')"
			echo "$architectures" | grep -q "$arch"
			if [ $? -eq 1 ] #only add if this architecture is not yet in the list
			then
				architectures="$architectures$arch "
				echo "Manually found native code for: $arch"
			fi
		done
		if [ -z "$architectures" ] #If the package really has no native code
		then
			architectures="all"
		fi
	else
		for arch in $native
		do
				architectures="$architectures$arch "
		done
	fi
	echo "Native code for architecture(s): $architectures"
}

getapkproperties(){
	apkproperties="$(aapt dump badging "$1" 2>/dev/null)"
	name="$(echo "$apkproperties" | grep "application-label:" | sed 's/application-label://g' | sed "s/'//g")"
	package="$(echo "$apkproperties" | grep package: | awk '{print $2}' | sed s/name=//g | sed s/\'//g | awk '{print tolower($0)}')"
	versionname="$(echo "$apkproperties" | grep "versionName" | awk '{print $4}' | sed s/versionName=// | sed "s/'//g")"
	versioncode="$(echo "$apkproperties" | grep "versionCode=" | awk '{print $3}' | sed s/versionCode=// | sed "s/'//g")"
	sdkversion="$(echo "$apkproperties" | grep "sdkVersion:" | sed 's/sdkVersion://' | sed "s/'//g")"
	compatiblescreens="$(echo "$apkproperties" | grep "compatible-screens:")"
	native="$(echo "$apkproperties" | grep "native-code:" | sed 's/native-code://g' | sed "s/'//g")"
}

installapk() {
	architecture="$1"

	#targetlocation: sources/platform/type/package/sdkversion/dpi1-dpi2-dpi3/versioncode.apk
	target="$SOURCES/$1/$type/$package/$sdkversion/$dpis"
	install -d "$target"
	if stat --printf='' "$target/"* 2>/dev/null
	then
		existing=$(find "$target/" -name "*.apk" | sort -r | cut -c1-) #we only look for lowercase .apk, since basename later assumes the same
		echo "Existing version $existing"
		existingversion=$(basename -s.apk "$existing")
		if [ "$versioncode" -gt "$existingversion" ]; then
			echo "Replaced with $target/$versioncode.apk"
			rm "$existing"
			install -D "$apk" "$target/$versioncode.apk"
		else
			echo "ERROR: APK is not newer than existing"
		fi
	else
		install -D "$apk" "$target/$versioncode.apk"
		echo "SUCCESS: Added $target/$versioncode.apk"
	fi

	if [ "$sdkversion" -le "$LOWESTAPI" ];then
		for i in $(seq 1 "$((sdkversion - 1))")
		do
			remove="$SOURCES/$architecture/$type/$package/$i/"
			if [ -e "$remove" ];then
				rm -rf "$remove"
				echo "Cleaned up old API: $remove"
			fi
		done
	fi
}

addapk() {
	apk="$1"
	getapkproperties "$apk"

	echo "Importing $name"
	echo "Package $package | VersionName $versionname | VersionCode $versioncode | API level $sdkversion"

	if [ "$compatiblescreens" = "" ] # we can't use -z here, because there can be a linecontrol character or such in it
	then
		dpis="nodpi"
		echo "Universal DPI package"
	else
		dpis=$(echo "$compatiblescreens" | grep "compatible-screens:" | grep -oE "/([0-9][0-9])[0-9]" | uniq | tr -d '\012\015' | tr '/' '-' | cut -c 2-)
		echo "Package supports DPIs: $(echo "$dpis" | tr '-' ' ')"
	fi

	if [ "$package" = "com.google.android.backuptransport" ] \
	|| [ "$package" = "com.google.android.feedback" ] \
	|| [ "$package" = "com.google.android.gms" ] \
	|| [ "$package" = "com.google.android.gsf" ] \
	|| [ "$package" = "com.google.android.gsf.login" ] \
	|| [ "$package" = "com.google.android.launcher" ] \
	|| [ "$package" = "com.google.android.onetimeinitializer" ] \
	|| [ "$package" = "com.google.android.partnersetup" ] \
	|| [ "$package" = "com.google.android.setupwizard" ]
	then
		type="priv-app"
	else
		type="app"
	fi

	getarchitectures "$apk"
	#We manually check for each of our set of supported architectures
	#We assume NO universal packages for 32vs64 bit, so start with the 'highest' architectures first, if it matches one of those, we will NOT add it to a lower architecture
	if echo "$architectures" | grep -q "arm64" #no space, all arm64 types are valid
	then
		installapk "arm64"
	else
		if echo "$architectures" | grep -q "armeabi" #no space, all armearbi types are valid
		then
			installapk "arm"
		fi
	fi
	if echo "$architectures" | grep -q "x86_64 "
	then
		installapk "x86_64"
	else
		if echo "$architectures" | grep -q "x86 "
		then
			installapk "x86"
		fi
	fi
	if echo "$architectures" | grep -q "all" #no space (single entry)
	then
		installapk "all"
	fi
}

for argument in "$@"
do
	file="$(readlink -f "$argument")"
	if [ -f "$file" ]
	then
		if aapt dump configurations "$file" >/dev/null
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
#	arm64-v8a - ARMv8 AArch64 instruction set
#x86:
#	x86 - IA-32 instruction set
#x86_64:
#	x86_64 - Intel64 instruction set
#
#unsupported at the moment:
#mips - MIPS32 instruction set
#mips64 - MIPS64 instruction set
