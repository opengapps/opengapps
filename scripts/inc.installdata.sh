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
makegprop(){
  echo "# begin addon properties
ro.addon.type=gapps
ro.addon.platform=$PLATFORM
ro.addon.open_type=$VARIANT
ro.addon.open_version=$DATE
# end addon properties" > "$build/g.prop"
  EXTRACTFILES="$EXTRACTFILES g.prop"
}
makegappsremovetxt(){
  gapps_remove=""
  get_supported_variants "stock"
  get_gapps_list "$supported_variants"
  for gapp in $gapps_list; do
    get_package_info "$gapp"
    if [ -n "$packagetarget" ]; then
      gapps_remove="/system/$packagetarget$REMOVALSUFFIX
$gapps_remove"
    fi
    for file in $packagefiles; do
      if [ "$file" = "etc" ];then
        gapps_remove="$(find "$SOURCES/all/" -mindepth 3 -printf "%P\n" -name "*" | grep "etc/" | sed 's#^#/system/#' | sort | uniq)
$gapps_remove"
      elif [ "$file" = "framework" ];then
        gapps_remove="$(find "$SOURCES/all/" -mindepth 2 -printf "%P\n" -name "*" | grep "framework/" | sed 's#^#/system/#' | sort | uniq)
$gapps_remove"
      else
        gapps_remove="/system/$file
$gapps_remove"
      fi
    done
  done
  printf "%s" "$gapps_remove" | sort > "$build/gapps-remove.txt"
  EXTRACTFILES="$EXTRACTFILES gapps-remove.txt"
}
makeinstallerdata(){
  echo '#This file is part of The Open GApps script of @mfonville.
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
# This Installation Data file for Open GApps Installer is derived from the PA GApps work of @TKruzze,
# PA GApps sources are used with permission, under the license that it may be re-used to continue the GApps package.
# This Installation Data file for Open GApps Installer includes code derived from the TK GApps of @TKruzze and @osm0sis,
# The TK GApps are available under the GPLv3 from http://forum.xda-developers.com/android/software/tk-gapps-t3116347
# Last Updated: '"$DATE"'
# _____________________________________________________________________________________________________________________
#                                             Define Current Package Variables
# List of GApps packages that can be installed with this installer
pkg_names="'"$SUPPORTEDVARIANTS"'";

# Installer Name (32 chars Total, excluding "")
installer_name="Open GApps '"$VARIANT"' '"$PLATFORM"' - ";

req_android_version="'"$PLATFORM"'";

'"$KEYBDLIBS"'
faceLock_lib_filename="libfacelock_jni.so";
WebView_lib_filename="libwebviewchromium.so";

# Buffer of extra system space to require for GApps install (9216=9MB)
# This will allow for some ROM size expansion when GApps are restored
buffer_size_kb=9216; small_buffer_size=2048;

# List of GApps files that should NOT be automatically removed as they are also included in (many) ROMs
removal_bypass_list="'"$REMOVALBYPASS"'
";

# Define exit codes (returned upon exit due to an error)
E_XZ=10; # No XZ support
E_TAR=11; # No TAR support
E_ROMVER=20; # Wrong ROM version
E_NOSPACE=70; # Insufficient Space Available in System Partition
E_NONOPEN=40; # NON-Open GApps Currently Installed
E_ARCH=64; # Wrong Architecture Detected
#_________________________________________________________________________________________________________________
#                                             GApps List (Applications user can Select/Deselect)
core_gapps_list="
'"$gappscore"'
";

stock_gapps_list="
'"$gappsstock"'
";

full_gapps_list="
'"$gappsfull"'
";

mini_gapps_list="
'"$gappsmini"'
";

micro_gapps_list="
'"$gappsmicro"'
";

nano_gapps_list="
'"$gappsnano"'
";

pico_gapps_list="
'"$gappspico"'
";
# _____________________________________________________________________________________________________________________
#                                             Default Stock/AOSP Removal List (Stock GApps Only)
default_aosp_remove_list="
'"$stockremove"'
";
# _____________________________________________________________________________________________________________________
#                                             Optional Stock/AOSP/ROM Removal List
optional_aosp_remove_list="
boxer
basicdreams
calendarstock
camerastock
clockstock
cmaudiofx
cmaccount
cmeleven
cmfilemanager
cmsetupwizard
cmupdater
cmwallpapers
dashclock
exchangestock
fmradio
galaxy
holospiral
keyboardstock
livewallpapers
lockclock
noisefield
phasebeam
photophase
phototable
simtoolkit
studio
sykopath
tagstock
terminal
themes
visualizationwallpapers
whisperpush
";
# _____________________________________________________________________________________________________________________
#                                             Stock/AOSP/ROM File Removal Lists
boxer_list="
vendor/bundled-app/Boxer'"$REMOVALSUFFIX"'
";

browser_list="
app/Browser'"$REMOVALSUFFIX"'
";

basicdreams_list="
app/BasicDreams'"$REMOVALSUFFIX"'
";

# Must be used when GoogleCalendar is installed
calendarstock_list="
app/Calendar'"$REMOVALSUFFIX"'
priv-app/Calendar'"$REMOVALSUFFIX"'
";

# Must be used when GoogleCamera is installed
camerastock_list="
app/Camera'"$REMOVALSUFFIX"'
app/Camera2'"$REMOVALSUFFIX"'
priv-app/Camera'"$REMOVALSUFFIX"'
priv-app/Camera2'"$REMOVALSUFFIX"'
app/MotCamera'"$REMOVALSUFFIX"'
priv-app/MotCamera'"$REMOVALSUFFIX"'
";

clockstock_list="
app/DeskClock'"$REMOVALSUFFIX"'
";

cmaccount_list="
priv-app/CMAccount'"$REMOVALSUFFIX"'
";

cmaudiofx_list="
priv-app/AudioFX'"$REMOVALSUFFIX"'
";

cmeleven_list="
app/Eleven'"$REMOVALSUFFIX"'
";

cmfilemanager_list="
app/CMFileManager'"$REMOVALSUFFIX"'
";

cmupdater_list="
priv-app/CMUpdater'"$REMOVALSUFFIX"'
";

cmsetupwizard_list="
app/CyanogenSetupWizard'"$REMOVALSUFFIX"'
";

cmwallpapers_list="
app/CMWallpapers'"$REMOVALSUFFIX"'
";

dashclock_list="
app/DashClock'"$REMOVALSUFFIX"'
";

email_list="
app/Email'"$REMOVALSUFFIX"'
app/PrebuiltEmailGoogle'"$REMOVALSUFFIX"'
";

exchangestock_list="
app/Exchange2'"$REMOVALSUFFIX"'
priv-app/Exchange2'"$REMOVALSUFFIX"'
";

fmradio_list="
app/FM2'"$REMOVALSUFFIX"'
app/FMRecord'"$REMOVALSUFFIX"'
";

galaxy_list="
app/Galaxy4'"$REMOVALSUFFIX"'
";

gallery_list="
app/Gallery'"$REMOVALSUFFIX"'
priv-app/Gallery'"$REMOVALSUFFIX"'
app/Gallery2'"$REMOVALSUFFIX"'
priv-app/Gallery2'"$REMOVALSUFFIX"'
app/MotGallery'"$REMOVALSUFFIX"'
priv-app/MotGallery'"$REMOVALSUFFIX"'
app/MediaShortcuts'"$REMOVALSUFFIX"'
priv-app/MediaShortcuts'"$REMOVALSUFFIX"'
";

holospiral_list="
app/HoloSpiralWallpaper'"$REMOVALSUFFIX"'
";

# Must be used when GoogleKeyboard is installed
keyboardstock_list="
app/LatinIME'"$REMOVALSUFFIX"'
";

launcher_list="
app/CMHome'"$REMOVALSUFFIX"'
app/CustomLauncher3'"$REMOVALSUFFIX"'
app/Launcher2'"$REMOVALSUFFIX"'
app/Launcher3'"$REMOVALSUFFIX"'
app/LiquidLauncher'"$REMOVALSUFFIX"'
app/Paclauncher'"$REMOVALSUFFIX"'
app/SlimLauncher'"$REMOVALSUFFIX"'
app/Trebuchet'"$REMOVALSUFFIX"'
priv-app/CMHome'"$REMOVALSUFFIX"'
priv-app/CustomLauncher3'"$REMOVALSUFFIX"'
priv-app/Launcher2'"$REMOVALSUFFIX"'
priv-app/Launcher3'"$REMOVALSUFFIX"'
priv-app/LiquidLauncher'"$REMOVALSUFFIX"'
priv-app/Paclauncher'"$REMOVALSUFFIX"'
priv-app/SlimLauncher'"$REMOVALSUFFIX"'
priv-app/Trebuchet'"$REMOVALSUFFIX"'
";

livewallpapers_list="
app/LiveWallpapers'"$REMOVALSUFFIX"'
";

lockclock_list="
app/LockClock'"$REMOVALSUFFIX"'
";

mms_list="
priv-app/Mms'"$REMOVALSUFFIX"'
";

noisefield_list="
app/NoiseField'"$REMOVALSUFFIX"'
";

phasebeam_list="
app/PhaseBeam'"$REMOVALSUFFIX"'
";

photophase_list="
app/PhotoPhase'"$REMOVALSUFFIX"'
";

phototable_list="
app/PhotoTable'"$REMOVALSUFFIX"'
";

picotts_list="
app/PicoTts'"$REMOVALSUFFIX"'
priv-app/PicoTts'"$REMOVALSUFFIX"'
lib/libttscompat.so
lib/libttspico.so
tts
";

simtoolkit_list="
app/Stk'"$REMOVALSUFFIX"'
";

studio_list="
app/VideoEditor'"$REMOVALSUFFIX"'
";

sykopath_list="
app/Layers'"$REMOVALSUFFIX"'
";

tagstock_list="
priv-app/Tag'"$REMOVALSUFFIX"'
";

terminal_list="
app/Terminal'"$REMOVALSUFFIX"'
";

themes_list="
priv-app/ThemeChooser'"$REMOVALSUFFIX"'
priv-app/ThemesProvider'"$REMOVALSUFFIX"'
";

visualizationwallpapers_list="
app/VisualizationWallpapers'"$REMOVALSUFFIX"'
";

webviewstock_list="
app/webview'"$REMOVALSUFFIX"'
app/WebView'"$REMOVALSUFFIX"'
lib/$WebView_lib_filename
lib64/$WebView_lib_filename
";

whisperpush_list="
app/WhisperPush'"$REMOVALSUFFIX"'
";
# _____________________________________________________________________________________________________________________
#                                             Permanently Removed Folders
# Pieces that may be left over from AIO ROMs that can/will interfere with these GApps
other_list="
/system/app/BrowserProviderProxy'"$REMOVALSUFFIX"'
/system/app/CalendarGoogle'"$REMOVALSUFFIX"'
/system/app/CloudPrint'"$REMOVALSUFFIX"'
/system/app/EditorsDocsStub'"$REMOVALSUFFIX"'
/system/app/EditorsSheetsStub'"$REMOVALSUFFIX"'
/system/app/EditorsSlidesStub'"$REMOVALSUFFIX"'
/system/app/Gmail'"$REMOVALSUFFIX"'
/system/app/Gmail2'"$REMOVALSUFFIX"'
/system/app/GoogleCalendar'"$REMOVALSUFFIX"'
/system/app/GoogleCloudPrint'"$REMOVALSUFFIX"'
/system/app/GoogleHangouts'"$REMOVALSUFFIX"'
/system/app/GoogleKeep'"$REMOVALSUFFIX"'
/system/app/GoogleLatinIme'"$REMOVALSUFFIX"'
/system/app/GooglePlus'"$REMOVALSUFFIX"'
/system/app/Keep'"$REMOVALSUFFIX"'
/system/app/NewsWeather'"$REMOVALSUFFIX"'
/system/app/PartnerBookmarksProvider'"$REMOVALSUFFIX"'
/system/app/QuickSearchBox'"$REMOVALSUFFIX"'
/system/app/Vending'"$REMOVALSUFFIX"'
/system/priv-app/GmsCore'"$REMOVALSUFFIX"'
/system/priv-app/GoogleNow'"$REMOVALSUFFIX"'
/system/priv-app/GoogleSearch'"$REMOVALSUFFIX"'
/system/priv-app/GoogleHangouts'"$REMOVALSUFFIX"'
/system/priv-app/OneTimeInitializer'"$REMOVALSUFFIX"'
/system/priv-app/Provision'"$REMOVALSUFFIX"'
/system/priv-app/QuickSearchBox'"$REMOVALSUFFIX"'
/system/priv-app/Vending'"$REMOVALSUFFIX"'
";

# Apps from app that need to be installed in priv-app
privapp_list="
/system/app/GoogleBackupTransport'"$REMOVALSUFFIX"'
/system/app/GoogleFeedback'"$REMOVALSUFFIX"'
/system/app/GoogleHome'"$REMOVALSUFFIX"'
/system/app/GoogleLoginService'"$REMOVALSUFFIX"'
/system/app/GoogleOneTimeInitializer'"$REMOVALSUFFIX"'
/system/app/GooglePartnerSetup'"$REMOVALSUFFIX"'
/system/app/GoogleServicesFramework'"$REMOVALSUFFIX"'
/system/app/Hangouts'"$REMOVALSUFFIX"'
/system/app/OneTimeInitializer'"$REMOVALSUFFIX"'
/system/app/Phonesky'"$REMOVALSUFFIX"'
/system/app/PrebuiltGmsCore'"$REMOVALSUFFIX"'
/system/app/SetupWizard'"$REMOVALSUFFIX"'
/system/app/Velvet'"$REMOVALSUFFIX"'
/system/app/Wallet'"$REMOVALSUFFIX"'
";

# Stock/AOSP Keyboard lib (and symlink) that are always removed since they are always replaced
reqd_list="
'"$REQDLIST"'";

# Remove talkback from priv-app since it was moved to app in 5.1
obsolete_list="
/system/priv-app/talkback'"$REMOVALSUFFIX"'
";

# Obsolete files from xxxx
#obsolete_list="${obsolete_list}
#";

# Old addon.d backup scripts as we will be replacing with updated version during install
oldscript_list="
/system/etc/g.prop
/system/addon.d/70-gapps.sh
";' >> "$build/installer.data"
  tee -a "$build/installer.data" > /dev/null <<'EOFILE'

remove_list="${other_list}${privapp_list}${reqd_list}${obsolete_list}${oldscript_list}";
# _____________________________________________________________________________________________________________________
#                                             Installer Error Messages
arch_compat_msg="INSTALLATION FAILURE: This Open GApps package cannot be installed on this\ndevice's architecture. Please download the correct version for your device.\n";
camera_sys_msg="WARNING: Google Camera has/will not be installed as requested. Google Camera\ncan only be installed during a Clean Install or as an update to an existing\nGApps Installation.\n";
camera_compat_msg="WARNING: Google Camera has/will not be installed as requested. Google Camera is\nNOT compatible with your device if installed in the system partition. Try\ninstalling from the Play Store instead.\n";
faceunlock_msg="NOTE: FaceUnlock can only be installed on devices with a front facing camera.\n";
googlenow_msg="WARNING: Google Now Launcher has/will not be installed as requested. Google \nSearch must be added to the GApps installation if you want to install the Google\nNow Launcher.\n";
keyboard_sys_msg="WARNING: Google Keyboard has/will not be installed as requested. Google Keyboard\ncan only be installed during a Clean Install or as an update to an existing\nGApps Installation.\n";
nokeyboard_msg="NOTE: The Stock/AOSP keyboard was NOT removed as requested to ensure your device\nwas not accidentally left with no keyboard installed. If this was intentional,\nyou can add 'Override' to your gapps-config to override this protection.\n";
nolauncher_msg="NOTE: The Stock/AOSP Launcher was NOT removed as requested to ensure your device\nwas not accidentally left with no Launcher. If this was your intention, you can\nadd 'Override' to your gapps-config to override this protection.\n";
nomms_msg="NOTE: The Stock/AOSP MMS app was NOT removed as requested to ensure your device\nwas not accidentally left with no way to receive text messages. If this WAS\nintentional, add 'Override' to your gapps-config to override this protection.\n";
nowebview_msg="NOTE: The Stock/AOSP WebView was NOT removed as requested to ensure your device\nwas not accidentally left with no WebView installed. If this was intentional,\nyou can add 'Override' to your gapps-config to override this protection.\n";
non_open_gapps_msg="INSTALLATION FAILURE: Open GApps can only be installed on top of an existing\nOpen GApps installation. Since you are currently using another GApps package, you\nwill need to wipe (format) your system partition before installing Open GApps.\n";
rom_version_msg="INSTALLATION FAILURE: This GApps package can only be installed on a $req_android_version.x ROM.\n";
simulation_msg="TEST INSTALL: This was only a simulated install. NO CHANGES WERE MADE TO YOUR\nDEVICE. To complete the installation remove 'Test' from your gapps-config.\n";
system_space_msg="INSTALLATION FAILURE: Your device does not have sufficient space available in\nthe system partition to install this GApps package as currently configured.\nYou will need to switch to a smaller GApps package or use gapps-config to\nreduce the installed size.\n";
user_multiplefound_msg="NOTE: All User Application Removals included in gapps-config were unable to be\nprocessed as requested because multiple versions of the app were found on your\ndevice. See the log portion below for the name(s) of the application(s).\n";
user_notfound_msg="NOTE: All User Application Removals included in gapps-config were unable to be\nremoved as requested because the files were not found on your device. See the\nlog portion below for the name(s) of the application(s).\n";
del_conflict_msg="!!! WARNING !!! - Duplicate files were found between your ROM and this GApps\npackage. This is likely due to your ROM's dev including Google proprietary\nfiles in the ROM. The duplicate files are shown in the log portion below.\n";
no_tar_message="INSTALLATION FAILURE: The installer detected that your recovery does not support\ntar extraction. Please update your recovery or switch to another one like TWRP."
no_xz_message="INSTALLATION FAILURE: The installer detected that your recovery does not support\nXZ decompression. Please update your recovery or switch to another one like TWRP."
EOFILE
  EXTRACTFILES="$EXTRACTFILES installer.data"
}
