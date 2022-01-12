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
makegprop() {
  echo "# begin addon properties
ro.addon.type=gapps
ro.addon.arch=$ARCH
ro.addon.sdk=$API
ro.addon.platform=$PLATFORM
ro.addon.open_type=$VARIANT
ro.addon.open_version=$DATE
# end addon properties" >"$build/$1"
  EXTRACTFILES="$EXTRACTFILES $1"
}

makegappsremovetxt() {
  gapps_remove=""
  if [ "$API" -le "21" ] && [ "$GAPPSREMOVEVARIANT" = "super" ]; then
    get_supported_variants "stock" # On 5.0 and lower the largest package is stock instead of super for the "regular" package-type
  else
    get_supported_variants "$GAPPSREMOVEVARIANT" # Retrieve the largest package of the package-type branch
  fi
  get_gapps_list "$supported_variants"
  for gapp in $gapps_list; do
    get_package_info "$gapp"
    if [ -n "$packagetarget" ]; then
      gapps_remove="/system/$packagetarget$REMOVALSUFFIX
$gapps_remove"
      if [ $packagetarget = "priv-app/PrebuiltGmsCorePi" ]; then
        # On Pie Emulator, the image has priv-app/PrebuiltGmsCore and not priv-app/PrebuiltGmsCorePi
        gapps_remove="/system/priv-app/PrebuiltGmsCore$REMOVALSUFFIX
$gapps_remove"
      fi
    fi
    for lib in $packagelibs; do
      systemlibpath=""
      getpathsystemlib "$lib"
      for libpath in $systemlibpath; do
        gapps_remove="/system/$libpath
$gapps_remove"
      done
    done
    for file in $packagefiles; do
      gapps_remove="/system/$file
$gapps_remove"
    done
    for extraline in $packagegappsremove; do
      gapps_remove="/system/$extraline
$gapps_remove"
    done
  done
  printf "%s" "$gapps_remove" | sort -u >"$build/$1" # make unique for the VRmode entries
  EXTRACTFILES="$EXTRACTFILES $1"
}

makeupdatebinary() {
  echo '#!/sbin/sh
#This file is part of The Open GApps script of @mfonville.
#
#    The Open GApps scripts are free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version, w/Open GApps installable zip exception.
#
#    These scripts are distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    This Open GApps installer-runtime is because of the Open GApps installable
#    zip exception de-facto LGPLv3 licensed.
#
export OPENGAZIP="$3"
export OUTFD="/proc/self/fd/$2"
export TMP="/tmp"
case "$(uname -m)" in
  *86*) export BINARCH="x86";;  # e.g. Zenfone is i686
  *ar*) export BINARCH="arm";; # i.e. armv7l and aarch64
esac
bb="$TMP/'"$2"'-$BINARCH"
l="$TMP/bin"
ui_print() {
  echo "ui_print $1
    ui_print" >> $OUTFD
}
setenforce 0
for f in '"$4"'; do
  unzip -o "$OPENGAZIP" "$f" -d "$TMP"
done
for f in '"$5"'; do
  chmod +x "$TMP/$f"
done
if [ -e "$bb" ]; then
  install -d "$l"
  for i in $($bb --list); do
    if ! ln -sf "$bb" "$l/$i" && ! $bb ln -sf "$bb" "$l/$i" && ! $bb ln -f "$bb" "$l/$i"; then
      # create script wrapper if symlinking and hardlinking failed because of restrictive selinux policy
      if ! echo "#!$bb" > "$l/$i" || ! chmod +x "$l/$i" ; then
        ui_print "ERROR 10: Failed to set-up Open GApps'"'"' pre-bundled '"$2"'"
        ui_print "Please use TWRP as recovery instead"
        exit 1
      fi
    fi
  done
  PATH="$l:$PATH" $bb ash "$TMP/'"$3"'" "$@"
  exit "$?"
else
  ui_print "ERROR 64: Wrong architecture to set-up Open GApps'"'"' pre-bundled '"$2"'"
  exit 1
fi' >"$build/$1"
}

# Reads stdin and for each variable name argument VAR replaces @VAR@
# with the value of $VAR and prints the result to stdout.
substitute_vars() {
  subst_vars_sed=''
  for subst_var in "$@"; do
    eval "subst_val=\$$subst_var"
    # Escape characters that are special in the sed "s" function's
    # replacement text (ampersand, backslash, and newline). The string
    # "EOV" is appended to the value and then removed so that trailing
    # newlines in the variable's value are preserved.
    subst_val_esc=$(printf %sEOV\\n "$subst_val" | sed -e 's/[&\]/\\&/g;s/.*/&\\/')
    subst_val_esc=${subst_val_esc%EOV*}
    subst_vars_sed=$subst_vars_sed"
s&@$subst_var@&$subst_val_esc&g"
  done
  sed -e "$subst_vars_sed"
}

