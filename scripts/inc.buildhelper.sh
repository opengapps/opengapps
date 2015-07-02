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

clean() {
	echo "Cleaning build area: $build"
	rm -rf "$build"
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
	#buildfile needs slashes when used, unlike the buildapp
	targetdir="$build$2"
	if [ -e "$SOURCES/$ARCH/$1" ] #check if directory or file exists
	then
		install -d "$targetdir"
		copy "$SOURCES/$ARCH/$1" "$targetdir" #if we have a file specific to this architecture
	elif [ -e "$SOURCES/all/$1" ]
	then
		install -d "$targetdir"
		copy "$SOURCES/all/$1" "$targetdir" #use architecure independent file
	else
		echo "WARNING: file $1 does not exist in the sources for $ARCH"
	fi
}

buildapp(){
	package="$1"
	ziplocation="$2"
	targetlocation="$3"
	if [ "x$4" = "x" ]; then SOURCEARCH="$ARCH"
	else SOURCEARCH="$4"; fi #allows for an override

	if getsourceforapi "$package"
	then
		baseversionname=""
		for dpivariant in $(echo "$sourceapks" | tr ' ' ''); do #we replace the spaces with a special char to survive the for-loop
			dpivariant="$(echo "$dpivariant"| tr '' ' ')" #and we place the spaces back again
			versionname="$(aapt dump badging "$dpivariant" 2>/dev/null | grep "versionName" |awk '{print $4}' |tr -d "versionName=" |tr -d "/'")"
			case "$package" in
				#the Drive/Docs/Sheets/Slides variate even the last two different digits of the versionName per DPI variant, so we only take the first 10 chars
				com.google.android.apps.docs*) versionname="$(echo "$versionname" | cut -c 1-10)";;
			esac
			if [ -z "$baseversionname" ]; then
				baseversionname=$versionname
				buildlib "$dpivariant" "$ziplocation/common/$targetlocation" #Use the libs from this baseversion
				printf "%44s %17s" "$package" "$baseversionname"
			fi
			if [ "$versionname" = "$baseversionname" ]; then
				density=$(basename "$(dirname "$dpivariant")")
				buildapk "$dpivariant" "$ziplocation/$density/$targetlocation"
				printf " $density"
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
	for foundapk in $(echo "$(eval "$sourcearch$sourceall")"\
			| sed 's!.*/\(.*\)!\1/&!'\
			| sort -r -t/ -k1,1\
			| cut -d/ -f2-\
			| tr ' ' ''); do #we replace the spaces with a special char to survive the for-loop
		foundpath="$(dirname "$(dirname "$(echo "$foundapk" | tr '' ' ')")")" #and we place the spaces back again
		api="$(basename "$foundpath")"
		if [ "$api" -le "$API" ]
		then
			#We need to keep them sorted
			sourceapks="$(find "$foundpath" -name "*.apk"\
			| sed 's!.*/\(.*\)!\1/&!'\
			| sort -r -t/ -k1,1\
			| cut -d/ -f2-)"
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
	targetdir="$build$2"
	if [ "$API" -le "19" ]; then ##We will do this as long as we support KitKat
		targetapk="$targetdir.apk"
		install -D "$sourceapk" "$targetapk" #inefficient, we will write this file, just to make the higher directories
		rm "$targetapk"
		zip -q -U "$sourceapk" -O "$targetapk" --exclude "lib*"
	else ##This is Lollipop, much more nice :-)
		targetapk="$targetdir/$(basename "$targetdir").apk"
		if [ -f "$targetapk" ]
			then
			rm "$targetapk"
		fi
		install -d "$targetdir"
		zip -q -U "$sourceapk" -O "$targetapk" --exclude "lib*"
	fi
}
buildlib() {
	sourceapk="$1"
	targetdir="$build$2"
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
	if [ "$API" = "19" ]; then ##We will do this as long as we support KitKat
		targetdir=$(dirname "$(dirname "$targetdir")")
		if [ "x$(unzip -qql "$sourceapk" "$libsearchpath" | cut -c1- | tr -s ' ' | cut -d' ' -f5-)" != "x" ]
		then
			install -d "$targetdir/lib"
			unzip -q -j -o "$sourceapk" -d "$targetdir/lib/" "$libsearchpath"
		fi
	else ##This is Lollipop, much more nice :-)
		if [ "x$(unzip -qql "$sourceapk" "$libsearchpath" | cut -c1- | tr -s ' ' | cut -d' ' -f5-)" != "x" ]
		then
			install -d "$targetdir/lib/$SOURCEARCH"
			unzip -q -j -o "$sourceapk" -d "$targetdir/lib/$SOURCEARCH" "$libsearchpath"
		fi
		if [ "$SOURCEARCH" != "$FALLBACKARCH" ] && [ "x$(unzip -qql "$sourceapk" "$libfallbacksearchpath" | cut -c1- | tr -s ' ' | cut -d' ' -f5-)" != "x" ]
		then
			install -d "$targetdir/lib/$FALLBACKARCH"
			unzip -q -j -o "$sourceapk" -d "$targetdir/lib/$FALLBACKARCH" "$libfallbacksearchpath"
		fi
	fi
}
