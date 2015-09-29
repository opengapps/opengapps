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
  if [ -d "$1" ]; then
    for f in $1/*; do
      copy "$f" "$2/$(basename "$f")"
    done
  fi
  if [ -f "$1" ]; then
      install -D -p "$1" "$2"
  fi
}

buildfile() {
  if [ -z "$3" ]; then usearch="$ARCH"
  else usearch="$3"; fi #allows for an override

  if [ -e "$SOURCES/$usearch/$2" ]; then #check if directory or file exists
    if [ -d "$SOURCES/$usearch/$2" ]; then #if we are handling a directory
      targetdir="$build/$1/$2"
    else
      targetdir="$build/$1/$(dirname "$2")"
    fi
    if [ "$usearch" != "$ARCH" ]; then
      echo "INFO: Falling back from $ARCH to $usearch for file $2"
    fi
    install -d "$targetdir"
    copy "$SOURCES/$usearch/$2" "$targetdir" #if we have a file specific to this architecture
  else
    get_fallback_arch "$usearch"
    if [ "$usearch" != "$fallback_arch" ]; then
      buildfile "$1" "$2" "$fallback_arch"
    else
      echo "ERROR: No fallback available. Failed to build file $2"
      exit 1
    fi
  fi
}

buildapp(){
  package="$1"
  ziplocation="$2"
  targetlocation="$3"
  if [ -z "$4" ]; then usearch="$ARCH"
  else usearch="$4"; fi #allows for an override

  if getsourceforapi "$package" "$usearch"
  then
    baseversionname=""
    for dpivariant in $(echo "$sourceapks" | tr ' ' ''); do #we replace the spaces with a special char to survive the for-loop
      dpivariant="$(echo "$dpivariant" | tr '' ' ')" #and we place the spaces back again
      versionname="$(aapt dump badging "$dpivariant" 2>/dev/null | awk '/versionName/ {print $4}' | sed s/versionName=// | sed "s/'//g")"
      versionnamehack #Some packages have a different versionname, when the actual version is equal
      systemlibhack #Some packages want their libs installed as system libs
      if [ "$API" -le "19" ] || [ "$systemlib" = "true" ]; then
        liblocation="$ziplocation/common"
      else
        liblocation="$ziplocation/common/$targetlocation"
      fi

      if [ -z "$baseversionname" ]; then
        baseversionname=$versionname
        buildlib "$dpivariant" "$liblocation" "$usearch" #Use the libs from this baseversion
        printf "%44s %6s %27s" "$package" "$usearch" "$baseversionname"
      fi
      if [ "$versionname" = "$baseversionname" ]; then
        density=$(basename "$(dirname "$dpivariant")")
        buildapk "$dpivariant" "$ziplocation/$density/$targetlocation"
        printf " %s" "$density"
        echo "$ziplocation/$density/" >> "$build/app_densities.txt"
      fi
    done
    printf "\n"
  else
    get_fallback_arch "$usearch"
    if [ "$usearch" != "$fallback_arch" ]; then
      buildapp "$package" "$ziplocation" "$targetlocation" "$fallback_arch"
    else
      echo "ERROR: No fallback available. Failed to build package $package"
      exit 1
    fi
  fi
}
getsourceforapi() {
  #this functions finds the highest available acceptable api level for the given architeture
  if ! stat --printf='' "$SOURCES/$2/"*"app/$1" 2>/dev/null; then
    return 1 #appname is not there, error!?
  fi

  #sed copies filename to the beginning, to compare version, and later we remove it with cut
  for foundapk in $(find $SOURCES/$2/*app/$1 -iname '*.apk' | sed 's!.*/\(.*\)!\1/&!' | sort -r -t/ -k1,1 | cut -d/ -f2- | tr ' ' ''); do #we replace the spaces with a special char to survive the for-loop
    foundpath="$(dirname "$(dirname "$(echo "$foundapk" | tr '' ' ')")")" #and we place the spaces back again
    api="$(basename "$foundpath")"
    if [ "$api" -le "$API" ]; then
      #We need to keep them sorted
      sourceapks="$(find "$foundpath" -name "*.apk" | sed 's!.*/\(.*\)!\1/&!' | sort -r -t/ -k1,1 | cut -d/ -f2-)"
      break
    fi
  done
  if [ -z "$sourceapks" ]; then
    echo "WARNING: No APK found compatible with API level $API for package $appname on $2, lowest found: $api"
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
  if [ -f "$targetapk" ]; then
    rm "$targetapk"
  fi

  install -D "$sourceapk" "$targetapk"
  if [ "$API" -lt "23" ] && (unzip -qql "$targetapk" | grep -q "lib/"); then #only if pre-Marshmallow and the lib folder exists
    unzip -Z -1 "$targetapk" | grep "lib/" | grep -v "/crazy." | xargs zip -q -d "$targetapk" #delete all libs, except crazy-linked
  fi
}
buildlib() {
  sourceapk="$1"
  targetdir="$build/$2"
  apkarch="$3"
  libsearchpath="lib/*" #default that should never happen: all libs
  if [ "$apkarch" = "arm" ]; then
    libsearchpath="lib/armeabi*/*" #mind the wildcard
    libfallbacksearchpath=""
  elif [ "$apkarch" = "arm64" ]; then
    libsearchpath="lib/arm64*/*" #mind the wildcard
    libfallbacksearchpath="lib/armeabi*/*" #mind the wildcard
  elif [ "$apkarch" = "x86" ]; then
    libsearchpath="lib/x86/*"
    libfallbacksearchpath=""
  elif [ "$apkarch" = "x86_64" ]; then
    libsearchpath="lib/x86_64/*"
    libfallbacksearchpath="lib/x86/*"
  elif [ "$apkarch" = "mips" ]; then
    libsearchpath="lib/mips/*"
    libfallbacksearchpath=""
  elif [ "$apkarch" = "mips64" ]; then
    libsearchpath="lib/mips64/*"
    libfallbacksearchpath="lib/mips/*"
  fi
  get_fallback_arch "$apkarch"
  if [ "$(basename "$targetdir")" = "common" ]; then	#if we are installing systemwide libs
    libpath="$LIBFOLDER"
    fallbacklibpath="lib"
  else #Lollipop-style libs bundled in the APK's folder
    libpath="lib/$apkarch"
    fallbacklibpath="lib/$fallback_arch" #notice that this sometimes gives 'illegal' paths like 'lib/all', but the path is not used in those situations
  fi
  if [ "$API" -lt "23" ]; then #libextraction is only necessary on pre-Marshmallow
    if [ -n "$(unzip -Z -1 "$sourceapk" "$libsearchpath" 2>/dev/null)" ]
    then
      install -d "$targetdir/$libpath"
      unzip -qq -j -o "$sourceapk" "$libsearchpath" -x "lib/*/crazy.*" -d "$targetdir/$libpath" 2>/dev/null
    fi
    if [ "$apkarch" != "$fallback_arch" ] && [ -n "$(unzip -Z -1 "$sourceapk" "$libfallbacksearchpath" 2>/dev/null)" ]
    then
      install -d "$targetdir/$fallbacklibpath"
      unzip -qq -j -o "$sourceapk" "$libfallbacksearchpath" -x "lib/*/crazy.*" -d "$targetdir/$fallbacklibpath" 2>/dev/null
    fi
  fi
}
