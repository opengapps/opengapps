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
  logfile=""
  if [ -n "$VERSIONLOG" ]; then
    logfile="$(eval "echo \"$VERSIONLOG\"")"
    install -d "$(dirname "$logfile")"
    printf "%-6s%3s| %-61s| %-35s| %s\n--------------------------------------------------------------------------------------------------------------------\n" "Arch." "API" "Application / File / Folder" "Version Name" "DPIs" > "$logfile"
  fi
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
  if [ -z "$4" ]; then usearch="$ARCH"
  else usearch="$4"; fi #allows for an override

  case "$usearch" in
    all) targetarch="common";;  # technically with our currrent APKs-set, every that is 'all' is de-facto also 'common'
    *) targetarch="$usearch";;
  esac

  if [ -e "$SOURCES/$usearch/$1" ]; then #check if directory or file exists
    if [ -d "$SOURCES/$usearch/$1" ]; then #if we are handling a directory
      targetdir="$build/$2-$targetarch/$3/$1"
    else
      targetdir="$build/$2-$targetarch/$3/$(dirname "$1")"
    fi
    install -d "$targetdir"
    printf "%6s    %s\n" "$usearch" "$1"
    if [ -n "$logfile" ]; then
      printf "%6s   | %-s\n" "$usearch" "$1">> "$logfile"
    fi
    copy "$SOURCES/$usearch/$1" "$targetdir" #if we have a file specific to this architecture
  else
    get_fallback_arch "$usearch"
    if [ "$usearch" != "$fallback_arch" ]; then
      buildfile "$1" "$2" "$3" "$fallback_arch"
    else
      echo "ERROR: No fallback available. Failed to build file $1"
      exit 1
    fi
  fi
}

buildframework() {
  frameworkname="$1"
  ziplocation="$2"
  targetlocation="$3"
  if [ -z "$4" ]; then usearch="$ARCH"
  else usearch="$4"; fi #allows for an override

  case "$usearch" in
    all) targetarch="common";;  # technically with our currrent APKs-set, every that is 'all' is de-facto also 'common'
    *) targetarch="$usearch";;
  esac

  if getframeworkforapi "$frameworkname" "$usearch" "$API"; then
    printf "%6s-%s %s\n" "$usearch" "$api" "$frameworkname"
    if [ -n "$logfile" ]; then
      printf "%6s-%s| %-s\n" "$usearch" "$api" "$frameworkname" >> "$logfile"
    fi
    install -D -p "$sourceframework" "$build/$ziplocation-$targetarch/$targetlocation/$targetframework"
  else
    get_fallback_arch "$usearch"
    if [ "$usearch" != "$fallback_arch" ]; then
      buildframework "$frameworkname" "$ziplocation" "$targetlocation" "$fallback_arch"
    else
      echo "ERROR: No fallback available. Failed to build framework $frameworkname"
      exit 1
    fi
  fi
}

buildsystemlib() {
  libname="$1"
  ziplocation="$2"
  targetlocation="$3"
  if [ -z "$4" ]; then usearch="$ARCH"
  else usearch="$4"; fi #allows for an override

  fallback=""
  case "$libname" in
    *+fallback) libname="$(echo "$libname" | sed 's/+fallback//')"
    fallback="true";;
  esac

  case "$usearch" in
    all) targetarch="common";;  # technically with our currrent APKs-set, every that is 'all' is de-facto also 'common'
    *) targetarch="$usearch";;
  esac

  if getsystemlibforapi "$libname" "$usearch" "$API"; then
    printf "%6s-%s %s\n" "$usearch" "$api" "$libname"
    if [ -n "$logfile" ]; then
      printf "%6s-%s| %-s\n" "$usearch" "$api" "$libname" >> "$logfile"
    fi
    install -D -p "$sourcelib" "$build/$ziplocation-lib-$targetarch/$targetlocation/$targetlib"
  else
    fallback="true"
  fi
  if [ -n "$fallback" ]; then
    get_fallback_arch "$usearch"
    if [ "$usearch" != "$fallback_arch" ]; then
      buildsystemlib "$libname" "$ziplocation" "$targetlocation" "$fallback_arch"
    else
      echo "ERROR: No fallback available. Failed to build lib $libname"
      exit 1
    fi
  fi
}

getpathsystemlib(){
  libname="$1"
  if [ -z "$2" ]; then usearch="$ARCH"
  else usearch="$2"; fi #allows for an override

  fallback=""
  case "$libname" in
    *+fallback) libname="$(echo "$libname" | sed 's/+fallback//')"
    fallback="true";;
  esac

  if getsystemlibforapi "$libname" "$usearch" "$API"; then
    systemlibpath="$targetlib $systemlibpath"
  else
    fallback="true"
  fi

  if [ -n "$fallback" ]; then
    get_fallback_arch "$usearch"
    if [ "$usearch" != "$fallback_arch" ]; then
      getpathsystemlib "$libname" "$fallback_arch"
    fi
  fi
}

