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

preparebuildarea() {
	build="$BUILD/$ARCH/$API/$VARIANT"
	echo "Cleaning build area: $build"
	rm -rf "$build"
	install -d "$build"
	install -d "$CACHE"
}

copy() {
	if [ -d "$1" ]
	then
		for f in $1/*; do
			copy "$f" "$2/$(basename "$f")"
		done
	fi
	if [ -f "$1" ]
	then
  		install -D -p "$1" "$2"
	fi
}

buildfile() {
	if [ -e "$SOURCES/$ARCH/$2" ];then #check if directory or file exists
		if [ -d "$SOURCES/$ARCH/$2" ];then #if we are handling a directory
			targetdir="$build/$1/$2"
		else
			targetdir="$build/$1/$(dirname "$2")"
		fi
		install -d "$targetdir"
		copy "$SOURCES/$ARCH/$2" "$targetdir" #if we have a file specific to this architecture
	elif [ -e "$SOURCES/all/$2" ];then
		if [ -d "$SOURCES/all/$2" ];then #if we are handling a directory
			targetdir="$build/$1/$2"
		else
			targetdir="$build/$1/$(dirname "$2")"
		fi
		install -d "$targetdir"
		copy "$SOURCES/all/$2" "$targetdir" #use architecure independent file
	else
		echo "WARNING: file $2 does not exist in the sources for $ARCH"
	fi
}

buildapp(){
	package="$1"
	ziplocation="$2"
	targetlocation="$3"
	if [ -z "$4" ]; then SOURCEARCH="$ARCH"
	else SOURCEARCH="$4"; fi #allows for an override

	if getsourceforapi "$package"
	then
		baseversionname=""
		for dpivariant in $(echo "$sourceapks" | tr ' ' ''); do #we replace the spaces with a special char to survive the for-loop
			dpivariant="$(echo "$dpivariant" | tr '' ' ')" #and we place the spaces back again
			versionname="$(aapt dump badging "$dpivariant" 2>/dev/null | grep "versionName" | awk '{print $4}' | sed s/versionName=// | sed "s/'//g")"

			versionnamehack #Some packages have a different versionname, when the actual version is equal

			if [ -z "$baseversionname" ]; then
				baseversionname=$versionname
				buildlib "$dpivariant" "$ziplocation/common/$targetlocation" #Use the libs from this baseversion
				printf "%44s %22s" "$package" "$baseversionname"
			fi
			if [ "$versionname" = "$baseversionname" ]; then
				density=$(basename "$(dirname "$dpivariant")")
				buildapk "$dpivariant" "$ziplocation/$density/$targetlocation"
				echo -n " $density"
				echo "$ziplocation/$density/" >> "$build/app_densities.txt"
			fi
		done
		printf "\n"
	else
		if [ "$SOURCEARCH" != "$FALLBACKARCH" ]
		then
			echo "WARNING: Falling back from $ARCH to $FALLBACKARCH for package $package"
			buildapp "$package" "$ziplocation" "$targetlocation" "$FALLBACKARCH"
		else
			echo "ERROR: No fallback available. Failed to build package $package on $ARCH"
			exit 1
		fi
	fi
}
getsourceforapi() {
	appname="$1"
	#loop over all source-instances and find the highest available acceptable api level
	sourcearch=""
	sourceall=""
	sourceapks=""
	if stat --printf='' "$SOURCES/$SOURCEARCH/"*"app/$appname" 2>/dev/null
	then
		sourcearch="find $SOURCES/$SOURCEARCH/*app/$appname -iname '*.apk'"
		sourceall=" & " #glue
	fi
	if stat --printf='' "$SOURCES/all/"*"app/$appname" 2>/dev/null
	then
		sourceall="${sourceall}find $SOURCES/all/*app/$appname -iname '*.apk'"
	else
		sourceall="" #undo glue
	fi
	if [ -z "$sourcearch" ] && [ -z "$sourceall" ]
	then
		return 1 #appname is not there, error!?
	fi

	#sed copies filename to the beginning, to compare version, and later we remove it with cut
	for foundapk in $(eval "$sourcearch$sourceall" | sed 's!.*/\(.*\)!\1/&!' | sort -r -t/ -k1,1 | cut -d/ -f2- | tr ' ' ''); do #we replace the spaces with a special char to survive the for-loop
		foundpath="$(dirname "$(dirname "$(echo "$foundapk" | tr '' ' ')")")" #and we place the spaces back again
		api="$(basename "$foundpath")"
		if [ "$api" -le "$API" ]
		then
			#We need to keep them sorted
			sourceapks="$(find "$foundpath" -name "*.apk" | sed 's!.*/\(.*\)!\1/&!' | sort -r -t/ -k1,1 | cut -d/ -f2-)"
			break
		fi
	done
	if [ -z "$sourceapks" ]
	then
		echo "WARNING: No APK found compatible with API level $API for package $appname on $SOURCEARCH, lowest found: $api"
		return 1 #error
	fi
	#$sourceapks has the useful returnvalue
	return 0 #return that it was a success
}
buildapk() {
	sourceapk="$1"
	targetdir="$build/$2"
	targetapk="$targetdir/$(basename "$targetdir").apk"
	if [ "$API" -le "19" ]; then #We will do this as long as we support KitKat
		targetapk="$targetdir.apk"
		targetdir="$(dirname "$targetapk")"
	fi
	install -d "$targetdir"
	if [ -f "$targetapk" ]
		then
		rm "$targetapk"
	fi

	zip -q -b "$targetdir" -U "$sourceapk" -O "$targetapk" --exclude "lib*"
}
buildlib() {
	sourceapk="$1"
	targetdir="$build/$2"
	libsearchpath="lib/*" #default that should never happen: all libs
	if [ "$SOURCEARCH" = "arm" ]; then
		libsearchpath="lib/armeabi*/*" #mind the wildcard
		libfallbacksearchpath=""
	elif [ "$SOURCEARCH" = "arm64" ]; then
		libsearchpath="lib/arm64*/*" #mind the wildcard
		libfallbacksearchpath="lib/armeabi*/*" #mind the wildcard
	elif [ "$SOURCEARCH" = "x86" ]; then
		libsearchpath="lib/x86/*"
		libfallbacksearchpath=""
	elif [ "$SOURCEARCH" = "x86_64" ]; then
		libsearchpath="lib/x86_64/*"
		libfallbacksearchpath="lib/x86/*"
	elif [ "$SOURCEARCH" = "mips" ]; then
		libsearchpath="lib/mips/*"
		libfallbacksearchpath=""
	elif [ "$SOURCEARCH" = "mips64" ]; then
		libsearchpath="lib/mips64/*"
		libfallbacksearchpath="lib/mips/*"
	fi
	if [ "$API" -le "19" ]; then #We will do this as long as we support KitKat
		targetdir=$(dirname "$(dirname "$targetdir")")
		if [ -n "$(unzip -qql "$sourceapk" "$libsearchpath" | cut -c1- | tr -s ' ' | cut -d' ' -f5-)" ]
		then
			install -d "$targetdir/lib"
			unzip -q -j -o "$sourceapk" -d "$targetdir/lib/" "$libsearchpath"
		fi
	else #This is Lollipop, much more nice :-)
		if [ -n "$(unzip -qql "$sourceapk" "$libsearchpath" | cut -c1- | tr -s ' ' | cut -d' ' -f5-)" ]
		then
			install -d "$targetdir/lib/$SOURCEARCH"
			unzip -q -j -o "$sourceapk" -d "$targetdir/lib/$SOURCEARCH" "$libsearchpath"
		fi
		if [ "$SOURCEARCH" != "$FALLBACKARCH" ] && [ -n "$(unzip -qql "$sourceapk" "$libfallbacksearchpath" | cut -c1- | tr -s ' ' | cut -d' ' -f5-)" ]
		then
			install -d "$targetdir/lib/$FALLBACKARCH"
			unzip -q -j -o "$sourceapk" -d "$targetdir/lib/$FALLBACKARCH" "$libfallbacksearchpath"
		fi
	fi
}
