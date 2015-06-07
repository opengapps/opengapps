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
# end addon properties" > "$build"g.prop
}
makegappsremovetxt(){
corepath="$BUILD/$ARCH/$API/Core/"
gappspath="$BUILD/$ARCH/$API/GApps/"
gmscorepath="$BUILD/$ARCH/$API/GMSCore/"
messengerpath="$BUILD/$ARCH/$API/Messenger/"
playgamespath="$BUILD/$ARCH/$API/PlayGames/"
find "$corepath" "$gappspath" "$gmscorepath" "$messengerpath" "$playgamespath" -mindepth 3 -maxdepth 3 -printf "%P\n" -name "*" | grep -v "etc/" | sed 's#^[^/]*#/system#' | sort | uniq > "$build"gapps-remove.txt
find "$corepath" "$gappspath" "$gmscorepath" "$messengerpath" "$playgamespath" -mindepth 4 -printf "%P\n" -name "*" | grep "etc/" | sed 's#^[^/]*#/system#' | sort | uniq >> "$build"gapps-remove.txt
}
makesizesprop(){
echo "books_size="`du -s --apparent-size "$build"GApps/books | cut -f 1` > "$build"sizes.prop
echo "calendargoogle_size="`du -s --apparent-size "$build"GApps/calendargoogle | cut -f 1` >> "$build"sizes.prop
echo "calsync_size="`du -s --apparent-size "$build"GApps/calsync | cut -f 1` >> "$build"sizes.prop
echo "cameragoogle_size="`du -s --apparent-size "$build"GApps/cameragoogle | cut -f 1` >> "$build"sizes.prop
echo "chrome_size="`du -s --apparent-size "$build"GApps/chrome | cut -f 1` >> "$build"sizes.prop
echo "cloudprint_size="`du -s --apparent-size "$build"GApps/cloudprint | cut -f 1` >> "$build"sizes.prop
echo "docs_size="`du -s --apparent-size "$build"GApps/docs | cut -f 1` >> "$build"sizes.prop
echo "drive_size="`du -s --apparent-size "$build"GApps/drive | cut -f 1` >> "$build"sizes.prop
echo "ears_size="`du -s --apparent-size "$build"GApps/ears | cut -f 1` >> "$build"sizes.prop
echo "earth_size="`du -s --apparent-size "$build"GApps/earth | cut -f 1` >> "$build"sizes.prop
echo "exchangegoogle_size="`du -s --apparent-size "$build"GApps/exchangegoogle | cut -f 1` >> "$build"sizes.prop
if [ "$API" -gt "19" ]; then
	echo "faceunlock_size="`du -s --apparent-size "$build"GApps/faceunlock | cut -f 1` >> "$build"sizes.prop
fi
echo "fitness_size="`du -s --apparent-size "$build"GApps/fitness | cut -f 1` >> "$build"sizes.prop
echo "gmail_size="`du -s --apparent-size "$build"GApps/gmail | cut -f 1` >> "$build"sizes.prop
echo "googlenow_size="`du -s --apparent-size "$build"GApps/googlenow | cut -f 1` >> "$build"sizes.prop
echo "googleplus_size="`du -s --apparent-size "$build"GApps/googleplus | cut -f 1` >> "$build"sizes.prop
echo "googletts_size="`du -s --apparent-size "$build"GApps/googletts | cut -f 1` >> "$build"sizes.prop
echo "hangouts_size="`du -s --apparent-size "$build"GApps/hangouts | cut -f 1` >> "$build"sizes.prop
echo "keep_size="`du -s --apparent-size "$build"GApps/keep | cut -f 1` >> "$build"sizes.prop
echo "keyboardgoogle_size="`du -s --apparent-size "$build"GApps/keyboardgoogle | cut -f 1` >> "$build"sizes.prop
echo "maps_size="`du -s --apparent-size "$build"GApps/maps | cut -f 1` >> "$build"sizes.prop
echo "movies_size="`du -s --apparent-size "$build"GApps/movies | cut -f 1` >> "$build"sizes.prop
echo "music_size="`du -s --apparent-size "$build"GApps/music | cut -f 1` >> "$build"sizes.prop
echo "newsstand_size="`du -s --apparent-size "$build"GApps/newsstand | cut -f 1` >> "$build"sizes.prop
echo "newswidget_size="`du -s --apparent-size "$build"GApps/newswidget | cut -f 1` >> "$build"sizes.prop
echo "photos_size="`du -s --apparent-size "$build"GApps/photos | cut -f 1` >> "$build"sizes.prop
echo "search_size="`du -s --apparent-size "$build"GApps/search | cut -f 1` >> "$build"sizes.prop
echo "sheets_size="`du -s --apparent-size "$build"GApps/sheets | cut -f 1` >> "$build"sizes.prop
echo "slides_size="`du -s --apparent-size "$build"GApps/slides | cut -f 1` >> "$build"sizes.prop
echo "speech_size="`du -s --apparent-size "$build"GApps/speech | cut -f 1` >> "$build"sizes.prop
echo "street_size="`du -s --apparent-size "$build"GApps/street | cut -f 1` >> "$build"sizes.prop
echo "talkback_size="`du -s --apparent-size "$build"GApps/talkback | cut -f 1` >> "$build"sizes.prop
echo "wallet_size="`du -s --apparent-size "$build"GApps/wallet | cut -f 1` >> "$build"sizes.prop
if [ "$API" -gt "19" ]; then
	echo "webview_size="`du -s --apparent-size "$build"GApps/webview | cut -f 1` >> "$build"sizes.prop
fi
echo "youtube_size="`du -s --apparent-size "$build"GApps/youtube | cut -f 1` >> "$build"sizes.prop
}
makeinstallerdata(){
if [ "$API" -le "19" ]; then
	REMOVALSUFFIX=".apk"
	REMOVALBYPASS="
/system/lib/libjni_eglfence.so		
/system/lib/libjni_filtershow_filters.so		
/system/lib/libjni_latinime.so		
/system/lib/libjni_tinyplanet.so		
/system/lib/libjpeg.so		
/system/lib/libWVphoneAPI.so		
/system/priv-app/CalendarProvider.apk"
else
	REMOVALSUFFIX=""
	REMOVALBYPASS=""
fi


echo "#This file is part of The Open GApps script of @mfonville.
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
# This Installation Data file for Open GApps Installer is derived from the work of @TKruzze,
# TKruzze's original work is used with permission, under the license that it may be re-used to continue the GApps package.
# This Installation Data file for Open GApps Installer includes code derived from the TK GApps of @TKruzze and @osm0sis,
# The TK GApps are available under the GPLv3 from http://forum.xda-developers.com/android/software/tk-gapps-t3116347
# Last Updated: "$DATE > "$build"installer.data
echo '# _____________________________________________________________________________________________________________________
#                                             Define Current Package Variables
# List of GApps packages that can be installed with this installer
pkg_names="'"`printf "$SUPPORTEDVARIANTS " | tac -s' ' -`"'";

# Installer Name (32 chars Total, excluding "")
installer_name="Open GApps '"$VARIANT"' '"$PLATFORM"' - ";

req_android_version="'"$PLATFORM"'";
keybd_lib_filename1="libjni_latinimegoogle.so";
keybd_lib_filename2="libjni_latinime.so";
FaceLock_lib_filename="libfacelock_jni.so";

# Google Play Services version sizes' >> "$build"installer.data
gmscommon=`du -s "$build"GMSCore/common | cut -f 1`
for t in $GMSCore; do
	gmst=`du -s "$build"GMSCore/$t | cut -f 1`
	printf "gms_"$t"_size="`expr $gmst + $gmscommon`"; " >> "$build"installer.data
done

echo "\n\n# Google Messenger version sizes" >> "$build"installer.data
msgcommon=`du -s "$build"Messenger/common | cut -f 1`
for t in $Messenger; do
	msgt=`du -s "$build"Messenger/$t | cut -f 1`
	printf "msg_"$t"_size="`expr $msgt + $msgcommon`"; " >> "$build"installer.data
done

echo "\n\n# Google Play Games version sizes" >> "$build"installer.data
pgcommon=`du -s "$build"PlayGames/common | cut -f 1`
for t in $PlayGames; do
	pgt=`du -s "$build"PlayGames/$t | cut -f 1`
	printf "pg_"$t"_size="`expr $pgt + $pgcommon`"; " >> "$build"installer.data
done

echo "\n\n# Core & Optional Apps size" >> "$build"installer.data
core=`du -s "$build"Core | cut -f 1`
keybdlib=`du -s "$build"Optional/keybd_lib | cut -f 1`
echo "core_size="$core"; keybd_lib_size="$keybdlib";">> "$build"installer.data

#The part below still has to be made more dynamic, like the 'stock' type
#We can include again the gms_base type
#We whould replace 'arm' with the $ARCH type
echo '

# Buffer of extra system space to require for GApps install (9216=9MB)
# This will allow for some ROM size expansion when GApps are restored
buffer_size_kb=9216; small_buffer_size=2048;

# List of GApps files that should NOT be automatically removed as they are also included in (many) ROMs
removal_bypass_list="'"$REMOVALBYPASS"'
";

# Define exit codes (returned upon exit due to an error)
E_ROMVER=20; # Wrong ROM version
E_NOSPACE=70; # Insufficient Space Available in System Partition
E_NONOPEN=40; # NON-Open GApps Currently Installed
E_64BIT=64 ; # 64-bit Device Detected
#_________________________________________________________________________________________________________________
#                                             GApps List (Applications user can Select/Deselect)
# calsync will be added to GApps Install List as needed during script execution' >> "$build"installer.data

echo 'stock_gapps_list="
'"$STOCK"'
";

full_gapps_list="
'"$FULL"'
";

mini_gapps_list="
'"$MINI"'
";

micro_gapps_list="
'"$MICRO"'
";

nano_gapps_list="
'"$NANO"'
";

pico_gapps_list="
'"$PICO"'
";' >> "$build"installer.data
echo '# _____________________________________________________________________________________________________________________
#                                             Default Stock/AOSP Removal List (Stock GApps Only)
default_aosp_remove_list="
'"$STOCKREMOVE"'
";' >> "$build"installer.data
echo '# _____________________________________________________________________________________________________________________
#                                             Optional Stock/AOSP/ROM Removal List
optional_aosp_remove_list="
basicdreams
calendarstock
camerastock
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
terminal
themes
simtoolkit
studio
sykopath
visualizationwallpapers
whisperpush
";
# _____________________________________________________________________________________________________________________
#                                             Stock/AOSP/ROM File Removal Lists
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

#Hidden, is not one of the normal options, but used in the script
webviewstock_list="
app/webview'"$REMOVALSUFFIX"'
priv-app/webview'"$REMOVALSUFFIX"'
";

whisperpush_list="
app/WhisperPush'"$REMOVALSUFFIX"'
";' >> "$build"installer.data
echo '# _____________________________________________________________________________________________________________________
#                                             Permanently Removed Folders
# Pieces that may be left over from AIO ROMs that can/will interfere with these GApps
other_list="
/system/app/BrowserProviderProxy'"$REMOVALSUFFIX"'
/system/app/Gmail'"$REMOVALSUFFIX"'
/system/app/GoogleCalendar'"$REMOVALSUFFIX"'
/system/app/GoogleCloudPrint'"$REMOVALSUFFIX"'
/system/app/GoogleHangouts'"$REMOVALSUFFIX"'
/system/app/GoogleKeep'"$REMOVALSUFFIX"'
/system/app/GoogleLatinIme'"$REMOVALSUFFIX"'
/system/app/GooglePlus'"$REMOVALSUFFIX"'
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
/system/app/Phonesky'"$REMOVALSUFFIX"'
/system/app/PrebuiltGmsCore'"$REMOVALSUFFIX"'
/system/app/SetupWizard'"$REMOVALSUFFIX"'
/system/app/Velvet'"$REMOVALSUFFIX"'
/system/app/Wallet'"$REMOVALSUFFIX"'
";

# Stock/AOSP Keyboard lib (and symlink) that are always removed since they are always replaced 
reqd_list="
/system/lib/libjni_latinime.so
/system/lib/libjni_latinimegoogle.so
/system/app/LatinIME/lib/arm/libjni_latinime.so
/system/app/LatinIME/lib/arm/libjni_latinimegoogle.so
";

# Remove talkback from priv-app since it was moved to app in 5.1
obsolete_list="
/system/priv-app/talkback
";

# Obsolete files from xxxx
#obsolete_list="${obsolete_list}
#";

# Old addon.d backup scripts as we will be replacing with updated version during install
oldscript_list="
/system/etc/g.prop
/system/addon.d/70-gapps.sh
";' >> "$build"installer.data
tee -a "$build"installer.data > /dev/null <<'EOFILE'

remove_list="${other_list}${privapp_list}${reqd_list}${obsolete_list}${oldscript_list}";
# _____________________________________________________________________________________________________________________
#                                             Installer Error Messages
64bit_compat_msg="INSTALLATION FAILURE: Open GApps are not compatible with 64-bit devices. You will\nneed to find a 64-bit compatible GApps package that will work with your device.\n";
camera_sys_msg="WARNING: Google Camera has/will not be installed as requested. Google Camera\ncan only be installed during a Clean Install or as an update to an existing\nGApps Installation.\n";
camera_compat_msg="WARNING: Google Camera has/will not be installed as requested. Google Camera is\nNOT compatible with your device if installed in the system partition. Try\ninstalling from the Play Store instead.\n";
faceunlock_msg="NOTE: FaceUnlock can only be installed on devices with a front facing camera.\n";
googlenow_msg="WARNING: Google Now Launcher has/will not be installed as requested. Google \nSearch must be added to the GApps installation if you want to install the Google\nNow Launcher.\n";
keyboard_sys_msg="WARNING: Google Keyboard has/will not be installed as requested. Google Keyboard\ncan only be installed during a Clean Install or as an update to an existing\nGApps Installation.\n";
webview_compat_msg="WARNING: Google Webview has/will not be installed as requested. Google Webview\nis NOT compatible with your ROM when installed.\n";
nokeyboard_msg="NOTE: The Stock/AOSP keyboard was NOT removed as requested to ensure your device\nwas not accidentally left with no keyboard installed. If this was intentional,\nyou can add 'Override' to your gapps-config to override this protection.\n";
nolauncher_msg="NOTE: The Stock/AOSP Launcher was NOT removed as requested to ensure your device\nwas not accidentally left with no Launcher. If this was your intention, you can\nadd 'Override' to your gapps-config to override this protection.\n";
nomms_msg="NOTE: The Stock/AOSP MMS app was NOT removed as requested to ensure your device\nwas not accidentally left with no way to receive text messages. If this WAS\nintentional, add 'Override' to your gapps-config to override this protection.\n";
non_open_gapps_msg="INSTALLATION FAILURE: Open GApps can only be installed on top of an existing\nOpen GApps installation. Since you are currently using another GApps package, you\nwill need to wipe (format) your system partition before installing Open GApps.\n";
rom_version_msg="INSTALLATION FAILURE: This GApps package can only be installed on a $req_android_version.x ROM.\n";
simulation_msg="TEST INSTALL: This was only a simulated install. NO CHANGES WERE MADE TO YOUR\nDEVICE. To complete the installation remove 'Test' from your gapps-config.\n";
system_space_msg="INSTALLATION FAILURE: Your device does not have sufficient space available in\nthe system partition to install this GApps package as currently configured.\nYou will need to switch to a smaller GApps package or use gapps-config to\nreduce the installed size.\n";
user_multiplefound_msg="NOTE: All User Application Removals included in gapps-config were unable to be\nprocessed as requested because multiple versions of the app were found on your\ndevice. See the log portion below for the name(s) of the application(s).\n";
user_notfound_msg="NOTE: All User Application Removals included in gapps-config were unable to be\nremoved as requested because the files were not found on your device. See the\nlog portion below for the name(s) of the application(s).\n";
del_conflict_msg="!!! WARNING !!! - Duplicate files were found between your ROM and this GApps\npackage. This is likely due to your ROM's dev including Google proprietary\nfiles in the ROM. The duplicate files are shown in the log portion below.\n";
EOFILE
}

