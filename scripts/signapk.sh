#!/bin/bash
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
# This specific script is derived from https://code.google.com/p/signapk/

TMP="/tmp"                          # write temp files here, or try these if it won't work:

#######################
DEFKEYNAME="testkey"                  # default name of cert/key pair. script comes with AOSP testkey/media/platform/shared.
PKEY="$DEFKEYNAME.pk8"      # generated path to default private key; 'signapk-key.testkey.pk8'. 
CERT="$DEFKEYNAME.x509.pem" # generated path to default cert; 'signapk-key.testkey.x509.pem'
VERSION="0.3.1"

####################### Pointers to utils
if [ "x$OPENSSL" = "x" ]; then OPENSSL="openssl"; fi
if [ "x$PRINTF" = "x" ]; then PRINTF="printf"; fi
if [ "x$TR" = "x" ]; then TR="tr"; fi
if [ "x$SED" = "x" ]; then SED="sed"; fi
if [ "x$GREP" = "x" ]; then GREP="grep"; fi
if [ "x$READLINK" = "x" ]; then READLINK="readlink"; fi
if [ "x$UNZIP" = "x" ]; then UNZIP="unzip"; fi
if [ "x$ZIP" = "x" ]; then ZIP="zip"; fi
if [ "x$ZIPINFO" = "x" ]; then ZIPINFO="zipinfo"; fi

#######################  misc utility variables
esc=${IFS:2:2}
OLDIFS=$IFS
PAD="                                                                                                    "

#######################  debugging spew
dprint() {
  if [ $DEBUG ] && [ "$DEBUG" != "0" ]; then
    #IFS=$OLDIFS
    echo "[DEBUG $$] $*" 1>&2 
  fi
}
#######################  informational spew
p () {
  if [ ! $OPTquiet ]; then
    printf "$*"
  fi
}
#######################
ordie() {
  rc=$?
  if [ $rc -ne 0 ]; then
    if [ ! $2 ]; then
      ecode=$rc
    else
      ecode=$2
    fi
    IFS=" "
    echo "$1"
    exit $ecode
  fi
}

#######################  key/cert paranoia
chkcert() {
  #IFS=$esc
  dprint "chkcert($1,$2)"
  if [ "x$1" = "x" ] && [ "x$2" = "x" ]; then
    dprint "using defaults"
    return
  elif [ "x$1" = "x" ] || [ "x$2" = "x" ]; then
    alias="$1$2"
    if [ "$alias" != "${alias%%.pk8}" ]; then
      PKEY="$alias"
      CERT="${alias%%.pk8}.x509.pem"
      dprint "using key '$PKEY' and cert '$CERT'"
    elif [ "$alias" != "${alias%%.x509.pem}" ]; then
      PKEY="${alias%%.x509.pem}.pk8"
      CERT="$alias"
      dprint "using key '$PKEY' and cert '$CERT'"
    else
      PKEY="$DEFKEYDIR$alias.pk8"
      CERT="$DEFKEYDIR$alias.x509.pem"
      dprint "using alias '$alias': using key '$PKEY' and cert '$CERT'"
    fi
  fi
}

#######################  MANIFEST.MF entry hash: stdin - stdout 
mfhash() {
  $OPENSSL sha1 -binary |$OPENSSL base64
}

#######################  MANIFEST.MF entry: $zipfilename, $zipentryname - $ret
mfentry() {
  local hash=$($UNZIP -p "$ORIG" "$1"|mfhash)
  ret="Name: $1\r\nSHA1-Digest: $hash\r\n\r\n"
}

#######################  CERT.SF entry: $zipentryname, $mfentry - $ret
sfentry() {
  local hash=$($PRINTF "$2"|mfhash)
  ret="Name: $1\r\nSHA1-Digest: $hash\r\n\r\n"
}

#######################  serial of zip's signing cert: $zipfilename - $?, stdout
getcertid() {
  if [ -e "$1" ]; then
    cert=$($UNZIP -p "$1" 'META-INF/*.RSA' 'META-INF/*.DSA' 2> /dev/null |$OPENSSL pkcs7 -inform DER -print_certs 2> /dev/null)
    if [ $? -ne 0 ]; then
      dprint "'$1' is not a zip, trying as file"
      cert=$($OPENSSL pkcs7 -inform DER -print_certs < "$1" 2> /dev/null)
      if [ $? -ne 0 ]; then
        echo "error getting cert from '$1'"
        return 2
      fi
    fi
  else
    echo "No such file '$1'"
    return 1
  fi
  certid=$(echo "$cert"| $OPENSSL x509 -noout -serial| $SED -r "s,^(serial=),,g" )
  dprint "certid($?): '$certid'"
  echo $certid
  return 0
}

