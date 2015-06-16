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
			copy "$f" "$2/$(basename $f)"
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
	install -d "$targetdir"
	if [ -e "$SOURCES/$ARCH/$1" ] #check if directory or file exists
	then
		copy "$SOURCES/$ARCH/$1" "$targetdir" #if we have a file specific to this architecture
	else
		copy "$SOURCES/all/$1" "$targetdir" #use architecure independent file
	fi
}
buildapp() {
	package="$1"
	targetlocation="$2"
	if [ "x$3" = "x" ]; then SOURCEARCH="$ARCH"
	else SOURCEARCH="$3"; fi #allows for an override

	if getsourceforapi $package
	then
		buildapk "$package" "$targetlocation"
		buildlib "$package" "$targetlocation"
		echo "Built $package version "$(basename -s .apk "$sourceapk")
	else
		if [ "$SOURCEARCH" != "$FALLBACKARCH" ]
		then
			echo "WARNING: Falling back from $ARCH to $FALLBACKARCH for package $package"
			buildapp "$package" "$targetlocation" "$FALLBACKARCH"
		else
			echo "ERROR: Failed to build package $package on $ARCH"
			exit 1
		fi
	fi
}
builddpiapp(){
	package="$1"
	targettoplocation="$2" # is also used as variablename's identifier (for installdata.sh)
	targetsublocation="$3"
	if [ "x$4" = "x" ]; then SOURCEARCH="$ARCH"
	else SOURCEARCH="$4"; fi #allows for an override

	if getversion "$package.0" #universal DPI version is our benchmark
	then
		dpiversion="$getversion"
		dpitargets=""
		#$sourceapk is because of getversion still the one of the '0' variant
		buildapk "$package.0" "$targettoplocation/0/$targetsublocation"
		buildlib "$package.0" "$targettoplocation/common/$targetsublocation"
		for v in $DENSITIES; do
			if comparebaseversion "$dpiversion" "$package.$v"
			then
				dpitargets="$dpitargets $v"
				#the value of $sourceapk has been changed for us by calling the comparebaseversion
				buildapk "$package.$v" "$targettoplocation/$v/$targetsublocation"
			fi
		done
		echo "Built $package with extra DPI variants:$dpitargets of universal version $dpiversion"
		eval "$targettoplocation=\$dpitargets" #store the found dpi versions in ${targettoplocation
	else
		if [ "$SOURCEARCH" != "$FALLBACKARCH" ]
		then
			echo "WARNING: Falling back from $ARCH to $FALLBACKARCH for package $package"
			builddpiapp "$package" "$targettoplocation" "$targetsublocation" "$FALLBACKARCH"
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
	sourceapk=""
	if stat --printf='' "$SOURCES/$SOURCEARCH/"*"app/$appname" 2>/dev/null
	then
		sourcearch="find $SOURCES/$SOURCEARCH/*app/$appname -iname '*.apk'"
		sourceall=" & " #glue
	fi
	if stat --printf='' "$SOURCES/all/"*"app/$appname" 2>/dev/null
	then
		sourceall="$sourceall""find $SOURCES/all/*app/$appname -iname '*.apk'"
	else
		sourceall="" #undo glue
	fi
	if [ "$sourcearch" = "" ] && [ "$sourceall" = "" ]
	then
		return 1 #appname is not there, error!?
	fi
	#sed copies filename to the beginning, to compare version, and later we remove it with cut
	for foundapk in `{ eval "$sourcearch$sourceall"; }\
			| sed 's!.*/\(.*\)!\1/&!'\
			| sort -r -t/ -k1,1\
			| cut -d/ -f2-`; do
		api=$(basename $(dirname "$foundapk"))
		if [ "$api" -le "$API" ]
		then
			sourceapk=$foundapk
			break
		fi
	done
	if [ "$sourceapk" = "" ]
	then
		echo "WARNING: No APK found compatible with API level $API for package $appname on $SOURCEARCH, lowest found: $api"
		return 1 #error
	fi
	#$sourceapk has the useful returnvalue
	return 0 #return that it was a success
}
buildapk() {
	targetdir=$build$2
	if [ "$API" -le "19" ]; then ##We will do this as long as we support KitKat
		targetapk="$targetdir.apk"
		install -D "$sourceapk" "$targetapk" #inefficient, we will write this file, just to make the higher directories
		rm "$targetapk"
		zip -q -U "$sourceapk" -O "$targetapk" --exclude "lib*"
	else ##This is Lollipop, much more nice :-)
		targetapk="$targetdir/$(basename $targetdir).apk"
		if [ -f "$targetapk" ]
			then
			rm "$targetapk"
		fi
		install -d "$targetdir"
		zip -q -U "$sourceapk" -O "$targetapk" --exclude "lib*"
	fi
}
buildlib() {
	targetdir=$build$2
	libsearchpath="lib/*" #default that should never happen: all libs
	if [ "$SOURCEARCH" = "arm" ]; then
		libsearchpath="lib/armeabi*/*" #mind the wildcard
	elif [ "$SOURCEARCH" = "arm64" ]; then
		libsearchpath="lib/arm64*/*" #mind the wildcard
	elif [ "$SOURCEARCH" = "x86" ]; then
		libsearchpath="lib/x86/*"
	elif [ "$SOURCEARCH" = "x86_64" ]; then
		libsearchpath="lib/x86_64/*"
	elif [ "$SOURCEARCH" = "mips" ]; then
		libsearchpath="lib/mips/*"
	elif [ "$SOURCEARCH" = "mips64" ]; then
		libsearchpath="lib/mips64/*"
	fi
	if [ "$API" = "19" ]; then ##We will do this as long as we support KitKat
		targetdir=$(dirname $(dirname "$targetdir"))
		if [ "x`unzip -qql "$sourceapk" $libsearchpath | cut -c1- | tr -s ' ' | cut -d' ' -f5-`" != "x" ]
			then
			install -d "$targetdir/lib"
			unzip -q -j -o "$sourceapk" -d "$targetdir/lib" "$libsearchpath"
		fi
	else ##This is Lollipop, much more nice :-)
		if [ "x`unzip -qql "$sourceapk" $libsearchpath | cut -c1- | tr -s ' ' | cut -d' ' -f5-`" != "x" ]
			then
			install -d "$targetdir/lib/$SOURCEARCH"
			unzip -q -j -o "$sourceapk" -d "$targetdir/lib/$SOURCEARCH" "$libsearchpath"
		fi
	fi
}
getversion(){
	if getsourceforapi "$1"
	then
		getversion=`aapt dump badging "$sourceapk" | grep "versionCode=" |awk '{print $3}' |tr -d "/versionCode='"`
	else
		return 1
	fi
	return 0
}
comparebaseversion(){
	#returns true if both versions are equal
	#versionnumber to compare with is in $1
	#packageID to compare with is in $2
	baseversion1=`echo "$1" | sed 's/.$//'`
	if getversion "$2" #we rely on the fact that this method calls getsourceforapi and changes $sourceapk for us
	then
		baseversion2=`echo "$getversion" | sed 's/.$//'`
		test "$baseversion1" = "$baseversion2"
		return $?  #ugly, but I fail to get it more nice than this :-/
	else
		return 1 #the package does not even exist
	fi
}