makeupdatebinary(){
tee "$build"META-INF/com/google/android/update-binary > /dev/null <<'EOFILE'
#!/sbin/sh
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
# This Open GApps Shell Script Installer file for Open GApps Installer is derived from the work of @TKruzze and @osm0sis,
# Their original work is used with permission, under the license that it may be re-used to continue the GApps package.
# This Open GApps Shell Script Installer includes code derived from the TK GApps of @TKruzze and @osm0sis,
# The TK GApps are available under the GPLv3 from http://forum.xda-developers.com/android/software/tk-gapps-t3116347
#
unzip -o "$3" installer.data sizes.prop g.prop gapps-remove.txt bkup_tail.sh -d /tmp;
. /tmp/installer.data;
. /tmp/sizes.prop;
# _____________________________________________________________________________________________________________________
#                                                  Declare Variables
ZIP="$3";
zip_folder="$(dirname "$ZIP")";
OUTFD=/proc/self/fd/$2;

g_prop=/system/etc/g.prop;
b_prop=/system/build.prop;
bkup_tail=/tmp/bkup_tail.sh;
gapps_removal_list=/tmp/gapps-remove.txt
g_log=/tmp/g.log;
calc_log=/tmp/calc.log;
conflicts_log=/tmp/conflicts.log;
rec_cache_log=/cache/recovery/log;
rec_tmp_log=/tmp/recovery.log;
user_remove_notfound_log=/tmp/user_remove_notfound.log;
user_remove_multiplefound_log=/tmp/user_remove_multiplefound.log;

log_close="# End Open GApps Install Log\n";

reclaimed_gapps_space_kb=0;
reclaimed_removal_space_kb=0;
reclaimed_aosp_space_kb=0;
total_install_size_kb=0;
# _____________________________________________________________________________________________________________________
#                                                  Define Functions
abort() {
    quit;
    ui_print "- NO changes were made to your device";
    ui_print " ";
    ui_print "Installer will now exit...";
    ui_print " ";
    ui_print "Error Code: $1";
    sleep 5;
    exxit $1;
}

ch_con() {
  LD_LIBRARY_PATH=/system/lib /system/toolbox chcon u:object_r:system_file:s0 $1;
  LD_LIBRARY_PATH=/system/lib /system/bin/toolbox chcon u:object_r:system_file:s0 $1;
  chcon u:object_r:system_file:s0 $1;
}

ch_con_recursive() {
    dirs=$(echo $* | awk '{ print substr($0, index($0,$1)) }');
    for i in $dirs; do
        find "$i" -exec LD_LIBRARY_PATH=/system/lib /system/toolbox chcon u:object_r:system_file:s0 {} +;
        find "$i" -exec LD_LIBRARY_PATH=/system/lib /system/bin/toolbox chcon u:object_r:system_file:s0 {} +;
        find "$i" -exec chcon u:object_r:system_file:s0 {} +;
    done;
}

complete_gapps_list() {
cat <<EOF
$full_removal_list
EOF
}

contains() {
    case "$1" in
        *"$2"* ) return 0;;
        * ) return 1;;
    esac;
}

