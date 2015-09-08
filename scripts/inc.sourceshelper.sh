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
#IMPORTCERTS="" #if this value is set to non-zero, new certificates matching above regexp will be imported
INCOMPLETEFILES=1
INVALIDCERT=2
UNSIGNEDFILES=3
APKTOOLFAILED=11

getapkproperties(){
  apkproperties="$(aapt dump badging "$1" 2>/dev/null)"
  name="$(echo "$apkproperties" | grep -a "application-label:" | sed 's/application-label://g' | sed "s/'//g")"
  package="$(echo "$apkproperties" | awk '/package:/ {print $2}' | sed s/name=//g | sed s/\'//g | awk '{print tolower($0)}')"
  versionname="$(echo "$apkproperties" | awk -F="'" '/versionName=/ {print $4}' | sed "s/'.*//g")"
  versioncode="$(echo "$apkproperties" | awk -F="'" '/versionCode=/ {print $3}' | sed "s/'.*//g")"
  sdkversion="$(echo "$apkproperties" | grep -a "sdkVersion:" | sed 's/sdkVersion://' | sed "s/'//g")"
  compatiblescreens="$(echo "$apkproperties" | grep -a "compatible-screens:'")" #the ' is added to prevent detection of lines that only have compatiblescreens but without any values
  native="$(echo "$apkproperties" | grep -av "alt-native-code:" | grep -a "native-code:" | sed 's/native-code://g' | sed "s/'//g") " # add a space at the end
  altnative="$(echo "$apkproperties" | grep -a "alt-native-code:" | sed 's/alt-native-code://g' | sed "s/'//g") " # add a space at the end
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

  sdkversionhacks

  case $package in
    "com.android.hotwordenrollment" |\
    "com.android.vending" |\
    "com.android.vending.leanback" |\
    "com.google.android.androidforwork" |\
    "com.google.android.apps.mediashell.leanback" |\
    "com.google.android.apps.gcs" |\
    "com.google.android.athome.remotecontrol" |\
    "com.google.android.athome.globalkeyinterceptor" |\
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

  if [ "$(echo $compatiblescreens)" = "" ]; then # we can't use -z here, because there can be a linecontrol character or such in it
    dpis="nodpi"
  else
    dpis=$(echo "$compatiblescreens" | grep "compatible-screens:" | grep -oE "/([0-9][0-9])[0-9]" | sort -u | tr -d '\012\015' | tr '/' '-' | cut -c 2-)
  fi
}

getarchitecturesfromlib() {
  # Some packages don't have native-code specified, but are still depending on it
  # If multiple architectures are found; we assume it to be only compatible with the highest architecture and not multi-arch
  architectures=""
  libfiles=$(unzip -qqql "$1" "lib/*" | tr -s ' ' | cut -d ' ' -f5-)
  for lib in $libfiles; do
    #this gives all files found in the lib-folder(s), check their paths for which architectures' libs are included
    arch="$(echo "$lib" | awk 'BEGIN { FS = "/" } ; {print $2}')" #add a space at the end
    if ! echo "$architectures" | grep -q "$arch "; then #only add if this architecture is not yet in the list; use a space to distinguish substrings (e.g. x86 vs x86_64)
      architectures="$architectures$arch "
    fi
  done
  if [ -z "$architectures" ]; then #If the package really has no native code
    architectures="all"
  fi
}

getsetupwizardproduct() {
  # Setupwizard has various variations, depending on product type. We need to decompile the APK to find this value
  # this function is not part of the regular getapkproperties script because it is heavy and only necessary when adding an APK
  tmpdir="$(mktemp -d)"
  if java -jar "$APKTOOL" -q d -b -f -s -o "$tmpdir" "$1"; then
    product="$(grep '<string name="product">' "$tmpdir/res/values/strings.xml" | sed -r 's#.*<string name="product">([^<]*)</string>#\1#')"
    rm -rf "$tmpdir"
  else
    return $APKTOOLFAILED
  fi
}

verifyapk() {
  notinzip=""
  if importcert "$1" "$2"; then #always import, because sometimes new certificates are supplied but it would never be detected because the exitcode of jarsigner -verify would be 0, because the existing certificates would suffice
    if ! jarsigner -verify -keystore "$CERTIFICATES/opengapps.keystore" -strict "$1" 1>/dev/null 2>&1; then
      return $UNSIGNEDFILES #contains files not signed by Google. APK not imported
    fi
  else
    return $INVALIDCERT #no valid Google certificate. Certificate and APK not imported
  fi

  manifestlist="$(unzip -p "$1" "META-INF/MANIFEST.MF" | sed ':a;N;$!ba;s/\r\n //g' | tr -d '\r' | awk -F' ' '/Name:/ {print $NF}')"
  ziplist="$(unzip -Z -1 "$1")"
  notinzip="$(printf "%s\n%s\n" "$manifestlist" "$ziplist" | grep -vxF -e "META-INF/CERT.RSA" -e "META-INF/CERT.SF" -e "META-INF/MANIFEST.MF" | sort | uniq -u)"
  if [ -n "$notinzip" ]; then
    return $INCOMPLETEFILES #files were mentioned in the signed manifest but are not present in the APK
  fi
}

importcert() {
  unzip -p "$1" "META-INF/CERT.RSA" | openssl pkcs7 -inform DER -print_certs -text | grep -q -E "$GOOGLECERT" || return 1 #Certificate is not issued by Google.
  alias="$(unzip -p "$1" "META-INF/CERT.RSA" | openssl pkcs7 -inform DER -print_certs -text | awk -F' ' '/Serial Number:/ {if(NF==2){getline nextline;gsub(/[ \t:]/,"",nextline);print "ibase=16;",toupper(nextline)}else{print "ibase=10;",$(NF-1)}}' | bc)"
  if ! keytool -list -keystore "$CERTIFICATES/opengapps.keystore" -storepass "opengapps" -noprompt -alias "$alias" 1>/dev/null 2>&1; then
    if [ -n "$IMPORTCERTS" ]; then #set this variable in your environment if you want to permit the script to update the keystore
      unzip -p "$1" "META-INF/CERT.RSA" | openssl pkcs7 -inform DER -print_certs -text | keytool -importcert -keystore "$CERTIFICATES/opengapps.keystore" -storepass "opengapps" -noprompt -alias "$alias" 1>/dev/null 2>&1
      if [ -n "$2" ]; then #silent mode if value is set
        echo "Certificate with alias $alias is signed by Google and added to the keystore"
      fi
    elif [ -z "$2" ]; then #only output if no silent mode value is set
      echo "APK contains a new Google certificate not yet available in the keystore, please contact Open GApps maintainer to get it included"
    fi
  fi
  return 0
}
