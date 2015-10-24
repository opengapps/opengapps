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

checktools() {
  missing=""
  # Check existance of specified tools and notify user of missing tools
  for command in $@; do
    # To check pseudo tool "coreutils" we check one of it's tools absent from any other package
    if [ "$command" = "coreutils" ]; then command="basename"; fi

    if ! command -v $command >/dev/null 2>&1; then
      case $command in
        basename|install|readlink|md5sum)
          echo "Coreutils is required for install, basename, readlink, md5sum and other utilities but is not installed.";;
        jarsigner|keytool)
          echo "JDK is required for jarsigner and keytools utilities but is not installed.";;
        aapt|zipalign)
          echo "Android SDK is required for aapt and zipalign utilities but is not installed.";;
        *)
          echo "$command is required but is not installed.";;
      esac
      missing="$missing $command"
    else
      case $command in
        zipalign)
          if zipalign 2>&1 | grep -q "page align stored shared object files"; then
            echo "zipalign is outdated. Install a recent version from the Android SDK." >&2
            missing="$missing $command"
          fi;;
      #*)
          #echo "$command tool found and it is up to date." >&2;;
      esac
    fi
  done

  # Bail out if any of the requested tools are missing
  if [ -n "$missing" ]; then
    echo "Aborting." >&2
    exit 1
  #else
    #echo "All tools are set."
  fi
}