buildapp() {
  package="$1"
  usemaxapi="$2"
  ziplocation="$3"
  targetlocation="$4"
  if [ -z "$5" ]; then usearch="$ARCH"
  else usearch="$5"; fi #allows for an override

  minapihack #Some packages need a minimal api level to maintain compatibility with the OS

  if getapksforapi "$package" "$usearch" "$usemaxapi" "$useminapi"; then
    baseversionname=""
    for dpivariant in $(echo "$sourceapks" | tr ' ' ''); do #we replace the spaces with a special char to survive the for-loop
      dpivariant="$(echo "$dpivariant" | tr '' ' ')" #and we place the spaces back again
      getapkproperties "$dpivariant" #get versionname
      versionname="$(printf "%s" "$versionname" | cut -d ' ' -f 1)" #always cut off everything in the versionname after the space since that indicates a part that is ALWAYS at minimum dpi-specific
      versionnamehack #Some packages have a different versionname, when the actual version is equal
      systemlibhack #Some packages want their libs installed as system libs
      if [ "$API" -le "19" ] || [ "$systemlib" = "true" ]; then
        liblocation="$ziplocation-$usearch/common"
      else
        liblocation="$ziplocation-$usearch/common/$targetlocation"
      fi

      if [ -z "$baseversionname" ]; then
        baseversionname=$versionname
        buildlib "$dpivariant" "$liblocation" "$usearch" #Use the libs from this baseversion
        printf "%6s-%-2s %-61s %35s" "$usearch" "$api" "$1" "$baseversionname"  # use $1 instead of $package to show the foldername packagename instead of the getapkproperties-name to get the setupwizard name right
        if [ -n "$logfile" ]; then
          printf "%6s-%-2s| %-61s| %-35s|" "$usearch" "$api" "$1" "$baseversionname" >> "$logfile"
        fi
      fi
      if [ "$versionname" = "$baseversionname" ]; then
        density=$(basename "$(dirname "$dpivariant")")
        buildapk "$dpivariant" "$ziplocation-$usearch/$density/$targetlocation"
        printf " %s" "$density"
        if [ -n "$logfile" ]; then
          printf " %s" "$density" >> "$logfile"
        fi
        echo "$ziplocation-$usearch/$density/" >> "$build/app_densities.txt"
      fi
    done
    printf "\n"
    if [ -n "$logfile" ]; then
      printf "\n" >> "$logfile"
    fi
  else
    get_fallback_arch "$usearch"
    if [ "$usearch" != "$fallback_arch" ]; then
      buildapp "$package" "$usemaxapi" "$ziplocation" "$targetlocation" "$fallback_arch"
    else
      echo "ERROR: No fallback available. Failed to build package $package"
      exit 1
    fi
  fi
}

