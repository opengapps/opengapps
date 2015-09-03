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
TOP="$(realpath ../)"
SCRIPTS="$TOP/scripts"
CERTIFICATES="$SCRIPTS/certificates"
GOOGLECERT="(Issuer: C=US, ST=CA, L=Mountain View, O=Google, Inc, OU=Google, Inc, CN=)|(Issuer: C=US, ST=California, L=Mountain View, O=Google Inc., OU=Android, CN=Android)"

command -v keytool >/dev/null 2>&1 || { echo "openssl is required but it's not installed.  Aborting." >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "openssl is required but it's not installed.  Aborting." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but it's not installed.  Aborting." >&2; exit 1; }

if [ -z "$1" ]; then
  echo "Usage: $0 trusted.apk"
  exit 1
fi

unzip -p "$1" "META-INF/CERT.RSA" | openssl pkcs7 -inform DER -print_certs -text | grep -E "$GOOGLECERT" || { echo "Certificate is not issued by Google.  Aborting." >&2; exit 1; }
alias="$(unzip -p "$1" "META-INF/CERT.RSA" | openssl pkcs7 -inform DER -print_certs -text | grep "Serial Number:" | awk -F' ' '{print $(NF-1)}')"
unzip -p "$1" "META-INF/CERT.RSA" | openssl pkcs7 -inform DER -print_certs -text | keytool -importcert -keystore "$CERTIFICATES/opengapps.keystore" -storepass "opengapps" -noprompt -alias "$alias"
echo "with alias $alias"