#######################  Duh.
usage() {
  echo "Usage: ${0##*/} (options) [command] (files)
commands:
  sign FILE         sign a .zip or .apk
  sign FILE1 FILE2  create a signed copy of FILE1 as FILE2
  cert FILE(s)      print cert info on FILE's signer
  certinfo FILE     print detailed cert info on FILE's signer
  cmp FILE          compare signer of FILE with default/selected cert
  cmp FILE1 FILE2   compare signer of FILE1 to signer of FILE2

options:
  -k, --key FILE    key to sign with
  -c, --cert FILE   cert to sign with
                    if -c or -k are not files then they are considered
                    aliases to builtins (ie -k testkey or -c platform)
  -f, --force       sign even if cert differs from original
  -t, --tmp DIR     use DIR for tempdir instead of '$TMP'
  -d, --debug       output debugging
  -V, --version     print '${0##*/} v$VERSION'
exit codes:
  1: read error (file 1)		2: read error (file 2)
  3: write error			4: ssl error
  5: zip write error			9: key error
  8: sign: cert mismatch		10: cmp: cert mismatch
  128: script error			255: user error
"
}
#######################  getopts() but not: @array - $args
getop() {
  origarg="$*"
  while [ "$1" ]; do
    case "$1" in
      -c|--cert)
        shift
        if [ ! "$1" ]; then usage;exit 255;fi
        OPTcert="$1"
      ;;
      -k|--key)
        shift
        if [ ! "$1" ]; then usage;exit 255;fi
        OPTkey="$1"
      ;;
      -d|--debug)
        DEBUG=1
      ;;
      -f|--force)
        OPTforce=1
      ;;
      -q|--quiet)
        OPTquiet=1
        QZIP="-q"
      ;;
      -V|--version)
        echo ${0##*/} v$VERSION;exit
      ;;
      -t|--tmp|--tmpdir)
        shift
        if [ ! "$1" ]; then usage;exit 255;fi
        OPTtmp="$1";TMP="$1"
      ;;
      --)
        shift
        while [ "$1" ]; do
          args="$args$1$esc"
          shift
        done
        return
      ;;
      -*)
        usage;exit 255;;
      *)
        args="$args$1$esc"
      ;;
    esac
    shift  
  done
}

#######################
#######################
#######################