clean_inst() {
    if [ -f /data/system/packages.xml ]; then
        return 1;
    fi;
    return 0;
}

exxit() {
    set_progress 0.98;
    if ( ! grep -qi "nodebug" "$g_conf" ); then
        if [ "$g_conf" ]; then # copy gapps-config files to debug logs folder
            cp -f "$g_conf_orig" /tmp/logs/gapps-config_original.txt;
            cp -f "$g_conf" /tmp/logs/gapps-config_processed.txt;
        fi;
        ls -alZR /system > /tmp/logs/System_Files_After.txt;
        df -k > /tmp/logs/Device_Space_After.txt;
        cp -f "$log_folder/open_gapps_log.txt" /tmp/logs;
        cp -f $b_prop /tmp/logs;
        cp -f /system/addon.d/70-gapps.sh /tmp/logs;
        cp -f $gapps_removal_list "/tmp/logs/gapps-remove_revised.txt";
        cp -f $rec_cache_log /tmp/logs/Recovery_cache.log;
        cp -f $rec_tmp_log /tmp/logs/Recovery_tmp.log;
        cd /tmp/logs;
        tar -cz -f "$log_folder/open_gapps_debug_logs.tar.gz" *;
        cd /;
    fi;
    rm -rf /tmp/*;
    set_progress 1.0;
    ui_print "- Unmounting /system, /data, /cache";
    ui_print " ";
    umount /system;
    umount /data;
    umount /cache;
    exit $1;
}

file_getprop() {
    grep "^$2" "$1" | cut -d= -f2;
}

folder_extract() {
    unzip -o "$ZIP" "$1/$2/*" -d /tmp;
    bkup_list=$'\n'"$(find /tmp/$1/$2 -type f | cut -d/ -f5-)${bkup_list}";
    cp -rf "/tmp/$1/$2/." /system/;
    rm -rf "/tmp/$1";
}

log() {
    printf "%30s | %s\n" "$1" "$2" >> $g_log;
}

log_add() {
    printf "%7s | %25s | + %7d | %7d\n" "$1" "$2" "$3" "$4">> $calc_log;
}

log_sub() {
    printf "%7s | %25s | - %7d | %7d\n" "$1" "$2" "$3" "$4">> $calc_log;
}

obsolete_gapps_list() {
cat <<EOF
$remove_list
EOF
}

quit() {
    set_progress 0.94;
    install_note=$(echo "${install_note}" | sort -r | sed '/^$/d'); # sort Installation Notes & remove empty lines
    echo -------------------------------------------------------------------------------- >> $g_log;
    echo -e "$log_close" >> $g_log;

    # Add Installation Notes to log to help user better understand conflicts/errors
    for note in $install_note; do
        eval "error_msg=\$${note}";
        echo -e "$error_msg" >> $g_log;
    done;

    # Add User App Removals NotFound Log if it exists
    if [ -r $user_remove_notfound_log ]; then
        echo -e "$user_notfound_msg" >> $g_log;
        echo "# Begin User App Removals NOT Found (from gapps-config)" >> $g_log;
        cat $user_remove_notfound_log >> $g_log;
        rm -f $user_remove_notfound_log;
        echo -e "# End User App Removals NOT Found (from gapps-config)\n" >> $g_log;
    fi;
    # Add User App Removals MultipleFound Log if it exists
    if [ -r $user_remove_multiplefound_log ]; then
        echo -e "$user_multiplefound_msg" >> $g_log;
        echo "# Begin User App Removals MULTIPLE Found (from gapps-config)" >> $g_log;
        cat $user_remove_multiplefound_log >> $g_log;
        rm -f $user_remove_multiplefound_log;
        echo -e "# End User App Removals MULTIPLE Found (from gapps-config)\n" >> $g_log;
    fi;

    # Add Duplicate Files Log if it exists
    if [ -r $conflicts_log ]; then
        echo -e "$del_conflict_msg" >> $g_log;
        echo "# Begin GApps <> ROM Duplicate File List" >> $g_log;
        cat $conflicts_log >> $g_log;
        rm -f $conflicts_log;
        echo -e "# End GApps <> ROM Duplicate File List\n" >> $g_log;
    fi;

    # Add Installation Calculations to the log if they were performed
    if [ -r $calc_log ]; then
        echo "# Begin GApps Size Calculations" >> $g_log;
        cat $calc_log >> $g_log;
        rm -f $calc_log;
        echo -e "\n# End GApps Size Calculations" >> $g_log;
    fi;

    # Add list of Raw User Application Removals back to end of processed gapps-config for display in gapps log
    if [ -n "$user_remove_list" ]; then
        for user_remove_app_raw in $user_remove_list; do
            echo "(${user_remove_app_raw})" >> $g_conf;
        done;
    fi;

    set_progress 0.96;
    # Add gapps-config information to the log
    echo -e "\n# Begin User's gapps-config" >> $g_log;
    if [ "$g_conf" ]; then
        cat "$g_conf" >> $g_log;
    else
        echo -n "   *** NOT USED ***" >> $g_log;
    fi;
    echo -e "\n# End User's gapps-config" >> $g_log;

    # Copy logs to proper folder (Same as gapps-config or same as Zip)
    ui_print "- Copying Log to $log_folder";
    ui_print " ";
    cp -f $g_log "$log_folder/open_gapps_log.txt";
    rm -f $g_log;
    set_progress 0.97;
}

set_perm() {
  chown $1.$2 $4;
  chown $1:$2 $4;
  chmod $3 $4;
}

set_perm_recursive() {
    dirs=$(echo $* | awk '{ print substr($0, index($0,$5)) }');
    for i in $dirs; do
        chown -R $1.$2 $i; chown -R $1:$2 $i;
        find "$i" -type d -exec chmod $3 {} +;
        find "$i" -type f -exec chmod $4 {} +;
    done;
}

set_progress() { echo "set_progress $1" > $OUTFD; }

sys_app() {
    if ( grep -q "codePath=\"/system/app/$1" /data/system/packages.xml ); then
        return 0;
    fi;
    return 1;
}

ui_print() {
    echo -ne "ui_print $1\n" > $OUTFD;
    echo -ne "ui_print\n" > $OUTFD;
}
# _____________________________________________________________________________________________________________________
#                                                  Gather Pre-Install Info
# Get GApps Version and GApps Type from g.prop extracted at top of script
gapps_version=$(file_getprop /tmp/g.prop ro.addon.open_version);
gapps_type=$(file_getprop /tmp/g.prop ro.addon.open_type);
# _____________________________________________________________________________________________________________________
#                                                  Begin GApps Installation
ui_print " ";
ui_print "################################################";
ui_print "  ____                  ________               ";
ui_print " / __ \___  ___ ___    / ___/ _ | ___  ___  ___";
ui_print "/ /_/ / _ \/ -_) _ \  / (_ / __ |/ _ \/ _ \(_-<";
ui_print "\____/ .__/\__/_//_/  \___/_/ |_/ .__/ .__/___/";
ui_print "    /_/                        /_/  /_/        ";
ui_print "################################################";
ui_print " ";
ui_print "$installer_name$gapps_version";
ui_print " ";
ui_print "- Mounting /system, /data, /cache";
ui_print " ";
set_progress 0.01;
busybox mount /system;
busybox mount /data;
busybox mount /cache;
busybox mount -o rw,remount /system;
# _____________________________________________________________________________________________________________________
#                                                  Gather Device & GApps Package Information
# Locate gapps-config (if used)
for i in "/tmp/aroma/.gapps-config" "$zip_folder/.gapps-config" "$zip_folder/gapps-config.txt" /sdcard/Open-GApps/.gapps-config /sdcard/Open-GApps/gapps-config.txt "$zip_folder/.gapps-config.txt" /sdcard/Open-GApps/.gapps-config.txt; do
    if [ -r "$i" ]; then
        g_conf="$i";
        break;
    fi;
done;
if [ "$g_conf" ]; then
    config_file="$g_conf";
    log_folder="$(dirname "$g_conf")";
    g_conf_orig=$g_conf;
    # Create processed gapps-config with user comments stripped and user app removals removed and stored in variable for processing later
    g_conf=/tmp/proc_gconf;
    sed -e 's|#.*||g' -e 's/\r//g' -e '/^$/d'  "$g_conf_orig" > $g_conf; # Strip user comments from gapps-config
    user_remove_list=`awk -F "[()]" '{ for (i=2; i<NF; i+=2) print $i }' $g_conf`; # Get users list of apk's to remove from gapps-config
    sed -i s/'([^)]*)'/''/g $g_conf; # Remove all instances of user app removals (stuff between parentheses)
    sed -i '/^$/d' $g_conf; # Remove all empty lines for cleaner appearance
else
    config_file="Not Used";
    log_folder="$zip_folder";
fi;

# Unless this is a NoDebug install - create folder and take 'Before' snapshots
if ( ! grep -qi "nodebug" "$g_conf" ); then
    mkdir /tmp/logs;
    ls -alZR /system > /tmp/logs/System_Files_Before.txt;
    df -k > /tmp/logs/Device_Space_Before.txt;
fi;

# Get ROM android version from build.prop
ui_print "- Gathering device & ROM information";
ui_print " ";
rom_android_version=$(file_getprop $b_prop ro.build.version.release);

# Get device name any which way we can
for field in ro.product.device ro.build.product; do
    for file in $b_prop /default.prop; do
        device_name=$(file_getprop $file $field);
        if [ ${#device_name} -ge 2 ]; then
            break 2;
        fi;
    done;
    device_name="Bad ROM/Recovery";
done;

# Get Device Type (phone or tablet) from build.prop
if echo "$(file_getprop $b_prop ro.build.characteristics)" | grep -qi "tablet"; then
    device_type=tablet;
else
    device_type=phone;
fi;

# Get Rom Version from build.prop
for field in ro.modversion ro.build.version.incremental; do
    rom_version=$(file_getprop $b_prop $field);
    if [ ${#rom_version} -ge 2 ]; then
        break;
    fi;
    rom_version="non-standard build.prop";
done;

echo "# Begin Open GApps Install Log" > $g_log;
echo -------------------------------------------------------------------------------- >> $g_log;
log "ROM Android Version" $rom_android_version;

# Check to make certain user has proper version ROM Installed
if [ ! ${rom_android_version:0:3} == $req_android_version ]; then
    ui_print "*** Incompatible Android ROM detected ***";
    ui_print " ";
    ui_print "This GApps pkg is for Android $req_android_version.x ONLY";
    ui_print " ";
    ui_print "******* GApps Installation failed *******";
    ui_print " ";
    install_note="${install_note}rom_version_msg"$'\n'; # make note that ROM Version is not compatible with these GApps
    abort $E_ROMVER;
fi;

# Check to make certain that user is not using a 64-bit device
if echo "$(file_getprop $b_prop ro.product.cpu.abilist64)" | grep -qi "arm64"; then
    ui_print "***** Incompatible Device Detected *****";
    ui_print " ";
    ui_print "Open GApps can ONLY be installed on 32-bit";
    ui_print "devices. Your device has been detected";
    ui_print "as a 64-bit device. You will need to";
    ui_print "find a 64-bit compatible GApps package.";
    ui_print " ";
    ui_print "******* GApps Installation failed *******";
    ui_print " ";
    install_note="${install_note}64bit_compat_msg"$'\n'; # make note that Open GApps are not 64-bit compatible
    abort $E_64BIT;
fi;

# Determine Recovery Type and Version
for rec_log in $rec_tmp_log $rec_cache_log; do
    recovery=$(busybox grep -m 2 -E " Recovery v|Starting TWRP|Welcome to|PhilZ" $rec_log);
    case "$recovery" in
        *Welcome*) recovery="$(grep -m 1 "Welcome to" $rec_log | awk '{ print substr($0, index($0,$3)) }')$(grep -m 1 "^ext.version" $rec_log | cut -d\" -f2)"; break;;
        *Recovery*) recovery=$(grep -m 1 "Recovery v" $rec_log); recovery=${recovery/Recovery v/Recovery }; break;;
        *PhilZ*) recovery=$(grep -m 2 -E "PhilZ|ClockworkMod" $rec_log); recovery="${recovery/ClockworkMod v/(ClockworkMod })"; break;;
        Starting*) recovery=$(echo $recovery | awk -F"Starting " '{ print $2 }' | awk -F" on " '{ print $1 }'); break;;
    esac;
done;

# Get display density using getprop from Recovery
density=$(getprop ro.sf.lcd_density);

# If the density returned by getprop is empty or non-standard - read from default.prop instead
case $density in
    160|240|320|480|560) ;;
    *) density=$(file_getprop /default.prop ro.sf.lcd_density);;
esac;

# If the density from default.prop is still empty or non-standard - read from build.prop instead
case $density in
    160|240|320|480|560) ;;
    *) density=$(file_getprop $b_prop ro.sf.lcd_density);;
esac;

case $density in
EOFILE
for d in $DENSITIES; do
	if [ $d -lt 8 ]
	then
		x=80
	else
		x=160 #resolution 8 for 480 is weird
	fi
	printf "    "`expr 40 \* $d + $x`") ">> "$build"META-INF/com/google/android/update-binary
	echo "$GMSCore" | grep -q "$d"
	if [ $? -eq 0 ]
	then
		echo "gms=$d">> "$build"META-INF/com/google/android/update-binary
	else
		echo "gms=0">> "$build"META-INF/com/google/android/update-binary
	fi
	echo "$Messenger" | grep -q "$d"
	if [ $? -eq 0 ]
	then
		echo "         msg=$d">> "$build"META-INF/com/google/android/update-binary
	else
		echo "         msg=0">> "$build"META-INF/com/google/android/update-binary
	fi
	echo "$PlayGames" | grep -q "$d"
	if [ $? -eq 0 ]
	then
		echo "         pg=$d;;">> "$build"META-INF/com/google/android/update-binary
	else
		echo "         pg=0;;">> "$build"META-INF/com/google/android/update-binary
	fi
done

tee -a "$build"META-INF/com/google/android/update-binary > /dev/null <<'EOFILE'
      *) gms=0
         msg=0
         pg=0;;
esac;

# Set density to unknown if it's still empty
test -z $density && density=unknown;

# Remove any files from gapps-list.txt that should not be processed for automatic removal
for bypass_file in $removal_bypass_list; do
    sed -i "\:${bypass_file}:d" $gapps_removal_list;
done;

# Is this a 'Clean' or 'Dirty' install
if ( clean_inst ); then
    install_type="Clean[Data Wiped]";
    cameragoogle_inst=Clean;
    keyboardgoogle_inst=Clean;
else
    install_type="Dirty[Data NOT Wiped]";

    # Was Google Camera previously installed (in /system)
    if ( sys_app GoogleCamera ); then
        cameragoogle_inst=true;
    else
        cameragoogle_inst=false;
    fi;

    # Was Google Keyboard previously installed (in /system)
    if ( sys_app LatinImeGoogle ); then
        keyboardgoogle_inst=true;
    else
        keyboardgoogle_inst=false;
    fi;
fi;

# Is device FaceUnlock compatible
if ( ! grep -qE "Victory|herring|sun4i" /proc/cpuinfo ) && [ -e /system/etc/permissions/android.hardware.camera.front.xml ]; then
    faceunlock_compat=true;
else
    faceunlock_compat=false;
fi;

# Check device name for devices that are incompatible with Google Camera
# bacon or A0001=OnePlus One | find7=Oppo Find7 and Find7a
case $device_name in
    A0001|bacon|find7) cameragoogle_compat=false;;
    *) cameragoogle_compat=true;;
esac;

# Hackish code, checks if ROM is CM12.1 from 23th of May or newer, that supports Google Webview, otherwise does not allow the install
romversion=`echo $(file_getprop $b_prop ro.cm.version) | tr "-" " " | tr -d "."`
cmversion=`echo "$rocmversion" | awk '{print $1;}'`
cmdate=`echo "$rocmversion" | awk '{print $2;}'`
if [ "0$cmversion" -ge "121" ] && [ "0$cmdate" -ge "20150523" ]; then
    webviewgoogle_compat=true
else
    webviewgoogle_compat=false
fi

log "ROM ID" "$(file_getprop $b_prop ro.build.display.id)";
log "ROM Version" "$rom_version";
log "Device Recovery" "$recovery";
log "Device Name" "$device_name";
log "Device Model" "$(file_getprop $b_prop ro.product.model)";
log "Device Type" "$device_type";
log "Device CPU" "$(file_getprop $b_prop ro.product.cpu.abilist32)";
log "getprop Density" "$(getprop ro.sf.lcd_density)";
log "default.prop Density" "$(file_getprop /default.prop ro.sf.lcd_density)";
log "build.prop Density" "$(file_getprop $b_prop ro.sf.lcd_density)";
log "Display Density Used" "${density}ppi";
log "Install Type" "$install_type";
log "Google Camera Installed¹" "$cameragoogle_inst";
log "Google Keyboard Installed¹" "$keyboardgoogle_inst";
log "FaceUnlock Compatible" "$faceunlock_compat";
log "Google Camera Compatible" "$cameragoogle_compat";
log "Google Webview Compatible" "$webviewgoogle_compat";
log_close="                  ¹ Previously installed with Open GApps\n$log_close";

# Determine if a GApps package is installed and
# the version, type, and whether it's a Open GApps package
if [ -e /system/priv-app/GoogleServicesFramework/GoogleServicesFramework.apk -a -e /system/priv-app/GoogleLoginService/GoogleLoginService.apk ]; then
    if [ -n "$(grep -e ro.addon.open_version -e ro.addon.pa_version $g_prop)" ]; then
        log "Current GApps Version" "$(file_getprop $g_prop ro.addon.open_version)";
        if [ -n "$(grep ro.addon.open_type $g_prop)" ]; then
            log "Current Open GApps Package" "$(file_getprop $g_prop ro.addon.open_type)";
        else
            log "Current Open GApps Package" "Unknown";
        fi;
    else
        log "Current GApps Version" "NON Open GApps Currently Installed (FAILURE)";
        ui_print "* Incompatible GApps Currently Installed *";
        ui_print " ";
        ui_print "Open GApps can ONLY be installed on top of";
        ui_print "an existing installation of Open GApps. You";
        ui_print "must wipe (format) your system partition";
        ui_print "BEFORE installing any Open GApps package.";
        ui_print " ";
        ui_print "******* GApps Installation failed *******";
        ui_print " ";
        install_note="${install_note}non_open_gapps_msg"$'\n'; # make note that currently installed GApps are non-Open
        abort $E_NONOPEN;
    fi;
else
    # User does NOT have a GApps package installed on their device
    log "Current GApps Version" "NO GApps Installed";
    log "Current Open GApps Package" "NO GApps Installed";

    # Use the opportunity of No GApps installed to check for potential ROM conflicts when deleting existing GApps files
    while read gapps_file; do
        if [ -e $gapps_file ]; then
            echo $gapps_file >> $conflicts_log;
        fi;
    done < $gapps_removal_list;
fi;
# _____________________________________________________________________________________________________________________
#                                                  Prepare the list of GApps being installed and AOSP/Stock apps being removed
# Build list of available GApps that can be installed (and check for a user package preset)
for pkg in $pkg_names; do
    eval "addto=\$${pkg}_gapps_list"; # Look for method to combine this with line below
    all_gapps_list=${all_gapps_list}${addto}; # Look for method to combine this with line above
    if ( grep -qi "${pkg}gapps" "$g_conf" ); then # user has selected a 'preset' install
        gapps_type=$pkg;
        sed -i "/ro.addon.open_type/c\ro.addon.open_type=$pkg" /tmp/g.prop; # modify g.prop to new package type
        break;
    fi;
done;

# Prepare list of User specified GApps that will be installed
if [ "$g_conf" ]; then
    if ( grep -qi "include" "$g_conf" ); then # User is indicating the apps they WANT installed
        config_type=include;
        for gapp_name in $all_gapps_list; do
            if ( grep -qi "$gapp_name" "$g_conf" ); then
                gapps_list="$gapps_list$gapp_name"$'\n';
            fi;
        done;
    else # User is indicating the apps they DO NOT WANT installed
        config_type=exclude;
        for gapp_name in $all_gapps_list; do
            if ( ! grep -qi "$gapp_name" "$g_conf" ); then
                gapps_list="$gapps_list$gapp_name"$'\n';
            fi;
        done;
    fi;
else # User is not using a gapps-config and we're doing the 'full monty'
    config_type=[Default];
    gapps_list=$all_gapps_list;
fi;

# Configure default removal of Stock/AOSP apps - if we're installing Stock GApps
if [ $gapps_type = "stock" ]; then
    for default_name in $default_aosp_remove_list; do
        eval "remove_${default_name}=true[default]";
    done;
else
    # Do not perform any default removals - but make them optional
    for default_name in $default_aosp_remove_list; do
        eval "remove_${default_name}=false[default]";
    done;
fi;

# Prepare list of AOSP/ROM files that will be deleted using gapps-config
# We will look for +Browser, +Email, +Gallery, +Launcher, +MMS, +PicoTTS and +WebViewStock to prevent their removal
set_progress 0.03;
if [ "$g_conf" ]; then
    for default_name in $default_aosp_remove_list; do
        if ( grep -qi "+$default_name" "$g_conf" ); then
            eval "remove_${default_name}=false[gapps-config]";
        elif [ $gapps_type = "stock" ]; then
            aosp_remove_list="$aosp_remove_list$default_name"$'\n';
            if ( grep -qi "$default_name" "$g_conf" ); then
                eval "remove_${default_name}=true[gapps-config]";
            fi;
        else
            if ( grep -qi "$default_name" "$g_conf" ); then
                eval "remove_${default_name}=true[gapps-config]";
                aosp_remove_list="$aosp_remove_list$default_name"$'\n';
            fi;
        fi;
    done;
    # Check gapps-config for other optional AOSP/ROM files that will be deleted
    for opt_name in $optional_aosp_remove_list; do
        if ( grep -qi "$opt_name" "$g_conf" ); then
            aosp_remove_list="$aosp_remove_list$opt_name"$'\n';
        fi;
    done;
else
    aosp_remove_list=$default_aosp_remove_list;
fi;

# Verify device is FaceUnlock compatible BEFORE we allow it in $gapps_list
if ( contains "$gapps_list" "faceunlock" ) && [ $faceunlock_compat = "false" ]; then
    gapps_list=${gapps_list/faceunlock};
    install_note="${install_note}faceunlock_msg"$'\n'; # make note that FaceUnlock will NOT be installed as user requested
fi;

# If we're NOT installing chrome make certain 'browser' is NOT in $aosp_remove_list UNLESS 'browser' is in $g_conf
if ( ! contains "$gapps_list" "chrome" ) && ( ! grep -qi "browser" "$g_conf" ); then
    aosp_remove_list=${aosp_remove_list/browser};
    remove_browser=false[default];
fi;

# If we're NOT installing gmail make certain 'email' is NOT in $aosp_remove_list UNLESS 'email' is in $g_conf
if ( ! contains "$gapps_list" "gmail" ) && ( ! grep -qi "email" "$g_conf" ); then
    aosp_remove_list=${aosp_remove_list/email};
    remove_email=false[default];
fi;

# If we're NOT installing photos make certain 'gallery' is NOT in $aosp_remove_list UNLESS 'gallery' is in $g_conf
if ( ! contains "$gapps_list" "photos" ) && ( ! grep -qi "gallery" "$g_conf" ); then
    aosp_remove_list=${aosp_remove_list/gallery};
    remove_gallery=false[default];
fi;

# If $device_type is 'tablet' make certain we're not installing messenger
if ( contains "$gapps_list" "messenger" ) && [ $device_type = "tablet" ]; then
    gapps_list=${gapps_list/messenger}; # we'll prevent messenger from being installed since this isn't a phone
fi;

# If we're NOT installing hangouts or messenger make certain 'mms' is NOT in $aosp_remove_list UNLESS 'mms' is in $g_conf
if ( ! contains "$gapps_list" "hangouts" )  && ( ! contains "$gapps_list" "messenger" ) && ( ! grep -qi "mms" "$g_conf" ); then
    aosp_remove_list=${aosp_remove_list/mms};
    remove_mms=false[default];
fi;

# If we're NOT installing hangouts or messenger and mms is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "hangouts" ) && ( ! contains "$gapps_list" "messenger" ) && ( contains "$aosp_remove_list" "mms" ) && ( ! grep -qi "override" "$g_conf" ); then
    aosp_remove_list=${aosp_remove_list/mms}; # we'll prevent mms from being removed so user isn't left with no way to receive text messages
    remove_mms=false[NO_Override];
    install_note="${install_note}nomms_msg"$'\n'; # make note that MMS can't be removed unless user Overrides
fi;

# If we're NOT installing googletts make certain 'picotts' is NOT in $aosp_remove_list UNLESS 'picotts' is in $g_conf
if ( ! contains "$gapps_list" "googletts" ) && ( ! grep -qi "picotts" "$g_conf" ); then
    aosp_remove_list=${aosp_remove_list/picotts};
    remove_picotts=false[default];
fi;

# If we're NOT installing search then we MUST REMOVE googlenow from  $gapps_list (if it's currently there)
if ( ! contains "$gapps_list" "search" ) && ( contains "$gapps_list" "googlenow" ); then
    gapps_list=${gapps_list/googlenow};
    install_note="${install_note}googlenow_msg"$'\n'; # make note that Google Now Launcher will NOT be installed as user requested
fi;

# If we're NOT installing googlenow make certain 'launcher' is NOT in $aosp_remove_list UNLESS 'launcher' is in $g_conf
if ( ! contains "$gapps_list" "googlenow" ) && ( ! grep -qi "launcher" "$g_conf" ); then
    aosp_remove_list=${aosp_remove_list/launcher};
    remove_launcher=false[default];
fi;

# If we're NOT installing googlenow and launcher is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "googlenow" ) && ( contains "$aosp_remove_list" "launcher" ) && ( ! grep -qi "override" "$g_conf" ); then
    aosp_remove_list=${aosp_remove_list/launcher}; # we'll prevent launcher from being removed so user isn't left with no Launcher
    remove_launcher=false[NO_Override];
    install_note="${install_note}nolauncher_msg"$'\n'; # make note that Launcher can't be removed unless user Overrides
fi;

# If we're installing calendargoogle we must ADD calendarstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "calendargoogle" ) && ( ! contains "$aosp_remove_list" "calendarstock" ); then
    aosp_remove_list="${aosp_remove_list}calendarstock"$'\n';
fi;

# If we're NOT installing calendargoogle we will ADD calsync to $gapps_list IF $config_type != "include" AND $g_conf does NOT contain calsync
if ( ! contains "$gapps_list" "calendargoogle" ) && [ $config_type != "include" ] && ( ! grep -qi "calsync" "$g_conf" ); then
    gapps_list="${gapps_list}calsync"$'\n';
fi;

# Add calsync to $gapps_list IF $config_type = "include" AND $g_conf contains calsync
if [ $config_type = "include" ] && ( grep -qi "calsync" "$g_conf" ); then
    gapps_list="${gapps_list}calsync"$'\n';
fi;

# If user wants to install keyboardgoogle then it MUST be a Clean Install OR keyboardgoogle was previously installed in system partition
if ( contains "$gapps_list" "keyboardgoogle" ) && ( ! clean_inst ) && [ $keyboardgoogle_inst = "false" ]; then
    gapps_list=${gapps_list/keyboardgoogle}; # we must DISALLOW keyboardgoogle from being installed
    aosp_remove_list=${aosp_remove_list/keyboardstock}; # and we'll prevent keyboardstock from being removed so user isn't left with no keyboard
    install_note="${install_note}keyboard_sys_msg"$'\n'; # make note that Google Keyboard will NOT be installed as user requested
fi;

# If we're installing keyboardgoogle we must ADD keyboardstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "keyboardgoogle" ) && ( ! contains "$aosp_remove_list" "keyboardstock" ); then
    aosp_remove_list="${aosp_remove_list}keyboardstock"$'\n';
fi;

# If we're NOT installing keyboardgoogle and keyboardstock is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "keyboardgoogle" ) && ( contains "$aosp_remove_list" "keyboardstock" ) && ( ! grep -qi "override" "$g_conf" ); then
    aosp_remove_list=${aosp_remove_list/keyboardstock}; # we'll prevent keyboardstock from being removed so user isn't left with no keyboard
    install_note="${install_note}nokeyboard_msg"$'\n'; # make note that Stock Keyboard can't be removed unless user Overrides
fi;

# Verify device is Google Camera compatible BEFORE we allow it in $gapps_list
if ( contains "$gapps_list" "cameragoogle" ) && [ $cameragoogle_compat = "false" ]; then
    gapps_list=${gapps_list/cameragoogle}; # we must DISALLOW cameragoogle from being installed
    install_note="${install_note}camera_compat_msg"$'\n'; # make note that Google Camera will NOT be installed as user requested
fi;

# If user wants to install cameragoogle then it MUST be a Clean Install OR cameragoogle was previously installed in system partition
if ( contains "$gapps_list" "cameragoogle" ) && ( ! clean_inst ) && [ $cameragoogle_inst = "false" ]; then
    gapps_list=${gapps_list/cameragoogle}; # we must DISALLOW cameragoogle from being installed
    aosp_remove_list=${aosp_remove_list/camerastock}; # and we'll prevent camerastock from being removed so user isn't left with no camera
    install_note="${install_note}camera_sys_msg"$'\n'; # make note that Google Camera will NOT be installed as user requested
fi;

# If we're installing cameragoogle we MUST ADD camerastock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "cameragoogle" ) && ( ! contains "$aosp_remove_list" "camerastock" ); then
    aosp_remove_list="${aosp_remove_list}camerastock"$'\n';
fi;

# If we're installing exchangegoogle we must ADD exchangestock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "exchangegoogle" ) && ( ! contains "$aosp_remove_list" "exchangestock" ); then
    aosp_remove_list="${aosp_remove_list}exchangestock"$'\n';
fi;

# Verify ROM is Google Webview compatible BEFORE we allow it in $gapps_list
if ( contains "$gapps_list" "webview" ) && [ $webviewgoogle_compat = "false" ]; then
    gapps_list=${gapps_list/webview}; # we must DISALLOW webview from being installed
    install_note="${install_note}webview_compat_msg"$'\n'; # make note that Google Webview will NOT be installed as user requested
fi;

# If we're NOT installing webview make certain 'webviewstock' is NOT in $aosp_remove_list
if ( ! contains "$gapps_list" "webview" ); then
    aosp_remove_list=${aosp_remove_list/webviewstock};
    remove_webviewstock=false[default];
fi;

# Process User Application Removals for calculations and subsequent removal
if [ -n "$user_remove_list" ]; then
    for remove_apk in $user_remove_list; do 
        testapk=$( echo "$remove_apk" | tr '[:upper:]'  '[:lower:]' )
        # Add apk extension if user didn't include it
        case $testapk in
          *".apk" ) ;;
          * )       testapk="${testapk}.apk" ;;
        esac;
        # Check all files and folders in /system/app /system/priv-app for the apk
        for folder in /system/app /system/priv-app; do
            file_count=0; # Reset Counter
            file_count=$(find $folder -iname $testapk | wc -l);
            case $file_count in
                0)  continue;;
EOFILE
if [ "$API" -le "19" ]; then
	echo '                1)  app_folder="$(`find $folder -type f -iname $testapk`)"; # Determine file name since we found only 1 instance' >> "$build"installer.data
else
	echo '                1)  app_folder="$(dirname `find $folder -type f -iname $testapk`)"; # Determine folder name since we found only 1 instance' >> "$build"installer.data
fi
tee -a "$build"META-INF/com/google/android/update-binary > /dev/null <<'EOFILE'
                    user_remove_folder_list="${user_remove_folder_list}$app_folder"$'\n'; # Add 'found' app's folder to user_remove_folder_list
                    break;;
                *)  echo "$remove_apk" >> $user_remove_multiplefound_log; # Add app to user_remove_multiplefound_log since we found more than 1 instance
                    break;;
            esac;
        done;
        if [ $file_count -eq 0 ]; then echo "$remove_apk" >> $user_remove_notfound_log; fi; # Add 'not found' app to user_remove_notfound_log
    done;
fi;

# Read in gapps removal list from file
full_removal_list=$(cat $gapps_removal_list);

# Clean up and sort our lists for space calculations and installation
set_progress 0.04;
gapps_list=$(echo "${gapps_list}" | sort | sed '/^$/d'); # sort GApps list & remove empty lines
aosp_remove_list=$(echo "${aosp_remove_list}" | sort | sed '/^$/d'); # sort AOSP Remove list & remove empty lines
full_removal_list=$(echo "${full_removal_list}" | sed '/^$/d'); # Remove empty lines from FINAL GApps Removal list
remove_list=$(echo "${remove_list}" | sed '/^$/d'); # Remove empty lines from remove_list
user_remove_folder_list=$(echo "${user_remove_folder_list}" | sed '/^$/d'); # Remove empty lines from User Application Removal list

log "Installing GApps Version" $gapps_version;
log "Installing GApps Type" $gapps_type;
log "Config Type" $config_type;
log "Using gapps-config" "$config_file";
log "Remove Stock/AOSP Browser" $remove_browser;
log "Remove Stock/AOSP Email" $remove_email;
log "Remove Stock/AOSP Gallery" $remove_gallery;
log "Remove Stock/AOSP Launcher" $remove_launcher;
log "Remove Stock/AOSP MMS App" $remove_mms;
log "Remove Stock/AOSP Pico TTS" $remove_picotts;
log "Remove Stock/AOSP Stock WebView" $remove_webview;
log "Installing Play Services variation" "$gms)";
log "Installing Play Games variation" "$pg)";
log "Installing Messenger variation" "$msg)";
# _____________________________________________________________________________________________________________________
#                                                  Perform space calculations
ui_print "- Performing system space calculations";
ui_print " ";

# Perform calculations of device specific applications
eval "gms_size=\$gms_${gms}_size"; # Determine size of GMSCore
eval "messenger_size=\$msg_${msg}_size"; # Determine size of Messenger
eval "playgames_size=\$pg_${pg}_size"; # Determine size of PlayGames

# Determine final size of Core Apps
if ( ! contains "$gapps_list" "keyboardgoogle" ); then
    core_size=$((core_size + keybd_lib_size)); # Add Keyboard Lib size to core
fi;

# Read and save system partition size details
df=$(busybox df -k /system | tail -n 1);
case $df in
    /dev/block/*) df=$(echo $df | awk '{ print substr($0, index($0,$2)) }');;
esac;
total_system_size_kb=$(echo $df | awk '{ print $1 }');
used_system_size_kb=$(echo $df | awk '{ print $2 }');
free_system_size_kb=$(echo $df | awk '{ print $3 }');
log "Total System Size (KB)" $total_system_size_kb;
log "Used System Space (KB)" $used_system_size_kb;
log "Current Free Space (KB)" $free_system_size_kb;

# Perform storage space calculations of existing GApps that will be deleted/replaced
reclaimed_gapps_space_kb=$(du -ck `complete_gapps_list` | tail -n1 | awk '{ print $1 }');

# Perform storage space calculations of other Removals that need to be deleted (Obsolete and Conflicting Apps)
set_progress 0.05;
reclaimed_removal_space_kb=$(du -ck `obsolete_gapps_list` | tail -n1 | awk '{ print $1 }');

# Add information to calc.log that will later be added to open_gapps.log to assist user with app removals
post_install_size_kb=$((free_system_size_kb + reclaimed_gapps_space_kb)); # Add opening calculations
echo --------------------------------------------------------- > $calc_log;
printf "%7s | %25s |   %7s | %7s\n" "TYPE " "DESCRIPTION       " "SIZE" "  TOTAL" >> $calc_log;
printf "%7s | %25s |   %7d | %7d\n" "" "Current Free Space" $free_system_size_kb $free_system_size_kb >> $calc_log;
printf "%7s | %25s | + %7d | %7d\n" "Remove" "Existing GApps" $reclaimed_gapps_space_kb $post_install_size_kb >> $calc_log;
post_install_size_kb=$((post_install_size_kb + reclaimed_removal_space_kb)); # Add reclaimed_removal_space_kb
printf "%7s | %25s | + %7d | %7d\n" "Remove" "Obsolete Files" $reclaimed_removal_space_kb $post_install_size_kb >> $calc_log;

# Perform calculations of AOSP/ROM files that will be deleted
set_progress 0.07;
for aosp_name in $aosp_remove_list; do
    eval "list_name=\$${aosp_name}_list";
    aosp_size_kb=0; # Reset counter
    for file_name in $list_name; do
        if [ -e /system/$file_name ]; then
            file_size_kb=$(du -ck /system/$file_name | tail -n1 | awk '{ print $1 }');
            aosp_size_kb=$((file_size_kb + aosp_size_kb));
            post_install_size_kb=$((post_install_size_kb + file_size_kb));
        fi;
    done;
    log_add "Remove" "$aosp_name" $aosp_size_kb $post_install_size_kb;
done;

# Perform calculations of User App Removals that will be deleted
for remove_folder in $user_remove_folder_list; do
	if [ -e $remove_folder ]; then
		folder_size_kb=$(du -ck $remove_folder | tail -n1 | awk '{ print $1 }');
		post_install_size_kb=$((post_install_size_kb + folder_size_kb));
		log_add "Remove" "$(basename $remove_folder)°" $folder_size_kb $post_install_size_kb;
	fi;
done;

# Perform calculations of GApps files that will be installed
set_progress 0.09;
post_install_size_kb=$((post_install_size_kb - core_size)); # Add Core GApps
log_sub "Install" "Core²" $core_size $post_install_size_kb;
post_install_size_kb=$((post_install_size_kb - gms_size)); # Add Google Play Services
log_sub "Install" "GMSCore²" $gms_size $post_install_size_kb;

for gapp_name in $gapps_list; do
    eval "gapp_size_kb=\$${gapp_name}_size"; # Determine size of GApp being installed
    post_install_size_kb=$((post_install_size_kb - gapp_size_kb));
    log_sub "Install" "$gapp_name³" $gapp_size_kb $post_install_size_kb;
done;

# Perform calculations of required Buffer Size
set_progress 0.11;
if ( grep -qi "smallbuffer" "$g_conf" ); then
    buffer_size_kb=$small_buffer_size;
fi;

post_install_size_kb=$((post_install_size_kb - buffer_size_kb));
log_sub "" "Buffer Space²" $buffer_size_kb $post_install_size_kb;
echo --------------------------------------------------------- >> $calc_log;

if [ "$post_install_size_kb" -ge 0 ]; then
    printf "%47s | %7d\n" "  Post Install Free Space" $post_install_size_kb >> $calc_log;
    log "Post Install Free Space (KB)" "$post_install_size_kb       << See Calculations Below";
else
    additional_size_kb=$((post_install_size_kb * -1));
    printf "%47s | %7d\n" "Additional Space Required" $additional_size_kb >> $calc_log;
    log "Additional Space Required (KB)" "$additional_size_kb       << See Calculations Below";
fi;

# Finish up Calculation Log
echo --------------------------------------------------------- >> $calc_log;
if [ -n "$user_remove_folder_list" ]; then
    echo "              ° User Requested Removal" >> $calc_log;
fi;
echo "              ² Required (ALWAYS Installed)" >> $calc_log;
echo "             ³ Optional (may be removed)" >> $calc_log;

# Check whether there's enough free space to complete this installation
if [ "$post_install_size_kb" -lt 0 ]; then
    # We don't have enough system space to install everything user requested
    ui_print "Insufficient storage space available in";
    ui_print "System partition. You may want to use a";
    ui_print "smaller Open GApps package or consider";
    ui_print "removing some apps using gapps-config.";
    ui_print "See:'$log_folder/open_gapps_log.txt'";
    ui_print "for complete details and information.";
    ui_print " ";
    install_note="${install_note}system_space_msg"$'\n'; # make note that there is insufficient space in system to install
    abort $E_NOSPACE;
fi;

# Check to see if this is the 'real thing' or only a test
if ( grep -qi "test" "$g_conf" ); then # user has selected a 'test' install ONLY
    ui_print "- Exiting Simulated Install";
    ui_print " ";
    install_note="${install_note}simulation_msg"$'\n'; # make note that this is only a test installation
    quit;
    exxit 0;
fi;
# _____________________________________________________________________________________________________________________
#                                                  Perform Removals
# Remove ALL Existing GApps files
set_progress 0.13;
ui_print "- Removing existing/obsolete Apps";
ui_print " ";
rm -rf $(complete_gapps_list);

# Remove Obsolete and Conflicting Apps
rm -rf $(obsolete_gapps_list);

# Remove Stock/AOSP Apps and add Removals to addon.d script
aosp_remove_list=$(echo "${aosp_remove_list}" | sort -r); # reverse sort list for more readable output
for aosp_name in $aosp_remove_list; do
    eval "list_name=\$${aosp_name}_list";
    list_name=$(echo "${list_name}" | sort -r); # reverse sort list for more readable output
    for file_name in $list_name; do
        rm -rf /system/$file_name;
        sed -i "\:# Remove Stock/AOSP apps (from GApps Installer):a \    rm -rf /system/$file_name" $bkup_tail;
    done;
done;

# Perform User App Removals and add Removals to addon.d script
user_remove_folder_list=$(echo "${user_remove_folder_list}" | sort -r); # reverse sort list for more readable output
for user_app in $user_remove_folder_list; do
    rm -rf $user_app;
    sed -i "\:# Remove 'user requested' apps (from gapps-config):a \    rm -rf $user_app" $bkup_tail;
done;

# Remove any empty folders we may have created during the removal process
for i in /system/app /system/priv-app /system/vendor/pittpatt /system/usr/srec /system/etc/preferred-apps; do
    find $i -type d | xargs rmdir -p --ignore-fail-on-non-empty;
done;
# _____________________________________________________________________________________________________________________
#                                                  Perform Installs
ui_print "- Installing updated GApps";
ui_print " ";
set_progress 0.15;
folder_extract Core required; # Install Core GApps
if ( ! contains "$gapps_list" "keyboardgoogle" ); then
    folder_extract Optional keybd_lib; # Install Keyboard lib to add swipe capabilities to AOSP Keyboard
    mkdir -p /system/app/LatinIME/lib/arm;
    ln -sf /system/lib/$keybd_lib_filename1 /system/lib/$keybd_lib_filename2; # create required symlink
    ln -sf /system/lib/$keybd_lib_filename1 /system/app/LatinIME/lib/arm/$keybd_lib_filename1; # create required symlink
    ln -sf /system/lib/$keybd_lib_filename1 /system/app/LatinIME/lib/arm/$keybd_lib_filename2; # create required symlink
    # Add same code to backup script to insure symlinks are recreated on addon.d restore
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sf /system/lib/$keybd_lib_filename1 /system/app/LatinIME/lib/arm/$keybd_lib_filename2" $bkup_tail;
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sf /system/lib/$keybd_lib_filename1 /system/app/LatinIME/lib/arm/$keybd_lib_filename1" $bkup_tail;
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sf /system/lib/$keybd_lib_filename1 /system/lib/$keybd_lib_filename2" $bkup_tail;
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    mkdir -p /system/app/LatinIME/lib/arm" $bkup_tail;
fi;
set_progress 0.20;
folder_extract GMSCore common; # Install Google Play Services libs
set_progress 0.25;
folder_extract GMSCore $gms; # Install Google Play Services apk

# Install PlayGames if it's in $gapps_list
if ( contains "$gapps_list" "playgames" ); then
    folder_extract PlayGames common; # Install Google PlayGames libs
    folder_extract PlayGames $pg; # Install Google PlayGames apk
    gapps_list=${gapps_list/playgames}; # remove PlayGames from gapps list since it's now installed
fi;
# Install Messenger if it's in $gapps_list
if ( contains "$gapps_list" "messenger" ); then
    folder_extract Messenger $msg; # Install Google Messenger apk
    folder_extract Messenger common; # Install Google Messenger libs
    gapps_list=${gapps_list/messenger}; # Remove Messenger from gapps list since it's now installed
fi;

# Progress Bar increment calculations for GApps Install process
set_progress 0.30;
gapps_count=$(echo "${gapps_list}" | wc -w); # Count number of GApps left to be installed
if [ $gapps_count -lt 1 ]; then gapps_count=1; fi; # Prevent 'division by zero'
incr_amt=$(( 5000 / $gapps_count )); # Determine increment factor of progress bar during GApps installation
prog_bar=3000; # Set Progress Bar start point (0.3000) for below

# Install the rest of GApps still in $gapps_list
for gapp_name in $gapps_list; do
    folder_extract GApps $gapp_name; # Installing User Selected GApps
    prog_bar=$((prog_bar + incr_amt));
    set_progress 0.$prog_bar;
done;

# Create FaceLock lib symlink if FaceLock was installed
if ( contains "$gapps_list" "faceunlock" ); then
    mkdir -p /system/app/FaceLock/lib/arm;
    ln -sf /system/lib/$FaceLock_lib_filename /system/app/FaceLock/lib/arm/$FaceLock_lib_filename; # create required symlink
    # Add same code to backup script to insure symlinks are recreated on addon.d restore
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sf /system/lib/$FaceLock_lib_filename /system/app/FaceLock/lib/arm/$FaceLock_lib_filename" $bkup_tail;
    sed -i "\:# Recreate required symlinks (from GApps Installer):a \    mkdir -p /system/app/FaceLock/lib/arm" $bkup_tail;
fi;

# Copy g.prop over to /system/etc
cp -f /tmp/g.prop $g_prop;
# _____________________________________________________________________________________________________________________
#                                                  Build and Install Addon.d Backup Script
# Add 'other' Removals to addon.d script
set_progress 0.80;
other_list=$(echo "${other_list}" | sort -r); # reverse sort list for more readable output
for other_name in $other_list; do
    sed -i "\:# Remove 'other' apps (per installer.data):a \    rm -rf $other_name" $bkup_tail;
done;

# Add 'priv-app' Removals to addon.d script
privapp_list=$(echo "${privapp_list}" | sort -r); # reverse sort list for more readable output
for privapp_name in $privapp_list; do
    sed -i "\:# Remove 'priv-app' apps from 'app' (per installer.data):a \    rm -rf $privapp_name" $bkup_tail;
done;

# Add 'required' Removals to addon.d script
reqd_list=$(echo "${reqd_list}" | sort -r); # reverse sort list for more readable output
for reqdapp_name in $reqd_list; do
    sed -i "\:# Remove 'required' apps (per installer.data):a \    rm -rf $reqdapp_name" $bkup_tail;
done;

# Create final addon.d script in system
bkup_header="#!/sbin/sh\n# \n# /system/addon.d/70-gapps.sh\n#\n. /tmp/backuptool.functions\n\nlist_files() {\ncat <<EOF"
bkup_list="$bkup_list"$'\n'etc/g.prop; # add g.prop to backup list
bkup_list=$(echo "${bkup_list}" | sort -u| sed '/^$/d'); # sort list & remove duplicates and empty lines
mkdir -p /system/addon.d;
echo -e "$bkup_header" > /system/addon.d/70-gapps.sh;
echo -e "$bkup_list" >> /system/addon.d/70-gapps.sh;
cat $bkup_tail >> /system/addon.d/70-gapps.sh;
# _____________________________________________________________________________________________________________________
#                                                  Fix Permissions
set_progress 0.83;
ui_print "- Fixing permissions & contexts";
ui_print " ";
set_perm_recursive 0 0 755 644 "/system/app" "/system/framework" "/system/lib" "/system/priv-app" "/system/usr/srec" "/system/vendor/pittpatt" "/system/etc/permissions" "/system/etc/preferred-apps";

set_progress 0.85;
set_perm_recursive 0 0 755 755 "/system/addon.d";

set_progress 0.87;
find /system/vendor/pittpatt -type d -exec chown 0.2000 '{}' \; -exec chown 0:2000 '{}' \; # Change pittpatt folders to root:shell per Google Factory Settings

set_perm 0 0 644 $g_prop;

# Set contexts on all files we installed
set_progress 0.88;
ch_con_recursive "/system/app" "/system/framework" "/system/lib" "/system/priv-app" "/system/usr/srec" "/system/vendor/pittpatt" "/system/etc/permissions" "/system/etc/preferred-apps" "/system/addon.d";
ch_con $g_prop;

set_progress 0.92;
quit;

ui_print "- Installation complete!";
ui_print " ";
exxit 0;
EOFILE
}

