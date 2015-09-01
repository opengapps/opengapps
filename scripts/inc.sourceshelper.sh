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
LOWESTAPI_all="19"
LOWESTAPI_arm="19"
LOWESTAPI_arm64="21"
LOWESTAPI_x86="19"
LOWESTAPI_x86_64="21"

getapkproperties(){
  apkproperties="$(aapt dump badging "$1" 2>/dev/null)"
  name="$(echo "$apkproperties" | grep "application-label:" | sed 's/application-label://g' | sed "s/'//g")"
  package="$(echo "$apkproperties" | grep package: | awk '{print $2}' | sed s/name=//g | sed s/\'//g | awk '{print tolower($0)}')"
  versionname="$(echo "$apkproperties" | grep "versionName" | awk '{print $4}' | sed s/versionName=// | sed "s/'//g")"
  versioncode="$(echo "$apkproperties" | grep "versionCode=" | awk '{print $3}' | sed s/versionCode=// | sed "s/'//g")"
  sdkversion="$(echo "$apkproperties" | grep "sdkVersion:" | sed 's/sdkVersion://' | sed "s/'//g")"
  compatiblescreens="$(echo "$apkproperties" | grep "compatible-screens:")"
  native="$(echo "$apkproperties" | grep "native-code:" | sed 's/native-code://g' | sed "s/'//g")"
  leanback="$(echo "$apkproperties" | grep "android.software.leanback" | awk -F [.\'] '{print $(NF-1)}')"
  case "$versionname" in
    *leanback*) leanback="leanback";;
  esac

  if [ -n "$leanback" ]; then
    case "$package" in
      *.leanback) ;; #if package already has leanback at the end of its name, we don't need to add it ourselves
      *) package="$package.$leanback";; #special leanback versions need a different packagename
    esac
  fi

  case $package in
    "com.google.android.backuptransport" |\
    "com.google.android.feedback" |\
    "com.google.android.gms" |\
    "com.google.android.googlequicksearchbox" |\
    "com.google.android.gsf" |\
    "com.google.android.gsf.login" |\
    "com.google.android.onetimeinitializer" |\
    "com.google.android.partnersetup" |\
    "com.google.android.setupwizard" |\
    "com.google.android.tag" |\
    "com.google.android.talk" |\
    "com.google.android.apps.walletnfcrel") type="priv-app";;
    *) type="app";;
  esac

  if [ "$compatiblescreens" = "" ]; then # we can't use -z here, because there can be a linecontrol character or such in it
    dpis="nodpi"
  else
    dpis=$(echo "$compatiblescreens" | grep "compatible-screens:" | grep -oE "/([0-9][0-9])[0-9]" | uniq | tr -d '\012\015' | tr '/' '-' | cut -c 2-)
  fi
}

getarchitectures() {
  architectures=""
  if [ -z "$native" ]; then
    #Some packages don't have native-code specified, but are still depending on it.
    #So an extra check is necessary before declaring it suitable for all platforms
    libfiles=$(unzip -qql "$1" lib/* | tr -s ' ' | cut -d ' ' -f5-)
    for lib in $libfiles; do
      #this gives all files found in the lib-folder(s), check their paths for which architectures' libs are included
      arch="$(echo "$lib" | awk 'BEGIN { FS = "/" } ; {print $2}')"
      echo "$architectures" | grep -q "$arch"
      if [ $? -eq 1 ]; then #only add if this architecture is not yet in the list
        architectures="$architectures$arch "
      fi
    done
    if [ -z "$architectures" ]; then #If the package really has no native code
      architectures="all"
    fi
  else
    for arch in $native; do
      architectures="$architectures$arch "
    done
  fi
}