makeinstallersh() {
  EXTRACTFILES="$EXTRACTFILES $1"
  cameracompatibilityhack=$(cameracompatibilityhack)
  webviewcheckhack=$(webviewcheckhack)
  keyboardgooglenotremovehack=$(keyboardgooglenotremovehack)
  launcherhack=$(launcherhack)
  webviewignorehack=$(webviewignorehack)
  camerav3compatibilityhack=$(camerav3compatibilityhack)
  universalremoverhack=$(universalremoverhack)
  androidautohack=$(androidautohack)
  tvremotelibsymlink=''
  if [ "$API" -lt "24" ]; then # Only 5.1 and 6.0
    tvremotelibsymlink='# Create TVRemote lib symlink if installed
if ( contains "$gapps_list" "tvremote" ); then
  install -d "/system/app/AtvRemoteService/lib/$arch"
  ln -sfn "/system/$libfolder/$atvremote_lib_filename" "/system/app/AtvRemoteService/lib/$arch/$atvremote_lib_filename"
  # Add same code to backup script to ensure symlinks are recreated on addon.d restore
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/$libfolder/$atvremote_lib_filename\" \"\$SYS/app/AtvRemoteService/lib/$arch/$atvremote_lib_filename\"" $bkup_tail
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    install -d \"\$SYS/app/AtvRemoteService/lib/$arch\"" $bkup_tail
fi
'
  fi
  webviewlibsymlink=''
  if [ "$API" -lt "23" ]; then
    webviewlibsymlink='# Create WebView lib symlink if WebView was installed
if ( contains "$gapps_list" "webviewgoogle" ); then
  install -d "/system/app/WebViewGoogle/lib/$arch"
  ln -sfn "/system/$libfolder/$WebView_lib_filename" "/system/app/WebViewGoogle/lib/$arch/$WebView_lib_filename"
  # Add same code to backup script to ensure symlinks are recreated on addon.d restore
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"/system/$libfolder/$WebView_lib_filename\" \"/system/app/WebViewGoogle/lib/$arch/$WebView_lib_filename\"" $bkup_tail
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    install -d \"/system/app/WebViewGoogle/lib/$arch\"" $bkup_tail
  if [ -n "$fbarch" ]; then  # on 64bit we also need to add 32 bit libs
    install -d "/system/app/WebViewGoogle/lib/$fbarch"
    ln -sfn "/system/lib/$WebView_lib_filename" "/system/app/WebViewGoogle/lib/$fbarch/$WebView_lib_filename"
    # Add same code to backup script to ensure symlinks are recreated on addon.d restore
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/lib/$WebView_lib_filename\" \"/system/app/WebViewGoogle/lib/$fbarch/$WebView_lib_filename\"" $bkup_tail
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    install -d \"\$SYS/app/WebViewGoogle/lib/$fbarch\"" $bkup_tail
  fi
fi
'
  fi
  substitute_vars \
      API \
      ARCH \
      DATAINSTALLCODE \
      DATASIZESCODE \
      DATE \
      KEYBDINSTALLCODE \
      KEYBDLIBS \
      PLATFORM \
      PLATFORM \
      REMOVALBYPASS \
      REMOVALSUFFIX \
      REQDLIST \
      SUPPORTEDVARIANTS \
      VARIANT \
      cameracompatibilityhack \
      camerav3compatibilityhack \
      gappscore \
      gappsfull \
      gappsmicro \
      gappsmini \
      gappsnano \
      gappspico \
      gappsstock \
      gappssuper \
      gappscore_go \
      gappsfull_go \
      gappsmicro_go \
      gappsmini_go \
      gappsnano_go \
      gappspico_go \
      gappsstock_go \
      gappstvcore \
      gappstvmini \
      gappstvstock \
      keyboardgooglenotremovehack \
      launcherhack \
      stockremove \
      tvremotelibsymlink \
      universalremoverhack \
      webviewcheckhack \
      webviewignorehack \
      webviewlibsymlink \
      webviewstocklibs \
      androidautohack \
      <$SCRIPTS/templates/installer.sh >>"$build/$1"
}