getop "$@"
IFS="$esc"; 
set -- $args
IFS=$OLDIFS
#######################
if [ "x$1" = "xsign" ]; then
  chkcert "$OPTcert" "$OPTkey"
  if [ ! -e "$PKEY" ]; then echo "Missing private key! I looked in '$PKEY'"; exit 9 ; fi
  if [ ! -e "$CERT" ]; then echo "Missing cert! I looked in '$CERT'"; exit 9 ; fi
  IFS=$esc
  ORIG=$($READLINK -f "$2")

  mf="Manifest-Version: 1.0\r\nCreated-By: 1.0 (Android SignApk)\r\n\r\n"
  sf=""

  ZIPls=$($ZIPINFO -1 "$ORIG"); ordie "$ORIG: unzip error" 1
  if [ "x$3" != "x" ] && [ "x$3" != "x$2" ]; then
    TARGET=$($READLINK -f "$3")
    cp -a "$ORIG" "$TARGET";  ordie "Cannot write to $TARGET" 3
  else
    TARGET="$ORIG"
    if [ ! $OPTforce ]; then
      myserial=$($OPENSSL x509 -noout -serial < "$CERT" |$SED -r "s,^(serial=),,g")
      if origkey=$(getcertid "$ORIG"); then
        if [ "x$origkey" != "x$myserial" ]; then
          IFS=$OLDIFS
          echo "$ORIG is signed with a cert ($origkey) that does not match '$CERT' ($myserial). Try"
          echo "  $0 --force $origarg"
          echo "if you wish to proceed, or"
          echo "  $0 $origarg newfile"
          exit 8
        fi
        dprint "cert $myserial matches cert in $ORIG"
      fi
    fi
  fi
  IFS=$esc
  p "Checksumming $ORIG:\n\t"
  for file in $ZIPls; do
    IFS=$OLDIFS
    if [ $# -ge 3 ] && [ "x$1" != "x0" ]; then
      ret=""
      if [ "x$file" != "xMETA-INF/MANIFEST.MF" ] && [ "x$file" != "xMETA-INF/CERT.SF" ] && [ "x$file" != "xMETA-INF/CERT.RSA" ]; then
        p "$file  "
        mfentry "$file" 
        mf="$mf$ret"
        sfentry "$file" "$ret"
        sf="$sf$ret"
      fi
    fi
  done
  p "\n"
  sfhead=$($PRINTF "$mf"|mfhash)
  sf="Signature-Version: 1.0\r\nCreated-By: 1.0 (Android SignApk)\r\nSHA1-Digest-Manifest: $sfhead\r\n\r\n$sf"
  TMPDIR="${TMP}/sign-$$"
  TMPPKEY="${TMPDIR}/tmp.pkey"
  mkdir -p "$TMPDIR/META-INF"; ordie "" 3
  $PRINTF "$mf" > "${TMPDIR}/META-INF/MANIFEST.MF";  ordie "" 3
  $PRINTF "$sf" > "${TMPDIR}/META-INF/CERT.SF";  ordie "" 3
  $OPENSSL pkcs8 -inform DER -nocrypt -in "$PKEY" > "$TMPPKEY";  ordie "" 4
  $PRINTF "$sf"|$OPENSSL smime -sign -inkey "$TMPPKEY" -signer "$CERT" -binary -outform DER -noattr > "${TMPDIR}/META-INF/CERT.RSA";  ordie "" 4
  cd "${TMPDIR}"
  ENVKLUDGE="$ZIP"; unset ZIP # thanks new-version-of-infozip =[
  dprint $ENVKLUDGE "$TARGET" META-INF/MANIFEST.MF META-INF/CERT.SF META-INF/CERT.RSA
  $ENVKLUDGE "$TARGET" META-INF/MANIFEST.MF META-INF/CERT.SF META-INF/CERT.RSA;  ordie "" 5
  cd - > /dev/null
  rm -rf "${TMPDIR}"

#######################
elif [ "x$1" = "xcertinfo" ]; then
  $UNZIP -p "$2" 'META-INF/*.RSA' 'META-INF/*.DSA' 2> /dev/null | $OPENSSL pkcs7 -inform DER -print_certs -text
#######################
elif [ "x$1" = "xcert" ]; then
  shift
  packages=$($GREP 'package name' /data/system/packages.xml|$SED -r 's,(<package |>$),,g')
  p $( echo "$packages"| wc -l ) installed packages."\n"
  for i in $*; do
    unset real cert certserial title pkg name codepath system ts version shareduserid userid user
    if [ -e "$i" ]; then
      real=$($READLINK -f "$i")
      out="$real$PAD"
      cert=""
      IFS=$esc
      cert=$($UNZIP -p "$i" 'META-INF/*.RSA' 'META-INF/*.DSA' 2> /dev/null |$OPENSSL pkcs7 -inform DER -print_certs 2> /dev/null)
      if [ $? -eq 0 ]; then
        IFS=$OLDIFS
        set -- $(echo "$cert"| $OPENSSL x509 -noout -serial -subject|$SED -r "s,^(serial=|subject ?=.*/O=),,g" )
        certserial=$1
        case $certserial in
          C2E08746644A308D) title="Google";;
          936EACBE07F201DF) title="SDK Test Key";;
          F2B98E6123572C4E) title="SDK Media Key";;
          B3998086D056CFFA) title="SDK Platform Key";;
          F2A73396BD38767A) title="SDK Shared Key";;
          *) title="unknown $2";;
        esac
        real=$(echo "$real"|$SED -r 's,/(system/sd|sd-ext)/app,/data/app,')
        pkg=$(echo "$packages"|$GREP "codePath=\"$real\""|$TR -d '"' )
        if [ $? -eq 0 ]; then
          IFS=" "
          set -- $pkg          
          for p in $*; do
            IFS="="
            set -- $p
            case $1 in
              name) name=$2;;
              codePath) codepath=$2;;
              system) system=$2;;
              ts) ts=$2;;
              version) version=$2;;
              sharedUserId) shareduserid=$2;;
              userId) userid=$2;;
            esac
          done
        fi
        user="shuid:$shareduserid"
        if [ "x$shareduserid" = "x" ]; then
          user="uid:$userid"
        fi
        out="${out:0:60}  $user$PAD"
        out="${out:0:74}  $certserial$PAD"
        $PRINTF "${out:0:92}  $title\n"
      else 
        $PRINTF "${out:0:60}  Invalid\n"
      fi
    fi
  done
elif [ "x$1" = "xcmp" ]; then
  if [ "x$2" = "x" ]; then
    echo "Usage: $0 cmp [file]"
    echo "       $0 cmp [file1] [file2]"
    exit 255
  fi
  if [ "x$3" != "x" ]; then
    c1=$(getcertid "$2");  ordie "Error: $c1" 1
    c2=$(getcertid "$3");  ordie "Error: $c2" 2
  else
    chkcert "$OPTcert" "$OPTkey"
    set -- "cmp" "$2" "$CERT"
    c2=$($OPENSSL x509 -noout -serial -in "$CERT"); ordie "Error getting serial of '$CERT'" 9
    c2=$(echo $c2|$SED -r "s,^(serial=),,g")
    c1=$(getcertid "$2"); ordie "Error: $c1" 1
  fi
  if [ "$c1" != "$c2" ]; then
    echo "$2 ($c1) != $3 ($c2)" 
    exit 10
  else
    echo "$2 ($c1) == $3 ($c2)" 
    exit 0
  fi
elif [ "x$1" = "xgetcert" ]; then
  ret=$(getcertid "$2")
  echo "$? '$ret'"
else
  usage
  exit 0
fi