getapksforapi() {
  #this functions finds the highest available acceptable apk for a given api and architecture
  #$1 package, $2 arch, $3 api, $4 minapi
  if [ -z "$4" ]; then minapi="0"
  else minapi="$4"; fi #specify minimal api

  if ! stat --printf='' "$SOURCES/$2/"*"app/$1" 2>/dev/null; then
    return 1 #appname is not there, error!?
  fi

  sourceapks=""
  OLDIFS="$IFS"
  IFS="
"  #We set IFS to newline here so that spaces can survive the for loop
  #sed copies filename to the beginning, to compare version, and later we remove it with cut
  maxsdkerrorapi=""
  for foundapk in $(find $SOURCES/$2/*app/$1 -iname '*.apk' 2>/dev/null| sed 's!.*/\(.*\)!\1/&!' | sort -r -n -t/ -k1,1 | cut -d/ -f2-); do
    foundpath="$(dirname "$(dirname "$foundapk")")"
    api="$(basename "$foundpath")"
    if [ "$maxsdkerrorapi" = "$api" ]; then
      continue #if we already know that this api hit the maxsdk error, do not try it again
    fi
    if [ "$api" -le "$3" ] && [ "$api" -ge "$minapi" ]; then
      #We need to keep them sorted
      sourceapks="$(find "$foundpath" -iname '*.apk' | sed 's!.*/\(.*\)!\1/&!' | sort -r -n -t/ -k1,1 | cut -d/ -f2-)"
      for maxsdkapk in $sourceapks; do
        maxsdk="$(aapt dump badging "$maxsdkapk" 2>/dev/null | grep -a "maxSdkVersion:" | sed 's/maxSdkVersion://' | sed "s/'//g")"
        if [ -n "$maxsdk" ] && [ "$maxsdk" -lt "$3" ]; then
          echo "WARNING: Newest APK found is incompatible with API level $3 for package $1 on $2, maxSdk: $maxsdk, falling back to higher SDK"
          maxsdkerrorapi="$api"
          continue 2
        fi
        break
      done
      break
    fi
  done
  IFS="$OLDIFS"
  if [ -z "$sourceapks" ]; then
    echo "WARNING: No APK found compatible with API level $3 for package $1 on $2, lowest found: $api"
    return 1 #error
  fi
  #$sourceapks and $api have the useful returnvalues
  return 0 #return that it was a success
}

getframeworkforapi() {
  #this functions finds the highest available acceptable framework for a given api and architecture
  #$1 frameworkname, $2 arch, $3 api
  sourceframework=""
  OLDIFS="$IFS"
  IFS="
"  #We set IFS to newline here so that spaces can survive the for loop
  for foundframework in $(find $SOURCES/$2/framework/ -iname "$1" 2>/dev/null| sort -r); do
    api="$(basename "$(dirname "$foundframework")")"
    if [ "$api" -le "$3" ]; then
      sourceframework="$foundframework"
      break
    fi
  done
  IFS="$OLDIFS"
  if [ -z "$sourceframework" ]; then
    #echo "WARNING: No framework found compatible with API level $3 for framework $1 on $2, lowest found: $api"
    return 1 #error
  fi
  apiframeworkpath="$(echo "$sourceframework" | awk -F'/' '{print $(NF-1)}')" # is api number
  targetframework="$(echo "$sourceframework" | sed "s:^$SOURCES/$2/::" | sed "s:/$apiframeworkpath/:/:g")" # framework/frameworkname.jar
  #$sourceframework, $targetframework and $api have the useful returnvalues
  return 0 #return that it was a success
}

getsystemlibforapi() {
  #this functions finds the highest available acceptable lib for a given api and architecture
  #$1 libname, $2 arch, $3 api
  sourcelib=""
  OLDIFS="$IFS"
  IFS="
"  #We set IFS to newline here so that spaces can survive the for loop
  for foundlib in $(find $SOURCES/$2/lib*/ $SOURCES/$2/vendor/lib*/ -iname "$1" 2>/dev/null| sort -r); do
    api="$(basename "$(dirname "$foundlib")")"
    if [ "$api" -le "$3" ]; then
      sourcelib="$foundlib"
      break
    fi
  done
  IFS="$OLDIFS"
  if [ -z "$sourcelib" ]; then
    #echo "WARNING: No lib found compatible with API level $3 for lib $1 on $2, lowest found: $api"
    return 1 #error
  fi
  apilibpath="$(echo "$sourcelib" | awk -F'/' '{print $(NF-1)}')" # is api number
  targetlib="$(echo "$sourcelib" | sed "s:^$SOURCES/$2/::" | sed "s:/$apilibpath/:/:g")" # lib/libname.so
  #$sourcelib, $targetlib and $api have the useful returnvalues
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
  if [ "$API" -lt "23" ] && (unzip -qqql "$targetapk" | grep -q "lib/"); then #only if pre-Marshmallow and the lib folder exists
    unzip -Z -1 "$targetapk" | grep "lib/" | grep -v "/crazy." | xargs zip -q -d "$targetapk" #delete all libs, except crazy-linked
  elif [ "$API" -ge "23" ] && (unzip -qqql "$targetapk" | grep -q "lib/"); then #Marshmallow needs (if any exist) libs to be stored without compression within the APK
    unzip -qqq -o "$targetapk" -d "$targetdir" "lib/*"
    zip -q -d "$targetapk" "lib/*" #delete all libs
    CURRENTPWD="$(realpath .)" #if we ever switch to bash, make this a pushd-popd trick
    cd "$targetdir"
    zip -q -r -D -Z store -b "$targetdir" "$targetapk" "lib/" #no parameter for output and mode, we are in 'add and update existing' mode which is default. Lib files have to be stored without compression.
    cd "$CURRENTPWD"
    rm -rf "$targetdir/lib/"
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
    if [ -n "$(unzip -Z -1 "$sourceapk" "$libsearchpath" 2>/dev/null)" ]; then
      install -d "$targetdir/$libpath"
      unzip -qqq -j -o "$sourceapk" "$libsearchpath" -x "lib/*/crazy.*" -d "$targetdir/$libpath" 2>/dev/null
    fi
    if [ "$apkarch" != "$fallback_arch" ] && [ -n "$(unzip -Z -1 "$sourceapk" "$libfallbacksearchpath" 2>/dev/null)" ]; then
      install -d "$targetdir/$fallbacklibpath"
      unzip -qqq -j -o "$sourceapk" "$libfallbacksearchpath" -x "lib/*/crazy.*" -d "$targetdir/$fallbacklibpath" 2>/dev/null
    fi
  fi
}
