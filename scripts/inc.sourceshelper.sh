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
GOOGLECERT="Issuer: C=US, ST=C(A|alifornia), L=Mountain View, O=Google((|,) Inc(|.)|), OU=(Google((|,) Inc(|.)|)|Android), CN="
#IMPORTCERTS=#if this value is set, new certificates matching above regexp will be imported

getapkproperties(){
  apkproperties="$(aapt dump badging "$1" 2>/dev/null)"
  name="$(echo "$apkproperties" | grep -a "application-label:" | sed 's/application-label://g' | sed "s/'//g")"
  package="$(echo "$apkproperties" | awk '/package:/ {print $2}' | sed s/name=//g | sed s/\'//g | awk '{print tolower($0)}')"
  versionname="$(echo "$apkproperties" | awk '/versionName=/ {print $4}' | sed s/versionName=// | sed "s/'//g")"
  versioncode="$(echo "$apkproperties" | awk '/versionCode=/ {print $3}' | sed s/versionCode=// | sed "s/'//g")"
  sdkversion="$(echo "$apkproperties" | grep -a "sdkVersion:" | sed 's/sdkVersion://' | sed "s/'//g")"
  compatiblescreens="$(echo "$apkproperties" | grep -a "compatible-screens:'")" #the ' is added to prevent detection of lines that only have compatiblescreens but without any values
  native="$(echo "$apkproperties" | grep -a "native-code:" | sed 's/native-code://g' | sed "s/'//g")"
  leanback="$(echo "$apkproperties" | grep -a "android.software.leanback" | awk -F [.\'] '{print $(NF-1)}')"
  case "$versionname" in
    *leanback*) leanback="leanback";;
  esac

  if [ -n "$leanback" ]; then
    case "$package" in
      *inputmethod*) ;; #if package is an inputmethod, it will have leanback as feature described, but we don't want it recognized as such
      *.leanback) ;; #if package already has leanback at the end of its name, we don't need to add it ourselves
      *) package="$package.$leanback";; #special leanback versions need a different packagename
    esac
  fi

  case $package in
    "com.android.vending" |\
    "com.android.vending.leanback" |\
    "com.google.android.androidforwork" |\
    "com.google.android.apps.mediashell.leanback" |\
    "com.google.android.apps.gcs" |\
    "com.google.android.athome.remotecontrol" |\
    "com.google.android.atv.customization" |\
    "com.google.android.backuptransport" |\
    "com.google.android.configupdater" |\
    "com.google.android.contacts" |\
    "com.google.android.dialer" |\
    "com.google.android.feedback" |\
    "com.google.android.gms" |\
    "com.google.android.gms.leanback" |\
    "com.google.android.googlequicksearchbox" |\
    "com.google.android.gsf" |\
    "com.google.android.gsf.login" |\
    "com.google.android.katniss.leanback" |\
    "com.google.android.leanbacklauncher.leanback" |\
    "com.google.android.onetimeinitializer" |\
    "com.google.android.packageinstaller" |\
    "com.google.android.partnersetup" |\
    "com.google.android.setupwizard" |\
    "com.google.android.tungsten.setupwraith" |\
    "com.google.android.tag" |\
    "com.google.android.tungsten.overscan" |\
    "com.google.android.tungsten.setupwraith" |\
    "com.google.android.tv.leanback" |\
    "com.google.android.tv.remote" |\
    "com.google.android.tv.remotepairing") type="priv-app";;
    *) type="app";;
  esac

  #we do this on purpose after the priv-app detection to emulate the priv-app of the normal app
  if [ -n "$BETA" ]; then
    package="$package.$BETA"
  fi

  beta="" #make sure value is initialized
  case "$1" in
    *.beta/*) beta="beta";; #report beta status as a property
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

verifyapk() {
  notinzip=""
  if importcert "$1"; then #always import, because sometimes new certificates are supplied but it would never be detected because the exitcode of jarsigner -verify would be 0, because the existing certificates would suffice
    if ! jarsigner -verify -keystore "$CERTIFICATES/opengapps.keystore" -strict "$1" 1>/dev/null 2>&1; then
      return 1 #contains files not signed by Google. APK not imported
    fi
  else
    return 1 #no valid Google certificate. Certificate and APK not imported
  fi

  manifestlist="$(unzip -p "$1" "META-INF/MANIFEST.MF" | sed ':a;N;$!ba;s/\r\n //g' | tr -d '\r' | awk -F' ' '/Name:/ {print $NF}')"
  ziplist="$(unzip -Z -1 "$1")"
  notinzip="$(printf "%s\n%s\n" "$manifestlist" "$ziplist" | grep -vxF -e "META-INF/CERT.RSA" -e "META-INF/CERT.SF" -e "META-INF/MANIFEST.MF" | sort | uniq -u)"
  if [ -n "$notinzip" ]; then
    return 1 #files were mentioned in the signed manifest but are not present in the APK
  fi
}

importcert() {
  unzip -p "$1" "META-INF/CERT.RSA" | openssl pkcs7 -inform DER -print_certs -text | grep -q -E "$GOOGLECERT" || return 1 #Certificate is not issued by Google.
  alias="$(unzip -p "$1" "META-INF/CERT.RSA" | openssl pkcs7 -inform DER -print_certs -text | awk -F' ' '/Serial Number:/ {if(NF==2){getline nextline;gsub(/[ \t:]/,"",nextline);print "ibase=16;",toupper(nextline)}else{print "ibase=10;",$(NF-1)}}' | bc)"
  if keytool -keystore "$CERTIFICATES/opengapps.keystore" -storepass "opengapps" -noprompt -alias "$alias" 1>/dev/null 2>&1; then
    if [ -z "$IMPORTCERTS" ]; then #set this variable in your environment if you want to permit the script to update the keystore
      unzip -p "$1" "META-INF/CERT.RSA" | openssl pkcs7 -inform DER -print_certs -text | keytool -importcert -keystore "$CERTIFICATES/opengapps.keystore" -storepass "opengapps" -noprompt -alias "$alias" 1>/dev/null 2>&1
      echo "Certificate with alias $alias is signed by Google and added to the keystore"
    else
      echo "APK contains a new Google certificate not yet available in the keystore, please contact Open GApps maintainer to get it included"
    fi
  fi
  return 0
}
