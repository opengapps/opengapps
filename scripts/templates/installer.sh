#!/sbin/ash
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
#    This script of the Open GApps Installer is contains work from the PA GApps of @TKruzze and @osm0sis,
#    PA GApps source is used with permission, under the license that it may be re-used to continue GApps packages.
#
# Last Updated: @DATE@

newline='
'

# _____________________________________________________________________________________________________________________
#                                             Define Current Package Variables
# List of GApps packages that can be installed with this installer
pkg_names="@SUPPORTEDVARIANTS@"

# Installer Name (32 chars Total, excluding "")
installer_name="Open GApps @VARIANT@ @PLATFORM@ - "

req_android_arch="@ARCH@"
req_android_sdk="@API@"
req_android_version="@PLATFORM@"

@KEYBDLIBS@
atvremote_lib_filename="libatv_uinputbridge.so"
WebView_lib_filename="libwebviewchromium.so"
markup_lib_filename="libsketchology_native.so"

# Buffer of extra system space to require for GApps install (9216=9MB)
# This will allow for some ROM size expansion when GApps are restored
buffer_size_kb=9216
small_buffer_size=2048

# List of GApps files that should NOT be automatically removed as they are also included in (many) ROMs
removal_bypass_list="@REMOVALBYPASS@
"

# Define exit codes (returned upon exit due to an error)
E_ROMVER=20 # Wrong ROM version
E_NOBUILDPROP=25 #No build.prop or equivalent
E_RECCOMPR=30 # Recovery without transparent compression
E_NOSPACE=70 # Insufficient Space Available in System Partition
E_NONOPEN=40 # NON Open GApps Currently Installed
E_ARCH=64 # Wrong Architecture Detected
#_________________________________________________________________________________________________________________
#                                             GApps List (Applications user can Select/Deselect)
core_gapps_list="
@gappscore@
"

super_gapps_list="
@gappssuper@
"

stock_gapps_list="
@gappsstock@
"

full_gapps_list="
@gappsfull@
"

mini_gapps_list="
@gappsmini@
"

micro_gapps_list="
@gappsmicro@
"

nano_gapps_list="
@gappsnano@
"

pico_gapps_list="
@gappspico@
"

tvcore_gapps_list="
@gappstvcore@
"

tvmini_gapps_list="
@gappstvmini@
"

tvstock_gapps_list="
@gappstvstock@
"

# _____________________________________________________________________________________________________________________
#                                             Default Stock/AOSP Removal List (Stock GApps Only)
default_stock_remove_list="
@stockremove@
"

# _____________________________________________________________________________________________________________________
#                                             Optional Stock/AOSP/ROM Removal List
optional_aosp_remove_list="
boxer
basicdreams
calculatorstock
calendarstock
clockstock
cmaudiofx
cmaccount
cmbugreport
cmfilemanager
cmmusic
cmscreencast
cmsetupwizard
cmupdater
cmwallpapers
cmweatherprovider
dashclock
exchangestock
extservicesstock
extsharedstock
fmradio
galaxy
hexo
holospiral
keyboardstock
lbr0zip
livewallpapers
lockclock
logcat
lrecorder
lsetupwizard
lupdater
mms
mzfilemanager
mzpay
mzsetupwizard
mzupdater
mzweather
noisefield
omniswitch
phasebeam
photophase
phototable
printservicestock
provision
simtoolkit
soundrecorder
storagemanagerstock
studio
sykopath
tagstock
terminal
themes
visualizationwallpapers
wallpapersstock
whisperpush
"

# _____________________________________________________________________________________________________________________
#                                             Stock/AOSP/ROM File Removal Lists
boxer_list="
vendor/bundled-app/Boxer@REMOVALSUFFIX@"

browser_list="
app/Bolt@REMOVALSUFFIX@
app/Browser@REMOVALSUFFIX@
app/Browser2@REMOVALSUFFIX@
app/BrowserIntl@REMOVALSUFFIX@
app/BrowserProviderProxy@REMOVALSUFFIX@
app/Chromium@REMOVALSUFFIX@
app/DuckDuckGo@REMOVALSUFFIX@
app/Fluxion@REMOVALSUFFIX@
app/Gello@REMOVALSUFFIX@
app/Jelly@REMOVALSUFFIX@
app/PA_Browser@REMOVALSUFFIX@
app/PABrowser@REMOVALSUFFIX@
app/YuBrowser@REMOVALSUFFIX@
priv-app/BLUOpera@REMOVALSUFFIX@
priv-app/BLUOperaPreinstall@REMOVALSUFFIX@
priv-app/Browser@REMOVALSUFFIX@
priv-app/BrowserIntl@REMOVALSUFFIX@
product/app/Bolt@REMOVALSUFFIX@
product/app/Browser@REMOVALSUFFIX@
product/app/Browser2@REMOVALSUFFIX@
product/app/BrowserIntl@REMOVALSUFFIX@
product/app/BrowserProviderProxy@REMOVALSUFFIX@
product/app/Chromium@REMOVALSUFFIX@
product/app/DuckDuckGo@REMOVALSUFFIX@
product/app/Fluxion@REMOVALSUFFIX@
product/app/Gello@REMOVALSUFFIX@
product/app/Jelly@REMOVALSUFFIX@
product/app/PA_Browser@REMOVALSUFFIX@
product/app/PABrowser@REMOVALSUFFIX@
product/app/YuBrowser@REMOVALSUFFIX@
product/priv-app/BLUOpera@REMOVALSUFFIX@
product/priv-app/BLUOperaPreinstall@REMOVALSUFFIX@
product/priv-app/Browser@REMOVALSUFFIX@
product/priv-app/BrowserIntl@REMOVALSUFFIX@"

basicdreams_list="
app/BasicDreams@REMOVALSUFFIX@
product/app/BasicDreams@REMOVALSUFFIX@"

# Must be used when GoogleCalculator is installed
calculatorstock_list="
app/Calculator@REMOVALSUFFIX@
app/ExactCalculator@REMOVALSUFFIX@
app/FineOSCalculator@REMOVALSUFFIX@
product/app/Calculator@REMOVALSUFFIX@
product/app/ExactCalculator@REMOVALSUFFIX@
product/app/FineOSCalculator@REMOVALSUFFIX@"

# Must be used when GoogleCalendar is installed
calendarstock_list="
app/Calendar@REMOVALSUFFIX@
app/FineOSCalendar@REMOVALSUFFIX@
app/MonthCalendarWidget@REMOVALSUFFIX@
app/SimpleCalendar@REMOVALSUFFIX@
priv-app/Calendar@REMOVALSUFFIX@
product/app/Calendar@REMOVALSUFFIX@
product/app/Etar@REMOVALSUFFIX@
product/app/FineOSCalendar@REMOVALSUFFIX@
product/app/MonthCalendarWidget@REMOVALSUFFIX@
product/app/SimpleCalendar@REMOVALSUFFIX@
product/priv-app/Calendar@REMOVALSUFFIX@"

# Must be used when GoogleCamera is installed
camerastock_list="
app/Camera2@REMOVALSUFFIX@
app/Camera@REMOVALSUFFIX@
app/FineOSCamera@REMOVALSUFFIX@
app/MotCamera@REMOVALSUFFIX@
app/MtkCamera@REMOVALSUFFIX@
app/MTKCamera@REMOVALSUFFIX@
app/SnapdragonCamera@REMOVALSUFFIX@
app/Snap@REMOVALSUFFIX@
priv-app/Camera2@REMOVALSUFFIX@
priv-app/Camera@REMOVALSUFFIX@
priv-app/CameraX@REMOVALSUFFIX@
priv-app/MiuiCamera@REMOVALSUFFIX@
priv-app/MotCamera@REMOVALSUFFIX@
priv-app/MtkCamera@REMOVALSUFFIX@
priv-app/MTKCamera@REMOVALSUFFIX@
priv-app/SnapdragonCamera@REMOVALSUFFIX@
priv-app/Snap@REMOVALSUFFIX@
product/app/Camera2@REMOVALSUFFIX@
product/app/Camera@REMOVALSUFFIX@
product/app/FineOSCamera@REMOVALSUFFIX@
product/app/MotCamera@REMOVALSUFFIX@
product/app/MtkCamera@REMOVALSUFFIX@
product/app/MTKCamera@REMOVALSUFFIX@
product/app/SnapdragonCamera@REMOVALSUFFIX@
product/app/Snap@REMOVALSUFFIX@
product/priv-app/Camera2@REMOVALSUFFIX@
product/priv-app/Camera@REMOVALSUFFIX@
product/priv-app/CameraX@REMOVALSUFFIX@
product/priv-app/MiuiCamera@REMOVALSUFFIX@
product/priv-app/MotCamera@REMOVALSUFFIX@
product/priv-app/MtkCamera@REMOVALSUFFIX@
product/priv-app/MTKCamera@REMOVALSUFFIX@
product/priv-app/SnapdragonCamera@REMOVALSUFFIX@
product/priv-app/Snap@REMOVALSUFFIX@"

clockstock_list="
app/DeskClock@REMOVALSUFFIX@
app/DeskClock2@REMOVALSUFFIX@
app/FineOSDeskClock@REMOVALSUFFIX@
app/OmniClockOSS@REMOVALSUFFIX@
product/app/DeskClock@REMOVALSUFFIX@
product/app/DeskClock2@REMOVALSUFFIX@
product/app/FineOSDeskClock@REMOVALSUFFIX@
product/app/OmniClockOSS@REMOVALSUFFIX@"

cmaccount_list="
priv-app/CMAccount@REMOVALSUFFIX@
product/priv-app/CMAccount@REMOVALSUFFIX@"

cmaudiofx_list="
priv-app/AudioFX@REMOVALSUFFIX@
product/priv-app/AudioFX@REMOVALSUFFIX@"

cmbugreport_list="
priv-app/CMBugReport@REMOVALSUFFIX@
product/priv-app/CMBugReport@REMOVALSUFFIX@"

cmfilemanager_list="
app/CMFileManager@REMOVALSUFFIX@
product/app/CMFileManager@REMOVALSUFFIX@"

cmmusic_list="
app/Apollo@REMOVALSUFFIX@
app/Eleven@REMOVALSUFFIX@
priv-app/Eleven@REMOVALSUFFIX@
app/Music@REMOVALSUFFIX@
app/MusicX@REMOVALSUFFIX@
app/Phonograph@REMOVALSUFFIX@
app/SnapdragonMusic@REMOVALSUFFIX@
product/app/Apollo@REMOVALSUFFIX@
product/app/Eleven@REMOVALSUFFIX@
product/priv-app/Eleven@REMOVALSUFFIX@
product/app/Music@REMOVALSUFFIX@
product/app/MusicX@REMOVALSUFFIX@
product/app/Phonograph@REMOVALSUFFIX@
product/app/SnapdragonMusic@REMOVALSUFFIX@"

cmscreencast_list="
priv-app/Screencast@REMOVALSUFFIX@
product/priv-app/Screencast@REMOVALSUFFIX@"

cmsetupwizard_list="
app/CyanogenSetupWizard@REMOVALSUFFIX@
priv-app/CyanogenSetupWizard@REMOVALSUFFIX@
product/app/CyanogenSetupWizard@REMOVALSUFFIX@
product/priv-app/CyanogenSetupWizard@REMOVALSUFFIX@"

cmupdater_list="
priv-app/CMUpdater@REMOVALSUFFIX@
product/priv-app/CMUpdater@REMOVALSUFFIX@"

cmwallpapers_list="
app/CMWallpapers@REMOVALSUFFIX@
product/app/CMWallpapers@REMOVALSUFFIX@"

cmweatherprovider_list="
priv-app/WeatherProvider@REMOVALSUFFIX@
product/priv-app/WeatherProvider@REMOVALSUFFIX@"

# Must be used when Google Contacts is installed
contactsstock_list="
priv-app/Contacts@REMOVALSUFFIX@
priv-app/FineOSContacts@REMOVALSUFFIX@
product/priv-app/Contacts@REMOVALSUFFIX@
product/priv-app/FineOSContacts@REMOVALSUFFIX@"

dashclock_list="
app/DashClock@REMOVALSUFFIX@
product/app/DashClock@REMOVALSUFFIX@"

# Must be used when Google Dialer is installed
# For now, prevent stock AOSP Dialer (priv-app/Dialer) from being removed, no matter the configuration, on all ROMs
dialerstock_list="
priv-app/FineOSDialer@REMOVALSUFFIX@
priv-app/OPInCallUI@REMOVALSUFFIX@
product/priv-app/FineOSDialer@REMOVALSUFFIX@
product/priv-app/OPInCallUI@REMOVALSUFFIX@"

email_list="
app/Email@REMOVALSUFFIX@
app/PrebuiltEmailGoogle@REMOVALSUFFIX@
priv-app/Email@REMOVALSUFFIX@
product/app/Email@REMOVALSUFFIX@
product/app/PrebuiltEmailGoogle@REMOVALSUFFIX@
product/priv-app/Email@REMOVALSUFFIX@"

exchangestock_list="
app/Exchange2@REMOVALSUFFIX@
priv-app/Exchange2@REMOVALSUFFIX@
product/app/Exchange2@REMOVALSUFFIX@
product/priv-app/Exchange2@REMOVALSUFFIX@"

extservicesstock_list="
priv-app/ExtServices@REMOVALSUFFIX@
product/priv-app/ExtServices@REMOVALSUFFIX@"

extsharedstock_list="
app/ExtShared@REMOVALSUFFIX@
product/app/ExtShared@REMOVALSUFFIX@"

fmradio_list="
app/FM@REMOVALSUFFIX@
app/FM2@REMOVALSUFFIX@
app/FMRecord@REMOVALSUFFIX@
priv-app/FMRadio@REMOVALSUFFIX@
priv-app/MiuiRadio@REMOVALSUFFIX@
product/app/FM@REMOVALSUFFIX@
product/app/FM2@REMOVALSUFFIX@
product/app/FMRecord@REMOVALSUFFIX@
product/priv-app/FMRadio@REMOVALSUFFIX@
product/priv-app/MiuiRadio@REMOVALSUFFIX@"

galaxy_list="
app/Galaxy4@REMOVALSUFFIX@
product/app/Galaxy4@REMOVALSUFFIX@"

gallery_list="
app/Gallery@REMOVALSUFFIX@
app/Gallery2@REMOVALSUFFIX@
app/MotGallery@REMOVALSUFFIX@
app/MediaShortcuts@REMOVALSUFFIX@
app/SimpleGallery@REMOVALSUFFIX@
priv-app/FineOSGallery@REMOVALSUFFIX@
priv-app/Gallery@REMOVALSUFFIX@
priv-app/Gallery2@REMOVALSUFFIX@
priv-app/GalleryX@REMOVALSUFFIX@
priv-app/MediaShortcuts@REMOVALSUFFIX@
priv-app/MiuiGallery@REMOVALSUFFIX@
priv-app/MotGallery@REMOVALSUFFIX@
priv-app/SnapdragonGallery@REMOVALSUFFIX@
product/app/Gallery@REMOVALSUFFIX@
product/app/Gallery2@REMOVALSUFFIX@
product/app/MotGallery@REMOVALSUFFIX@
product/app/MediaShortcuts@REMOVALSUFFIX@
product/app/SimpleGallery@REMOVALSUFFIX@
product/priv-app/FineOSGallery@REMOVALSUFFIX@
product/priv-app/Gallery@REMOVALSUFFIX@
product/priv-app/Gallery2@REMOVALSUFFIX@
product/priv-app/GalleryX@REMOVALSUFFIX@
product/priv-app/MediaShortcuts@REMOVALSUFFIX@
product/priv-app/MiuiGallery@REMOVALSUFFIX@
product/priv-app/MotGallery@REMOVALSUFFIX@
product/priv-app/SnapdragonGallery@REMOVALSUFFIX@"

hexo_list="
app/HexoLibre@REMOVALSUFFIX@
product/app/HexoLibre@REMOVALSUFFIX@"

holospiral_list="
app/HoloSpiralWallpaper@REMOVALSUFFIX@
product/app/HoloSpiralWallpaper@REMOVALSUFFIX@"

# Must be used when GoogleKeyboard is installed
keyboardstock_list="
app/LatinIME@REMOVALSUFFIX@
app/MzInput@REMOVALSUFFIX@
app/OpenWnn@REMOVALSUFFIX@
priv-app/BLUTouchPal@REMOVALSUFFIX@
priv-app/BLUTouchPalPortuguesebrPack@REMOVALSUFFIX@
priv-app/BLUTouchPalSpanishLatinPack@REMOVALSUFFIX@
priv-app/MzInput@REMOVALSUFFIX@
product/app/LatinIME@REMOVALSUFFIX@
product/app/MzInput@REMOVALSUFFIX@
product/app/OpenWnn@REMOVALSUFFIX@
product/priv-app/BLUTouchPal@REMOVALSUFFIX@
product/priv-app/BLUTouchPalPortuguesebrPack@REMOVALSUFFIX@
product/priv-app/BLUTouchPalSpanishLatinPack@REMOVALSUFFIX@
product/priv-app/MzInput@REMOVALSUFFIX@"

launcher_list="
app/CMHome@REMOVALSUFFIX@
app/CustomLauncher3@REMOVALSUFFIX@
app/EasyLauncher@REMOVALSUFFIX@
app/FineOSHome@REMOVALSUFFIX@
app/Fluctuation@REMOVALSUFFIX@
app/FlymeLauncher@REMOVALSUFFIX@
app/FlymeLauncherIntl@REMOVALSUFFIX@
app/Launcher2@REMOVALSUFFIX@
app/Launcher3@REMOVALSUFFIX@
app/LawnConf@REMOVALSUFFIX@
app/LiquidLauncher@REMOVALSUFFIX@
app/Paclauncher@REMOVALSUFFIX@
app/SlimLauncher@REMOVALSUFFIX@
app/Trebuchet@REMOVALSUFFIX@
priv-app/CMHome@REMOVALSUFFIX@
priv-app/CustomLauncher3@REMOVALSUFFIX@
priv-app/EasyLauncher@REMOVALSUFFIX@
priv-app/Fluctuation@REMOVALSUFFIX@
priv-app/FlymeLauncher@REMOVALSUFFIX@
priv-app/FlymeLauncherIntl@REMOVALSUFFIX@
priv-app/Launcher2@REMOVALSUFFIX@
priv-app/Launcher3@REMOVALSUFFIX@
priv-app/Launcher3Go@REMOVALSUFFIX@
priv-app/Launcher3QuickStep@REMOVALSUFFIX@
priv-app/Launcher3QuickStepGo@REMOVALSUFFIX@
priv-app/Lawnchair@REMOVALSUFFIX@
priv-app/LiquidLauncher@REMOVALSUFFIX@
priv-app/MiuiHome@REMOVALSUFFIX@
priv-app/Nox@REMOVALSUFFIX@
priv-app/Paclauncher@REMOVALSUFFIX@
priv-app/SlimLauncher@REMOVALSUFFIX@
priv-app/Trebuchet@REMOVALSUFFIX@
priv-app/TrebuchetGo@REMOVALSUFFIX@
priv-app/TrebuchetQuickStep@REMOVALSUFFIX@
priv-app/TrebuchetQuickStepGo@REMOVALSUFFIX@
product/app/CMHome@REMOVALSUFFIX@
product/app/CustomLauncher3@REMOVALSUFFIX@
product/app/EasyLauncher@REMOVALSUFFIX@
product/app/FineOSHome@REMOVALSUFFIX@
product/app/Fluctuation@REMOVALSUFFIX@
product/app/FlymeLauncher@REMOVALSUFFIX@
product/app/FlymeLauncherIntl@REMOVALSUFFIX@
product/app/Launcher2@REMOVALSUFFIX@
product/app/Launcher3@REMOVALSUFFIX@
product/app/LawnConf@REMOVALSUFFIX@
product/app/LiquidLauncher@REMOVALSUFFIX@
product/app/Paclauncher@REMOVALSUFFIX@
product/app/SlimLauncher@REMOVALSUFFIX@
product/app/Trebuchet@REMOVALSUFFIX@
product/priv-app/CMHome@REMOVALSUFFIX@
product/priv-app/CustomLauncher3@REMOVALSUFFIX@
product/priv-app/EasyLauncher@REMOVALSUFFIX@
product/priv-app/Fluctuation@REMOVALSUFFIX@
product/priv-app/FlymeLauncher@REMOVALSUFFIX@
product/priv-app/FlymeLauncherIntl@REMOVALSUFFIX@
product/priv-app/Launcher2@REMOVALSUFFIX@
product/priv-app/Launcher3@REMOVALSUFFIX@
product/priv-app/Launcher3Go@REMOVALSUFFIX@
product/priv-app/Launcher3GoIconRecents@REMOVALSUFFIX@
product/priv-app/Launcher3QuickStep@REMOVALSUFFIX@
product/priv-app/Launcher3QuickStepGo@REMOVALSUFFIX@
product/priv-app/Lawnchair@REMOVALSUFFIX@
product/priv-app/LiquidLauncher@REMOVALSUFFIX@
product/priv-app/MiuiHome@REMOVALSUFFIX@
product/priv-app/Nox@REMOVALSUFFIX@
product/priv-app/Paclauncher@REMOVALSUFFIX@
product/priv-app/SlimLauncher@REMOVALSUFFIX@
product/priv-app/Trebuchet@REMOVALSUFFIX@
product/priv-app/TrebuchetGo@REMOVALSUFFIX@
product/priv-app/TrebuchetGoIconRecents@REMOVALSUFFIX@
product/priv-app/TrebuchetQuickStep@REMOVALSUFFIX@
product/priv-app/TrebuchetQuickStepGo@REMOVALSUFFIX@"

tvlaunch_list="
priv-app/TVLauncherNoGMS@REMOVALSUFFIX@
priv-app/TVRecommendationsNoGMS@REMOVALSUFFIX@"

lbr0zip_list="
app/Br0Zip@REMOVALSUFFIX@
product/app/Br0Zip@REMOVALSUFFIX@"

livewallpapers_list="
app/LiveWallpapers@REMOVALSUFFIX@
product/app/LiveWallpapers@REMOVALSUFFIX@"

lockclock_list="
app/LockClock@REMOVALSUFFIX@
product/app/LockClock@REMOVALSUFFIX@"

logcat_list="
priv-app/MatLog@REMOVALSUFFIX@
product/priv-app/MatLog@REMOVALSUFFIX@"

lrecorder_list="
priv-app/Recorder@REMOVALSUFFIX@
product/app/Recorder@REMOVALSUFFIX@
product/priv-app/Recorder@REMOVALSUFFIX@"

lsetupwizard_list="
app/LineageSetupWizard@REMOVALSUFFIX@
priv-app/LineageSetupWizard@REMOVALSUFFIX@
product/app/LineageSetupWizard@REMOVALSUFFIX@
product/priv-app/LineageSetupWizard@REMOVALSUFFIX@"

lupdater_list="
priv-app/Updater@REMOVALSUFFIX@
product/priv-app/Updater@REMOVALSUFFIX@"

mms_list="
app/messaging@REMOVALSUFFIX@
priv-app/Mms@REMOVALSUFFIX@
priv-app/FineOSMms@REMOVALSUFFIX@
product/app/messaging@REMOVALSUFFIX@
product/priv-app/Mms@REMOVALSUFFIX@
product/priv-app/FineOSMms@REMOVALSUFFIX@"

mzfilemanager_list="
app/FileManager@REMOVALSUFFIX@
product/app/FileManager@REMOVALSUFFIX@"

mzpay_list="
app/MzMPay@REMOVALSUFFIX@
app/MzPay@REMOVALSUFFIX@
product/app/MzMPay@REMOVALSUFFIX@
product/app/MzPay@REMOVALSUFFIX@"

mzsetupwizard_list="
app/MzSetupWizard@REMOVALSUFFIX@
product/app/MzSetupWizard@REMOVALSUFFIX@"

mzupdater_list="
app/MzUpdate@REMOVALSUFFIX@
app/SystemUpdate@REMOVALSUFFIX@
app/SystemUpdateAssistant@REMOVALSUFFIX@
product/app/MzUpdate@REMOVALSUFFIX@
product/app/SystemUpdate@REMOVALSUFFIX@
product/app/SystemUpdateAssistant@REMOVALSUFFIX@"

mzweather_list="
app/Weather@REMOVALSUFFIX@
product/app/Weather@REMOVALSUFFIX@"

noisefield_list="
app/NoiseField@REMOVALSUFFIX@
product/app/NoiseField@REMOVALSUFFIX@"

omniswitch_list="
priv-app/OmniSwitch@REMOVALSUFFIX@
product/priv-app/OmniSwitch@REMOVALSUFFIX@"

# Must be used when Google PackageInstaller is installed; non-capitalized spelling on Lenovo K3 Note
packageinstallerstock_list="
app/PackageInstaller@REMOVALSUFFIX@
priv-app/PackageInstaller@REMOVALSUFFIX@
priv-app/packageinstaller@REMOVALSUFFIX@
product/app/PackageInstaller@REMOVALSUFFIX@
product/priv-app/PackageInstaller@REMOVALSUFFIX@
product/priv-app/packageinstaller@REMOVALSUFFIX@"

phasebeam_list="
app/PhaseBeam@REMOVALSUFFIX@
product/app/PhaseBeam@REMOVALSUFFIX@"

photophase_list="
app/PhotoPhase@REMOVALSUFFIX@
product/app/PhotoPhase@REMOVALSUFFIX@"

phototable_list="
app/PhotoTable@REMOVALSUFFIX@
product/app/PhotoTable@REMOVALSUFFIX@"

picotts_list="
app/PicoTts@REMOVALSUFFIX@
priv-app/PicoTts@REMOVALSUFFIX@
lib/libttscompat.so
lib/libttspico.so
product/app/PicoTts@REMOVALSUFFIX@
product/priv-app/PicoTts@REMOVALSUFFIX@
product/lib/libttscompat.so
product/lib/libttspico.so
tts"

printservicestock_list="
app/BuiltInPrintService@REMOVALSUFFIX@
app/PrintRecommendationService@REMOVALSUFFIX@
product/app/BuiltInPrintService@REMOVALSUFFIX@
product/app/PrintRecommendationService@REMOVALSUFFIX@"

provision_list="
app/Provision@REMOVALSUFFIX@
priv-app/Provision@REMOVALSUFFIX@
product/app/Provision@REMOVALSUFFIX@
product/priv-app/Provision@REMOVALSUFFIX@"

simtoolkit_list="
app/Stk@REMOVALSUFFIX@
product/app/Stk@REMOVALSUFFIX@"

soundrecorder_list="
app/SoundRecorder@REMOVALSUFFIX@
product/app/SoundRecorder@REMOVALSUFFIX@"

storagemanagerstock_list="
priv-app/StorageManager@REMOVALSUFFIX@
product/priv-app/StorageManager@REMOVALSUFFIX@"

studio_list="
app/VideoEditor@REMOVALSUFFIX@
product/app/VideoEditor@REMOVALSUFFIX@"

sykopath_list="
app/Layers@REMOVALSUFFIX@
product/app/Layers@REMOVALSUFFIX@"

tagstock_list="
priv-app/Tag@REMOVALSUFFIX@
product/priv-app/Tag@REMOVALSUFFIX@"

terminal_list="
app/Terminal@REMOVALSUFFIX@
product/app/Terminal@REMOVALSUFFIX@"

themes_list="
priv-app/CustomizeCenter@REMOVALSUFFIX@
priv-app/ThemeChooser@REMOVALSUFFIX@
priv-app/ThemesProvider@REMOVALSUFFIX@
product/priv-app/CustomizeCenter@REMOVALSUFFIX@
product/priv-app/ThemeChooser@REMOVALSUFFIX@
product/priv-app/ThemesProvider@REMOVALSUFFIX@"

visualizationwallpapers_list="
app/VisualizationWallpapers@REMOVALSUFFIX@
product/app/VisualizationWallpapers@REMOVALSUFFIX@"

wallpapersstock_list="
app/WallpaperPicker@REMOVALSUFFIX@
product/app/WallpaperPicker@REMOVALSUFFIX@"

webviewstock_list="
app/webview@REMOVALSUFFIX@
app/WebView@REMOVALSUFFIX@
product/app/webview@REMOVALSUFFIX@
product/app/WebView@REMOVALSUFFIX@
@webviewstocklibs@"

whisperpush_list="
app/WhisperPush@REMOVALSUFFIX@
product/app/WhisperPush@REMOVALSUFFIX@"

# _____________________________________________________________________________________________________________________
#                                             Permanently Removed Folders
# Pieces that may be left over from AIO ROMs that can/will interfere with these GApps
other_list="
app/BooksStub@REMOVALSUFFIX@
app/BookmarkProvider@REMOVALSUFFIX@
app/CalendarGoogle@REMOVALSUFFIX@
app/CloudPrint@REMOVALSUFFIX@
app/DeskClockGoogle@REMOVALSUFFIX@
app/EditorsDocsStub@REMOVALSUFFIX@
app/EditorsSheetsStub@REMOVALSUFFIX@
app/EditorsSlidesStub@REMOVALSUFFIX@
app/Gmail@REMOVALSUFFIX@
app/Gmail2@REMOVALSUFFIX@
app/GoogleCalendar@REMOVALSUFFIX@
app/GoogleCloudPrint@REMOVALSUFFIX@
app/GoogleHangouts@REMOVALSUFFIX@
app/GoogleKeep@REMOVALSUFFIX@
app/GoogleLatinIme@REMOVALSUFFIX@
app/Keep@REMOVALSUFFIX@
app/NewsstandStub@REMOVALSUFFIX@
app/PartnerBookmarksProvider@REMOVALSUFFIX@
app/PrebuiltBugleStub@REMOVALSUFFIX@
app/PrebuiltKeepStub@REMOVALSUFFIX@
app/QuickSearchBox@REMOVALSUFFIX@
app/Vending@REMOVALSUFFIX@
priv-app/GmsCore@REMOVALSUFFIX@
priv-app/GoogleNow@REMOVALSUFFIX@
priv-app/GoogleSearch@REMOVALSUFFIX@
priv-app/GoogleHangouts@REMOVALSUFFIX@
priv-app/OneTimeInitializer@REMOVALSUFFIX@
priv-app/QuickSearchBox@REMOVALSUFFIX@
priv-app/Vending@REMOVALSUFFIX@
priv-app/Velvet_update@REMOVALSUFFIX@
priv-app/GmsCore_update@REMOVALSUFFIX@
product/app/BooksStub@REMOVALSUFFIX@
product/app/BookmarkProvider@REMOVALSUFFIX@
product/app/CalendarGoogle@REMOVALSUFFIX@
product/app/CloudPrint@REMOVALSUFFIX@
product/app/DeskClockGoogle@REMOVALSUFFIX@
product/app/EditorsDocsStub@REMOVALSUFFIX@
product/app/EditorsSheetsStub@REMOVALSUFFIX@
product/app/EditorsSlidesStub@REMOVALSUFFIX@
product/app/Gmail@REMOVALSUFFIX@
product/app/Gmail2@REMOVALSUFFIX@
product/app/GoogleCalendar@REMOVALSUFFIX@
product/app/GoogleCloudPrint@REMOVALSUFFIX@
product/app/GoogleHangouts@REMOVALSUFFIX@
product/app/GoogleKeep@REMOVALSUFFIX@
product/app/GoogleLatinIme@REMOVALSUFFIX@
product/app/Keep@REMOVALSUFFIX@
product/app/NewsstandStub@REMOVALSUFFIX@
product/app/PartnerBookmarksProvider@REMOVALSUFFIX@
product/app/PrebuiltBugleStub@REMOVALSUFFIX@
product/app/PrebuiltKeepStub@REMOVALSUFFIX@
product/app/QuickSearchBox@REMOVALSUFFIX@
product/app/Vending@REMOVALSUFFIX@
product/priv-app/GmsCore@REMOVALSUFFIX@
product/priv-app/GoogleNow@REMOVALSUFFIX@
product/priv-app/GoogleSearch@REMOVALSUFFIX@
product/priv-app/GoogleHangouts@REMOVALSUFFIX@
product/priv-app/OneTimeInitializer@REMOVALSUFFIX@
product/priv-app/QuickSearchBox@REMOVALSUFFIX@
product/priv-app/Vending@REMOVALSUFFIX@
product/priv-app/Velvet_update@REMOVALSUFFIX@
product/priv-app/GmsCore_update@REMOVALSUFFIX@
"

# Apps from app that need to be installed in priv-app
privapp_list="
app/CanvasPackageInstaller@REMOVALSUFFIX@
app/ConfigUpdater@REMOVALSUFFIX@
app/GoogleBackupTransport@REMOVALSUFFIX@
app/GoogleFeedback@REMOVALSUFFIX@
app/GoogleLoginService@REMOVALSUFFIX@
app/GoogleOneTimeInitializer@REMOVALSUFFIX@
app/GooglePartnerSetup@REMOVALSUFFIX@
app/GoogleServicesFramework@REMOVALSUFFIX@
app/OneTimeInitializer@REMOVALSUFFIX@
app/Phonesky@REMOVALSUFFIX@
app/PrebuiltGmsCore@REMOVALSUFFIX@
app/SetupWizard@REMOVALSUFFIX@
app/Velvet@REMOVALSUFFIX@
product/app/CanvasPackageInstaller@REMOVALSUFFIX@
product/app/ConfigUpdater@REMOVALSUFFIX@
product/app/GoogleBackupTransport@REMOVALSUFFIX@
product/app/GoogleFeedback@REMOVALSUFFIX@
product/app/GoogleLoginService@REMOVALSUFFIX@
product/app/GoogleOneTimeInitializer@REMOVALSUFFIX@
product/app/GooglePartnerSetup@REMOVALSUFFIX@
product/app/GoogleServicesFramework@REMOVALSUFFIX@
product/app/OneTimeInitializer@REMOVALSUFFIX@
product/app/Phonesky@REMOVALSUFFIX@
product/app/PrebuiltGmsCore@REMOVALSUFFIX@
product/app/SetupWizard@REMOVALSUFFIX@
product/app/Velvet@REMOVALSUFFIX@
"

# Stock/AOSP Keyboard lib (and symlink) that are always removed since they are always replaced
reqd_list="
@REQDLIST@
"

# Remove from priv-app since it was moved to app and vice-versa or other path changes
obsolete_list="
app/CalculatorGoogle
priv-app/GoogleHome@REMOVALSUFFIX@
priv-app/Hangouts@REMOVALSUFFIX@
priv-app/PrebuiltExchange3Google@REMOVALSUFFIX@
priv-app/talkback@REMOVALSUFFIX@
priv-app/Wallet@REMOVALSUFFIX@
product/app/CalculatorGoogle
product/priv-app/GoogleHome@REMOVALSUFFIX@
product/priv-app/Hangouts@REMOVALSUFFIX@
product/priv-app/PrebuiltExchange3Google@REMOVALSUFFIX@
product/priv-app/talkback@REMOVALSUFFIX@
product/priv-app/Wallet@REMOVALSUFFIX@
"

# Old addon.d backup scripts as we will be replacing with updated version during install
oldscript_list="
etc/g.prop
addon.d/70-gapps.sh
"

remove_list="${other_list}${privapp_list}${reqd_list}${obsolete_list}${oldscript_list}"

# _____________________________________________________________________________________________________________________
#                                             Installer Error Messages
arch_compat_msg="INSTALLATION FAILURE: This Open GApps package cannot be installed on this\ndevice's architecture. Please download the correct version for your device.\n"
camera_sys_msg="WARNING: Google Camera has/will not be installed as requested. Google Camera\ncan only be installed during a Clean Install or as an update to an existing\nGApps Installation.\n"
camera_compat_msg="WARNING: Google Camera has/will not be installed as requested. Google Camera\nis NOT compatible with your device if installed on the system partition. Try\ninstalling from the Play Store instead.\n"
cmcompatibility_msg="WARNING: PackageInstallerGoogle is not installed. Cyanogenmod is NOT\ncompatible with some Google Applications and Open GApps\n will skip their installation.\n"
dialergoogle_msg="WARNING: Google Dialer has/will not be installed as requested. Dialer Framework\nmust be added to the GApps installation if you want to install the\nGoogle Dialer.\n"
googlenow_msg="WARNING: Google Now Launcher has/will not be installed as requested. Google Search\nmust be added to the GApps installation if you want to install the\nGoogle Now Launcher.\n"
messenger_msg="WARNING: Google Messages has/will not be installed as requested. Carrier Services\nmust be added to the GApps installation on Android 6.0+ if you want to install\nGoogle Messages.\n"
pixellauncher_msg="WARNING: Pixel Launcher has/will not be installed as requested. Wallpapers and\nGoogle Search must be added to the GApps installation if you want to install\nthe Pixel Launcher.\n"
projectfi_msg="WARNING: Project Fi has/will not be installed as requested. GCS must be\nadded to the GApps installation if you want to install the Project Fi app.\n"
nobuildprop="INSTALLATION FAILURE: The installed ROM has no build.prop or equivalent\n"
nokeyboard_msg="NOTE: The Stock/AOSP keyboard was NOT removed as requested to ensure your device\nwas not accidentally left with no keyboard installed. If this was intentional,\nyou can add 'Override' to your gapps-config to override this protection.\n"
nolauncher_msg="NOTE: The Stock/AOSP Launcher was NOT removed as requested to ensure your device\nwas not accidentally left with no Launcher. If this was your intention, you can\nadd 'Override' to your gapps-config to override this protection.\n"
nomms_msg="NOTE: The Stock/AOSP MMS app was NOT removed as requested to ensure your device\nwas not accidentally left with no way to receive text messages. If this WAS\nintentional, add 'Override' to your gapps-config to override this protection.\n"
nowebview_msg="NOTE: The Stock/AOSP WebView was NOT removed as requested to ensure your device\nwas not accidentally left with no WebViewProvider installed. If this was intentional,\nyou can add 'Override' to your gapps-config to override this protection.\n"
non_open_gapps_msg="INSTALLATION FAILURE: Open GApps can only be installed on top of an existing\nOpen GApps installation. Since you are currently using another GApps package, you\nwill need to wipe (format) your system partition before installing Open GApps.\n"
fornexus_open_gapps_msg="NOTE: The installer detected that you already have Stock ROM GApps installed.\nThe installer will now continue, but please be aware that there could be problems.\n"
recovery_compression_msg="INSTALLATION FAILURE: Your ROM uses transparent compression, but your recovery\ndoes not support this feature, resulting in corrupt files.\nPlease update your recovery before flashing ANY package to prevent corruption.\n"
rom_android_version_msg="INSTALLATION FAILURE: This GApps package can only be installed on a $req_android_version.x ROM.\n"
simulation_msg="TEST INSTALL: This was only a simulated install. NO CHANGES WERE MADE TO YOUR\nDEVICE. To complete the installation remove 'Test' from your gapps-config.\n"
stubwebview_msg="NOTE: Stub WebView was installed instead of Google WebView because your device\nhas already Chrome installed as WebViewProvider. If you still want Google WebView,\nyou can add 'Override' to your gapps-config to override this redundancy protection.\n"
system_space_msg="INSTALLATION FAILURE: Your device does not have sufficient space available in\nthe system partition to install this GApps package as currently configured.\nYou will need to switch to a smaller GApps package or use gapps-config to\nreduce the installed size.\n"
user_multiplefound_msg="NOTE: All User Application Removals included in gapps-config were unable to be\nprocessed as requested because multiple versions of the app were found on your\ndevice. See the log portion below for the name(s) of the application(s).\n"
user_notfound_msg="NOTE: All User Application Removals included in gapps-config were unable to be\nremoved as requested because the files were not found on your device. See the\nlog portion below for the name(s) of the application(s).\n"
vrservice_compat_msg="WARNING: Google VR Services has/will not be installed as requested.\nGoogle VR Services is NOT compatible with your device.\n"
del_conflict_msg="!!! WARNING !!! - Duplicate files were found between your ROM and this GApps\npackage. This is likely due to your ROM's dev including Google proprietary\nfiles in the ROM. The duplicate files are shown in the log portion below.\n"

nogooglecontacts_removal_msg="NOTE: The Stock/AOSP Contacts is not available on your\nROM (anymore), the Google equivalent will not be removed."
nogoogledialer_removal_msg="NOTE: The Stock/AOSP Dialer is not available on your\nROM (anymore), the Google equivalent will not be removed."
nogooglekeyboard_removal_msg="NOTE: The Stock/AOSP Keyboard is not available on your\nROM (anymore), the Google equivalent will not be removed."
nogooglepackageinstaller_removal_msg="NOTE: The Stock/AOSP Package Installer is not\navailable on your ROM (anymore), the Google equivalent will not be removed."
nogoogletag_removal_msg="NOTE: The Stock/AOSP NFC Tag is not available on your\nROM (anymore), the Google equivalent will not be removed."
nogooglewebview_removal_msg="NOTE: The Stock/AOSP WebView is not available on your\nROM (anymore), not all Google WebViewProviders will be removed."

# _____________________________________________________________________________________________________________________
#                                                  Pre-define Helper Functions
get_file_prop() { grep -m1 "^$2=" "$1" | cut -d= -f2-; }

set_progress() { echo "set_progress $1" >> $OUTFD; }

ui_print() {
  echo "ui_print $1
    ui_print" >> $OUTFD
}

find_slot() {
  local slot=$(getprop ro.boot.slot_suffix 2>/dev/null)
  [ "$slot" ] || slot=$(grep -o 'androidboot.slot_suffix=.*$' /proc/cmdline | cut -d\  -f1 | cut -d= -f2)
  if [ ! "$slot" ]; then
    slot=$(getprop ro.boot.slot 2>/dev/null)
    [ "$slot" ] || slot=$(grep -o 'androidboot.slot=.*$' /proc/cmdline | cut -d\  -f1 | cut -d= -f2)
    [ "$slot" ] && slot=_$slot
  fi
  [ "$slot" ] && echo "$slot"
}

setup_mountpoint() {
  [ -L $1 ] && mv -f $1 ${1}_link
  if [ ! -d $1 ]; then
    rm -f $1
    mkdir -p $1
  fi
}

is_mounted() { mount | grep -q " $1 "; }

mount_apex() {
  [ -d /system_root/system/apex ] || return 1
  local apex dest loop minorx num
  setup_mountpoint /apex
  minorx=1
  [ -e /dev/block/loop1 ] && minorx=$(ls -l /dev/block/loop1 | awk '{ print $6 }')
  num=0
  for apex in /system_root/system/apex/*; do
    dest=/apex/$(basename $apex .apex)
    [ "$dest" = /apex/com.android.runtime.release ] && dest=/apex/com.android.runtime
    mkdir -p $dest
    case $apex in
      *.apex)
        unzip -qo $apex apex_payload.img -d /apex
        mv -f /apex/apex_payload.img $dest.img
        mount -t ext4 -o ro,noatime $dest.img $dest 2>/dev/null
        if [ $? != 0 ]; then
          while [ $num -lt 64 ]; do
            loop=/dev/block/loop$num
            (mknod $loop b 7 $((num * minorx))
            losetup $loop $dest.img) 2>/dev/null
            num=$((num + 1))
            losetup $loop | grep -q $dest.img && break
          done
          mount -t ext4 -o ro,loop,noatime $loop $dest
          if [ $? != 0 ]; then
            losetup -d $loop 2>/dev/null
          fi
        fi
      ;;
      *) mount -o bind $apex $dest;;
    esac
  done
  export ANDROID_RUNTIME_ROOT=/apex/com.android.runtime
  export ANDROID_TZDATA_ROOT=/apex/com.android.tzdata
  export BOOTCLASSPATH=/apex/com.android.runtime/javalib/core-oj.jar:/apex/com.android.runtime/javalib/core-libart.jar:/apex/com.android.runtime/javalib/okhttp.jar:/apex/com.android.runtime/javalib/bouncycastle.jar:/apex/com.android.runtime/javalib/apache-xml.jar:/system/framework/framework.jar:/system/framework/ext.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/ims-common.jar:/system/framework/android.test.base.jar:/system/framework/telephony-ext.jar:/apex/com.android.conscrypt/javalib/conscrypt.jar:/apex/com.android.media/javalib/updatable-media.jar
}

umount_apex() {
  [ -d /apex ] || return 1
  local dest loop
  for dest in $(find /apex -type d -mindepth 1 -maxdepth 1); do
    if [ -f $dest.img ]; then
      loop=$(mount | grep $dest | cut -d" " -f1)
    fi
    (umount -l $dest
    losetup -d $loop) 2>/dev/null
  done
  rm -rf /apex 2>/dev/null
  unset ANDROID_RUNTIME_ROOT ANDROID_TZDATA_ROOT BOOTCLASSPATH
}

mount_all() {
  if ! is_mounted /cache; then
    mount /cache 2>/dev/null && UMOUNT_CACHE=1
  fi
  if ! is_mounted /data; then
    mount /data && UMOUNT_DATA=1
  fi
  (mount -o ro -t auto /vendor
  mount -o ro -t auto /product
  mount -o ro -t auto /persist) 2>/dev/null
  setup_mountpoint $ANDROID_ROOT
  if ! is_mounted $ANDROID_ROOT; then
    mount -o ro -t auto $ANDROID_ROOT 2>/dev/null
  fi
  case $ANDROID_ROOT in
    /system_root) setup_mountpoint /system;;
    /system)
      if ! is_mounted /system && ! is_mounted /system_root; then
        setup_mountpoint /system_root
        mount -o ro -t auto /system_root
      elif [ -f /system/system/build.prop ]; then
        setup_mountpoint /system_root
        mount --move /system /system_root
      fi
      if [ $? != 0 ]; then
        (umount /system
        umount -l /system) 2>/dev/null
        if [ -d /dev/block/mapper ]; then
          [ -e /dev/block/mapper/system ] || local slot=$(find_slot)
          mount -o ro -t auto /dev/block/mapper/vendor$slot /vendor
          mount -o ro -t auto /dev/block/mapper/product$slot /product 2>/dev/null
          mount -o ro -t auto /dev/block/mapper/system$slot /system_root
        else
          [ -e /dev/block/bootdevice/by-name/system ] || local slot=$(find_slot)
          (mount -o ro -t auto /dev/block/bootdevice/by-name/vendor$slot /vendor
          mount -o ro -t auto /dev/block/bootdevice/by-name/product$slot /product
          mount -o ro -t auto /dev/block/bootdevice/by-name/persist$slot /persist) 2>/dev/null
          mount -o ro -t auto /dev/block/bootdevice/by-name/system$slot /system_root
        fi
      fi
    ;;
  esac
  if is_mounted /system_root; then
    mount_apex
    if [ -f /system_root/build.prop ]; then
      mount -o bind /system_root /system
    else
      mount -o bind /system_root/system /system
    fi
  fi
}

umount_all() {
  local mount
  (umount /system
  umount -l /system
  if [ -e /system_root ]; then
    umount /system_root
    umount -l /system_root
  fi
  umount_apex
  for mount in /mnt/system /vendor /mnt/vendor /product /mnt/product /persist; do
    umount $mount
    umount -l $mount
  done
  if [ "$UMOUNT_DATA" ]; then
    umount /data
    umount -l /data
  fi
  if [ "$UMOUNT_CACHE" ]; then
    umount /cache
    umount -l /cache
  fi) 2>/dev/null
}

# _____________________________________________________________________________________________________________________
#                                                  Gather Pre-Install Info
# Are we on an Android device is or is a really stupid person running this script on their computer?
if [ -e "/etc/lsb-release" ] || [ -n "$OSTYPE" ]; then
  echo "Don't run this on your computer! You need to flash the Open GApps zip on an Android Recovery!"
  exit 1
fi

# Get GApps Version and GApps Type from g.prop extracted at top of script
gapps_version=$(get_file_prop "$TMP/g.prop" "ro.addon.open_version")
gapps_type=$(get_file_prop "$TMP/g.prop" "ro.addon.open_type")

# _____________________________________________________________________________________________________________________
#                                                  Begin GApps Installation
ui_print " "
ui_print '##############################'
ui_print '  _____   _____   ___   ____  '
ui_print ' /  _  \ |  __ \ / _ \ |  _ \ '
ui_print '|  / \  || |__) | |_| || | \ \'
ui_print '| |   | ||  ___/|  __/ | | | |'
ui_print '|  \ /  || |    \ |__  | | | |'
ui_print ' \_/ \_/ |_|     \___| |_| |_|'
ui_print '       ___   _   ___ ___  ___ '
ui_print '      / __| /_\ | _ \ _ \/ __|'
ui_print '     | (_ |/ _ \|  _/  _/\__ \'
ui_print '      \___/_/ \_\_| |_|  |___/'
ui_print '##############################'
ui_print " "
ui_print "$installer_name$gapps_version"
ui_print " "

# _____________________________________________________________________________________________________________________
#                                                  Mount partitions
# For reference, check https://github.com/osm0sis/AnyKernel3/blob/master/META-INF/com/google/android/update-binary
ui_print "- Mounting partitions"
set_progress 0.01

BOOTMODE=false
ps | grep zygote | grep -v grep >/dev/null && BOOTMODE=true
$BOOTMODE || ps -A 2>/dev/null | grep zygote | grep -v grep >/dev/null && BOOTMODE=true

[ "$ANDROID_ROOT" ] || ANDROID_ROOT=/system

# emulators can only flash booted and may need /system (on legacy images), or / (on system-as-root images), remounted rw
if ! $BOOTMODE; then
  mount -o bind /dev/urandom /dev/random
  if [ -L /etc ]; then
    setup_mountpoint /etc
    cp -af /etc_link/* /etc
    sed -i 's; / ; /system_root ;' /etc/fstab
  fi
  umount_all
  mount_all
fi
if [ -d /dev/block/mapper ]; then
  for block in system vendor product; do
    for slot in "" _a _b; do
      blockdev --setrw /dev/block/mapper/$block$slot 2>/dev/null
    done
  done
fi
mount -o rw,remount -t auto /system || mount -o rw,remount -t auto /
(mount -o rw,remount -t auto /vendor
mount -o rw,remount -t auto /product) 2>/dev/null

ui_print " "

# _____________________________________________________________________________________________________________________
#                      Detect A/B partition layout https://source.android.com/devices/tech/ota/ab_updates
device_abpartition=$(getprop ro.build.ab_update)
[ -n "$device_abpartition" ] || device_abpartition=false

# _____________________________________________________________________________________________________________________
#                                                  Declare Variables
zip_folder="$(dirname "$OPENGAZIP")"
g_prop=/system/etc/g.prop
PROPFILES="$g_prop /system/default.prop /system/build.prop /system/product/build.prop /vendor/build.prop /product/build.prop /system_root/default.prop /system_root/build.prop /system_root/product/build.prop /data/local.prop /default.prop /build.prop"
bkup_tail=$TMP/bkup_tail.sh
gapps_removal_list=$TMP/gapps-remove.txt
g_log=$TMP/g.log
calc_log=$TMP/calc.log
conflicts_log=$TMP/conflicts.log
rec_cache_log=/cache/recovery/log
rec_tmp_log=$TMP/recovery.log
user_remove_notfound_log=$TMP/user_remove_notfound.log
user_remove_multiplefound_log=$TMP/user_remove_multiplefound.log

log_close="# End Open GApps Install Log\n"

reclaimed_gapps_space_kb=0
reclaimed_removal_space_kb=0
reclaimed_aosp_space_kb=0
total_install_size_kb=0

# _____________________________________________________________________________________________________________________
#                                                  Define Functions
abort() {
  quit
  ui_print "- NO changes were made to your device"
  ui_print " "
  ui_print "Installer will now exit..."
  ui_print " "
  ui_print "Error Code: $1"
  sleep 5
  exxit "$1"
}

ch_con() {
  chcon -h u:object_r:${1}_file:s0 "$2"
}

checkmanifest() {
  if [ -f "$1" ] && ("$TMP/unzip-$BINARCH" -ql "$1" | grep -q "META-INF/MANIFEST.MF"); then  # strict, only files
    "$TMP/unzip-$BINARCH" -p "$1" "META-INF/MANIFEST.MF" | grep -q "$2"
    return "$?"
  else
    return 0
  fi
}

complete_gapps_list() {
  cat <<EOF
$full_removal_list
EOF
}

contains() {
  case "$1" in
    *"$2"*) return 0;;
    *)      return 1;;
  esac
}

clean_inst() {
  if [ -f /data/system/packages.xml ] && [ "$forceclean" != "true" ]; then
    return 1
  fi
  return 0
}

exists_in_zip(){
  "$TMP/unzip-$BINARCH" -l "$OPENGAZIP" "$1" | grep -q "$1"
  return $?
}

extract_app() {
  tarpath="$TMP/$1.tar" # NB no suffix specified here
  if "$TMP/unzip-$BINARCH" -o "$OPENGAZIP" "$1.tar*" -d "$TMP"; then # wildcard for suffix
    app_name="$(basename "$1")"
    which_dpi "$app_name"
    echo "Found $1 DPI path: $dpiapkpath"
    folder_extract "$tarpath" "$dpiapkpath" "$app_name/common"
  else
    echo "Failed to extract $1.tar* from $OPENGAZIP"
  fi
}

exxit() {
  set_progress 0.98
  if [ "$skipvendorlibs" = "true" ]; then
    umount $ANDROID_ROOT/vendor  # unmount tmpfs
  fi
  if ( ! grep -qiE '^ *nodebug *($|#)+' "$g_conf" ); then
    if [ "$g_conf" ]; then # copy gapps-config files to debug logs folder
      cp -f "$g_conf_orig" "$TMP/logs/gapps-config_original.txt"
      cp -f "$g_conf" "$TMP/logs/gapps-config_processed.txt"
    fi
    ls -alZR /system > "$TMP/logs/System_Files_After.txt"
    df -k > "$TMP/logs/Device_Space_After.txt"
    cp -f "$log_folder/open_gapps_log.txt" "$TMP/logs"
    for f in $PROPFILES; do
      cp -f "$f" "$TMP/logs"
    done
    cp -f "/system/addon.d/70-gapps.sh" "$TMP/logs"
    cp -f "$gapps_removal_list" "$TMP/logs/gapps-remove_revised.txt"
    cp -f "$rec_cache_log" "$TMP/logs/Recovery_cache.log"
    cp -f "$rec_tmp_log" "$TMP/logs/Recovery_tmp.log"
    OLD_LD_PATH=$LD_LIBRARY_PATH
    OLD_LD_PRE=$LD_PRELOAD
    OLD_LD_CFG=$LD_CONFIG_FILE
    unset LD_LIBRARY_PATH LD_PRELOAD LD_CONFIG_FILE
    logcat -d -f "$TMP/logs/logcat"
    [ "$OLD_LD_PATH" ] && export LD_LIBRARY_PATH=$OLD_LD_PATH
    [ "$OLD_LD_PRE" ] && export LD_PRELOAD=$OLD_LD_PRE
    [ "$OLD_LD_CFG" ] && export LD_CONFIG_FILE=$OLD_LD_CFG
    cd "$TMP"
    tar -cz -f "$log_folder/open_gapps_debug_logs.tar.gz" logs/*
    cd /
  fi

  # Unmount and rollback script changes
  set_progress 1.0
  if ! $BOOTMODE; then
    ui_print "- Unmounting partitions"
    umount_all
    [ -L /etc_link ] && rm -rf /etc/*
    local dir
    (for dir in /apex /system /system_root /etc; do
      if [ -L "${dir}_link" ]; then
        rmdir $dir
        mv -f ${dir}_link $dir
      fi
    done
    umount -l /dev/random) 2>/dev/null
  fi

  # Finally, clean up $TMP
  find $TMP/* -maxdepth 0 ! -path "$rec_tmp_log" -exec rm -rf {} +

  ui_print " "
  exit "$1"
}

folder_extract() {
  archive="$1"
  shift
  if [ -e "$archive.xz" ]; then
    for f in "$@"; do
      if [ "$f" != "unknown" ]; then
        "$TMP/xzdec-$BINARCH" "$archive.xz" | "$TMP/tar-$BINARCH" -x -C "$TMP" -f - "$f" && install_extracted "$f"
      fi
    done
    rm -f "$archive.xz"
  elif [ -e "$archive.lz" ]; then
    for f in "$@"; do
      if [ "$f" != "unknown" ]; then
        "$TMP/tar-$BINARCH" -xf "$archive.lz" -C "$TMP" "$f" && install_extracted "$f"
      fi
    done
    rm -f "$archive.lz"
  elif [ -e "$archive" ]; then
    for f in "$@"; do
      if [ "$f" != "unknown" ]; then
        "$TMP/tar-$BINARCH" -xf "$archive" -C "$TMP" "$f" && install_extracted "$f"
      fi
    done
    rm -f "$archive"
  fi
}

get_apparch() {
  if [ -z "$2" ]; then  # no arch given
    apparch="$arch"
  else
    apparch="$2"
  fi
  if exists_in_zip "$1-$apparch.*"; then  # add the . to make sure it is not a substring being matched
    return 0
  else
    get_fallback_arch "$apparch"
    if [ "$apparch" != "$fallback_arch" ]; then
      get_apparch "$1" "$fallback_arch"
      return $?
    else
      apparch=""  # No arch-specific package
      return 1
    fi
  fi
}

get_apparchives(){
  apparchives=""
  if get_apparch "$1"; then
    apparchives="$1-$apparch"
  fi
  if exists_in_zip "$1-common.*"; then
    apparchives="$1-common $apparchives"
  fi
  if exists_in_zip "$1-lib-$arch.*"; then
    apparchives="$1-lib-$arch $apparchives"
  fi
  if [ -n "$fbarch" ] && exists_in_zip "$1-lib-$fbarch.*"; then
    apparchives="$1-lib-$fbarch $apparchives"
  fi
}

get_appsize() {
  app_name="$(basename "$1")"
  which_dpi "$app_name"
  app_density="$(basename "$dpiapkpath")"
  appsize="$(cat $TMP/app_sizes.txt | grep -E "$app_name.*[[:blank:]]($app_density|common)[[:blank:]]" | awk 'BEGIN { app_size=0; } { folder_size=$3; app_size=app_size+folder_size; } END { printf app_size; }')"
}

get_fallback_arch(){
  case "$1" in
    arm)    fallback_arch="all";;
    arm64)  fallback_arch="arm";;
    x86)    fallback_arch="arm";; #by using libhoudini
    x86_64) fallback_arch="x86";; #e.g. chain: x86_64->x86->arm->all
    *)      fallback_arch="$1";; #return original arch if no fallback available
  esac
}

get_prop() {
  #check known .prop files using get_file_prop
  local propfile propval
  for propfile in $PROPFILES; do
    if [ "$propval" ]; then
      break
    else
      propval="$(get_file_prop $propfile $1 2>/dev/null)"
    fi
  done
  #if propval is no longer empty output current result; otherwise try to use recovery's built-in getprop method
  if [ "$propval" ]; then
    echo "$propval"
  else
    getprop "$1"
  fi
}

install_extracted() {
  file_list="$(find "$TMP/$1/" -mindepth 1 -type f | cut -d/ -f5-)"
  dir_list="$(find "$TMP/$1/" -mindepth 1 -type d | cut -d/ -f5-)"
  for file in $file_list; do
    install -D "$TMP/$1/${file}" "/system/${file}"
    # overlays require different SELinux context
    case $file in
      */overlay/*) ch_con vendor_overlay "/system/${file}";;
      *)           ch_con system "/system/${file}";;
    esac
    set_perm 0 0 644 "/system/${file}"
  done
  for dir in $dir_list; do
    ch_con system "/system/${dir}"
    set_perm 0 0 755 "/system/${dir}"
  done
  bkup_list="$newline${file_list}${bkup_list}"
  rm -rf "$TMP/$1"
}

log() {
  printf "%31s | %s\n" "$1" "$2" >> $g_log
}

log_add() {
  printf "%7s | %26s | + %7d | %7d\n" "$1" "$2" "$3" "$4">> $calc_log
}

log_sub() {
  printf "%7s | %26s | - %7d | %7d\n" "$1" "$2" "$3" "$4">> $calc_log
}

obsolete_gapps_list() {
  cat <<EOF
$remove_list
EOF
}

quit() {
  set_progress 0.94
  install_note=$(echo "${install_note}" | sort -r | sed '/^$/d') # sort Installation Notes & remove empty lines
  echo ------------------------------------------------------------------ >> $g_log
  echo -e "$log_close" >> $g_log

  # Add Installation Notes to log to help user better understand conflicts/errors
  for note in $install_note; do
    eval "error_msg=\$${note}"
    echo -e "$error_msg" >> $g_log
  done

  # Add User App Removals NotFound Log if it exists
  if [ -r $user_remove_notfound_log ]; then
    echo -e "$user_notfound_msg" >> $g_log
    echo "# Begin User App Removals NOT Found (from gapps-config)" >> $g_log
    cat $user_remove_notfound_log >> $g_log
    rm -f $user_remove_notfound_log
    echo -e "# End User App Removals NOT Found (from gapps-config)\n" >> $g_log
  fi
  # Add User App Removals MultipleFound Log if it exists
  if [ -r $user_remove_multiplefound_log ]; then
    echo -e "$user_multiplefound_msg" >> $g_log
    echo "# Begin User App Removals MULTIPLE Found (from gapps-config)" >> $g_log
    cat $user_remove_multiplefound_log >> $g_log
    rm -f $user_remove_multiplefound_log
    echo -e "# End User App Removals MULTIPLE Found (from gapps-config)\n" >> $g_log
  fi

  # Add Duplicate Files Log if it exists
  if [ -r $conflicts_log ]; then
    echo -e "$del_conflict_msg" >> $g_log
    echo "# Begin GApps <> ROM Duplicate File List" >> $g_log
    cat $conflicts_log >> $g_log
    rm -f $conflicts_log
    echo -e "# End GApps <> ROM Duplicate File List\n" >> $g_log
  fi

  # Add Installation Calculations to the log if they were performed
  if [ -r $calc_log ]; then
    echo "# Begin GApps Size Calculations" >> $g_log
    cat $calc_log >> $g_log
    rm -f $calc_log
    echo -e "\n# End GApps Size Calculations" >> $g_log
  fi

  # Add list of Raw User Application Removals back to end of processed gapps-config for display in gapps log
  if [ -n "$user_remove_list" ]; then
    for user_remove_app_raw in $user_remove_list; do
      echo "(${user_remove_app_raw})" >> "$g_conf"
    done
  fi

  set_progress 0.96
  # Add gapps-config information to the log
  echo -e "\n# Begin User's gapps-config" >> $g_log
  if [ "$g_conf" ]; then
    cat "$g_conf" >> $g_log
  else
    echo -n "   *** NOT USED ***" >> $g_log
  fi
  echo -e "\n# End User's gapps-config" >> $g_log

  # Copy logs to proper folder (Same as gapps-config or same as Zip)
  ui_print "- Copying Log to $log_folder"
  ui_print " "
  cp -f $g_log "$log_folder/open_gapps_log.txt"
  rm -f $g_log
  set_progress 0.97
}

set_perm() {
  chown "$1:$2" "$4"
  chmod "$3" "$4"
}

sys_app() {
  for folder in /system/app /system/product/app /system/priv-app /system/product/priv-app; do
    if ( grep -q "codePath=\"$folder/$1" /data/system/packages.xml ); then
      return 0
    fi
  done
  return 1
}

which_dpi() {
  # Calculate available densities
  app_densities=""
  app_densities="$(cat $TMP/app_densities.txt | grep -E "$1/([0-9-]+|nodpi)/" | sed -r 's#.*/([0-9-]+|nodpi)/.*#\1#' | sort)"
  dpiapkpath="unknown"
  # Check if in the package there is a version for our density, or a universal one.
  for densities in $app_densities; do
    case "$densities" in
      *"$density"*) dpiapkpath="$1/$densities"; break;;
      *nodpi*)      dpiapkpath="$1/nodpi"; break;;
    esac
  done
  # Check if density is unknown or set to nopdi and there is not a universal package and select the package with higher density.
  if { [ "$density" = "unknown" ] || [ "$density" = "nopdi" ]; } && [ "$dpiapkpath" = "unknown" ] && [ -n "$app_densities" ]; then
    app_densities="$(echo "$app_densities" | sort -r)"
    for densities in $app_densities; do
      dpiapkpath="$1/$densities"
      break
    done
  fi
  # If there is no package for our density nor a universal one, we will look for the one with closer, but higher density.
  if [ "$dpiapkpath" = "unknown" ] && [ -n "$app_densities" ]; then
    app_densities="$(echo "$app_densities" | sort)"
    for densities in $app_densities; do
      all_densities="$(echo "$densities" | sed 's/-/ /g' | tr ' ' '\n' | sort | tr '\n' ' ')"
      for d in $all_densities; do
        if [ "$d" -ge "$density" ]; then
          dpiapkpath="$1/$densities"
          break 2
        fi
      done
    done
  fi
  # If there is no package for our density nor a universal one or one for higher density, we will use the one with closer, but lower density.
  if [ "$dpiapkpath" = "unknown" ] && [ -n "$app_densities" ]; then
    app_densities="$(echo "$app_densities" | sort -r)"
    for densities in $app_densities; do
      all_densities="$(echo "$densities" | sed 's/-/ /g' | tr ' ' '\n' | sort -r | tr '\n' ' ')"
      for d in $all_densities; do
        if [ "$d" -le "$density" ]; then
          dpiapkpath="$1/$densities"
          break 2
        fi
      done
    done
  fi
}

# _____________________________________________________________________________________________________________________
#                                                  Gather Device & GApps Package Information
if [ -z "$(get_prop "ro.build.id")" ]; then
  ui_print "*** No ro.build.id ***"
  ui_print " "
  ui_print "Your ROM has no valid build.prop or equivalent"
  ui_print " "
  ui_print "******* GApps Installation failed *******"
  ui_print " "
  install_note="${install_note}nobuildprop$newline"
  abort "$E_NOBUILDPROP"
fi

testcomprfile="$(find /system -maxdepth 1 -type f  | head -n 1)" #often this should return the build.prop, but it can be any file for this test
# Check if $testcomprfile if it is exists is not compressed and thus unprocessable
if [ -e "$testcomprfile" ] && [ "$(head -c 4 "$testcomprfile")" = "zzzz" ]; then
  ui_print "*** Recovery does not support transparent compression ***"
  ui_print " "
  ui_print "Your ROM uses transparent compression, but your recovery"
  ui_print "does not support this feature, resulting in corrupt files."
  ui_print " "
  ui_print "BEFORE INSTALLING ANYTHING ANYMORE YOU SHOULD UPDATE YOUR"
  ui_print "RECOVERY AS SOON AS POSSIBLE, TO PREVENT FILE CORRUPTION."
  ui_print " "
  ui_print "******* GApps Installation failed *******"
  ui_print " "
  install_note="${install_note}recovery_compression_msg$newline"
  abort "$E_RECCOMPR"
fi

# Get device name any which way we can
for field in ro.product.device ro.build.product ro.product.name; do
  device_name="$(get_prop "$field")"
  if [ "${#device_name}" -ge "2" ]; then
    break
  fi
  device_name="Bad ROM/Recovery"
done

# Locate gapps-config (if used)
for i in "$TMP/aroma/.gapps-config"\
 "$zip_folder/.gapps-config"\
 "$zip_folder/.gapps-config-$device_name"\
 "$zip_folder/.gapps-config-$device_name.txt"\
 "$zip_folder/.gapps-config.txt"\
 "$zip_folder/gapps-config-$device_name.txt"\
 "$zip_folder/gapps-config.txt"\
 "/data/.gapps-config"\
 "/data/.gapps-config-$device_name"\
 "/data/.gapps-config-$device_name.txt"\
 "/data/.gapps-config.txt"\
 "/data/gapps-config-$device_name.txt"\
 "/data/gapps-config.txt"\
 "/persist/.gapps-config"\
 "/persist/.gapps-config-$device_name"\
 "/persist/.gapps-config-$device_name.txt"\
 "/persist/.gapps-config.txt"\
 "/persist/gapps-config-$device_name.txt"\
 "/persist/gapps-config.txt"\
 "/sdcard/.gapps-config"\
 "/sdcard/.gapps-config-$device_name"\
 "/sdcard/.gapps-config-$device_name.txt"\
 "/sdcard/.gapps-config.txt"\
 "/sdcard/gapps-config-$device_name.txt"\
 "/sdcard/gapps-config.txt"\
 "/sdcard/Open-GApps/.gapps-config"\
 "/sdcard/Open-GApps/.gapps-config-$device_name"\
 "/sdcard/Open-GApps/.gapps-config-$device_name.txt"\
 "/sdcard/Open-GApps/.gapps-config.txt"\
 "/sdcard/Open-GApps/gapps-config-$device_name.txt"\
 "/sdcard/Open-GApps/gapps-config.txt"\
 "/tmp/install/.gapps-config"\
 "/tmp/install/.gapps-config-$device_name"\
 "/tmp/install/.gapps-config-$device_name.txt"\
 "/tmp/install/.gapps-config.txt"\
 "/tmp/install/gapps-config-$device_name.txt"\
 "/tmp/install/gapps-config.txt"; do
  if [ -r "$i" ]; then
    g_conf="$i"
    break
  fi
done

# We log in the same directory as the gapps-config file, unless it is aroma
# or adb sideload
if [ -n "$g_conf" ] && [ "$g_conf" != "$TMP/aroma/.gapps-config" ]; then
  log_folder="$(dirname "$g_conf")"
else
  if [ "$zip_folder" = "/sideload" ]; then
    log_folder=/sdcard
  else
    log_folder="$zip_folder"
  fi
fi

if [ "$g_conf" ]; then
  config_file="$g_conf"
  g_conf_orig="$g_conf"
  g_conf="$TMP/proc_gconf"

  sed -r -e 's/\r//g' -e 's|#.*||g' -e 's/^[ \t ]*//g' -e 's/[ \t ]*$//g' -e '/^$/d' "$g_conf_orig" > "$g_conf" # UNIX line-endings, strip comments+emptylines+spaces+tabs

  # include mentioned as a *whole word* (surrounded by space/tabs or start/end or directly followed by a comment) and is itself NOT a comment (should not be possible because of sed above)
  if ( grep -qiE '^([^#]*[[:blank:]]+)?include($|#|[[:blank:]])' "$g_conf" ); then
    config_type="include"
  else
    config_type="exclude"
  fi
  sed -i -r -e 's/\<(in|ex)clude\>//gI' "$g_conf" # drop in/exclude from the config

  user_remove_list=$(awk -F "[()]" '{ for (i=2; i<NF; i+=2) print $i }' "$g_conf") # Get users list of apk's to remove from gapps-config
  sed -i -e s/'([^)]*)'/''/g -e '/^$/d' "$g_conf" # Remove all instances of user app removals (stuff between parentheses) and empty lines we might have created
else
  config_file="Not Used"
  g_conf="$TMP/proc_gconf"
  touch "$g_conf"
fi

# Unless this is a NoDebug install - create folder and take 'Before' snapshots
if ( ! grep -qiE '^nodebug$' "$g_conf" ); then
  install -d $TMP/logs
  ls -alZR /system > $TMP/logs/System_Files_Before.txt
  df -k > $TMP/logs/Device_Space_Before.txt
fi

# Get ROM Android version
ui_print "- Gathering device & ROM information"
ui_print " "

# Get ROM SDK version
rom_build_sdk="$(get_prop "ro.build.version.sdk")"

# Get Device Type
if echo "$(get_prop "ro.build.characteristics")" | grep -qi "tablet"; then
  device_type=tablet
elif echo "$(get_prop "ro.build.characteristics")" | grep -qi "tv"; then
  device_type=tv
  core_gapps_list="$tvcore_gapps_list"  # use the TV core apps instead of the regular core apps
else
  device_type=phone
fi

echo "# Begin Open GApps Install Log" > $g_log
echo ------------------------------------------------------------------ >> $g_log

# Check to make certain user has proper version ROM Installed
if [ ! "$rom_build_sdk" = "$req_android_sdk" ]; then
  ui_print "*** Incompatible Android ROM detected ***"
  ui_print " "
  ui_print "This GApps pkg is for Android $req_android_version.x ONLY"
  ui_print "Please download the correct version for"
  ui_print "your ROM: $(get_prop "ro.build.version.release") (SDK $rom_build_sdk)"
  ui_print " "
  ui_print "******* GApps Installation failed *******"
  ui_print " "
  install_note="${install_note}rom_android_version_msg$newline" # make note that ROM Version is not compatible with these GApps
  abort "$E_ROMVER"
fi

# Check to make certain that user device matches the architecture
device_architecture="$(get_prop "ro.product.cpu.abilist")"
# If the recommended field is empty, fall back to the deprecated one
if [ -z "$device_architecture" ]; then
  device_architecture="$(get_prop "ro.product.cpu.abi")"
fi

case "$device_architecture" in
  *x86_64*) arch="x86_64"; libfolder="lib64";;
  *x86*) arch="x86"; libfolder="lib";;
  *arm64*) arch="arm64"; libfolder="lib64";;
  *armeabi*) arch="arm"; libfolder="lib";;
  *) arch="unknown";;
esac

for targetarch in @ARCH@ abort; do # we add abort as latest entry to detect if there is no match
  if [ "$arch" = "$targetarch" ]; then
    if [ "$libfolder" = "lib64" ]; then #on 64bit we also need to install 32 bit libs from the fbarch
      get_fallback_arch "$arch"
      fbarch="$fallback_arch"
    else
      fbarch=""
    fi
    break
  elif [ "abort" = "$targetarch" ]; then
    ui_print "***** Incompatible Device Detected *****"
    ui_print " "
    ui_print "This Open GApps package cannot be"
    ui_print "installed on this device's architecture."
    ui_print "Please download the correct version for"
    ui_print "your device: $arch"
    ui_print " "
    ui_print "******* GApps Installation failed *******"
    ui_print " "
    install_note="${install_note}arch_compat_msg$newline" # make note that Open GApps are not compatible with architecture
    abort "$E_ARCH"
  fi
done

# Determine Recovery Type and Version
for rec_log in $rec_tmp_log $rec_cache_log; do
  recovery=$(grep -m 2 -E " Recovery v|Starting TWRP|Welcome to|PhilZ|Starting recovery \(" $rec_log)
  case "$recovery" in
    *Welcome*)  recovery="$(grep -m 1 "Welcome to" $rec_log | awk '{ print substr($0, index($0,$3)) }')$(grep -m 1 "^ext.version" $rec_log | cut -d\" -f2)"; break;;
    *Recovery*) recovery=$(grep -m 1 "Recovery v" $rec_log); recovery=${recovery/Recovery v/Recovery }; break;;
    *PhilZ*)    recovery=$(grep -m 2 -E "PhilZ|ClockworkMod" $rec_log); recovery="${recovery/ClockworkMod v/(ClockworkMod })"; break;;
    *Starting\ recovery\ \(*) recovery=$(grep -m 1 "ro.cm.version=" $rec_log| sed -e 's/.*ro.cm.version=/CM Recovery /gI'); break;;
    Starting*) recovery=$(echo "$recovery" | awk -F"Starting " '{ print $2 }' | awk -F" on " '{ print $1 }'); break;;
  esac
done

# Get device model
device_model="$(get_prop "ro.product.model")"

# Get display density
density="$(get_prop "ro.sf.lcd_density")"

# Check for DPI Override in gapps-config
if ( grep -qiE '^forcedpi(120|160|213|240|260|280|300|320|340|360|400|420|480|560|640|nodpi)$' "$g_conf" ); then # user wants to override the DPI selection
  density=$( grep -iEo '^forcedpi(120|160|213|240|260|280|300|320|340|360|400|420|480|560|640|nodpi)$' "$g_conf" | tr '[:upper:]'  '[:lower:]' )
  density=${density#forcedpi}
fi

# Set density to unknown if it's still empty
[ -z "$density" ] && density="unknown"

# Check for Camera API v2 availability
cameraapi="$(get_prop "camera2.portability.force_api")"
camerahal="$(get_prop "persist.camera.HAL3.enabled")"
if ( grep -qiE '^forcenewcamera$' "$g_conf" ); then  # takes precedence over any detection
  newcamera_compat="true[forcenewcamera]"
else
  if [ -n "$cameraapi" ]; then  # we check first for the existence of this key, it takes precedence if set to any value
    if [ "$cameraapi" -ge "2" ]; then
      newcamera_compat="true[force_api]"
    else
      newcamera_compat="false[force_api]"
    fi
  elif [ -n "$camerahal" ] && [ "$camerahal" -ge "1" ]; then
    newcamera_compat="true"
  else
    # If not explictly defined, check whitelist
    case $device_name in
      ryu|angler|bullhead|shamu|volantis*|flounder*|hammerhead*|sprout*) newcamera_compat="true[whitelist]";;
      *) newcamera_compat="false";;
    esac
  fi
fi

cmcompatibilityhacks="false"  # test for CM/Lineage since they do weird AOSP-breaking changes to their code, breaking some GApps
case "$(get_prop "ro.build.flavor")" in
  cm_*|lineage_*)
  if [ "$rom_build_sdk" -lt "27" ]; then
    cmcompatibilityhacks="true"
  fi
  if [ "$rom_build_sdk" -ge "24" ]; then # CMSetupWizard is broken in LineageOS 14+ and can be safely removed on CM14+ as well
    aosp_remove_list="${aosp_remove_list}cmsetupwizard$newline"
  fi;;
esac

# Check for Clean Override in gapps-config
if ( grep -qiE '^forceclean$' "$g_conf" ); then
  forceclean="true"
else
  forceclean="false"
fi

# Check for skipswypelibs in gapps-config
if ( grep -qiE '^skipswypelibs$' $g_conf ); then
  skipswypelibs="true"
else
  skipswypelibs="false"
fi

# Check for substituteswypelibs in gapps-config
if ( grep -qiE '^substituteswypelibs$' $g_conf ); then
  substituteswypelibs="true"
else
  substituteswypelibs="false"
fi

# Check for skipvendorlibs in gapps-config
if ( grep -qiE '^skipvendorlibs$' $g_conf ); then
  skipvendorlibs="true"
  mount -t tmpfs tmpfs /system/vendor  # by mounting a tmpfs on this location, we hide the existing files from any operations
else
  skipvendorlibs="false"
fi

# Remove any files from gapps-remove.txt that should not be processed for automatic removal
for bypass_file in $removal_bypass_list; do
  sed -i "\:${bypass_file}:d" $gapps_removal_list
done

# Is this a 'Clean' or 'Dirty' install
if ( clean_inst ); then
  install_type="Clean[Data Wiped]"
  cameragoogle_inst=Clean
else
  install_type="Dirty[Data NOT Wiped]"

  # Was Google Camera previously installed (in /system)
  if ( sys_app GoogleCamera ); then
    cameragoogle_inst=true
  else
    cameragoogle_inst=false
  fi
fi

# Is device VRMode compatible
vrmode_compat=false
for xml in $(grep -rl '<feature name="android.software.vr.mode" />' /system/etc/ /system/product/etc/ /system/vendor/etc/ 2>/dev/null); do
  if ( awk -vRS='-->' '{ gsub(/<!--.*/,"")}1' $xml | grep -qr '<feature name="android.software.vr.mode" />' /system/etc/ /system/product/etc/ /system/vendor/etc/ ); then
    vrmode_compat=true
    break
  fi
done

# Check device name for devices that are incompatible with Google Camera
case $device_name in
#in kitkat we don't have google camera compatibility with some phones
@cameracompatibilityhack@
  *) cameragoogle_compat=true;;
esac

# Check if Google Pixel
case $device_name in
  marlin|sailfish|walleye|taimen|crosshatch|blueline|bonito|sargo|coral|flame|sunfish) googlepixel_compat="true";;
  *) googlepixel_compat="false";;
esac

log "ROM Android version" "$(get_prop "ro.build.version.release")"
log "ROM Build ID" "$(get_prop "ro.build.display.id")"
log "ROM Version increment" "$(get_prop "ro.build.version.incremental")"
log "ROM SDK version" "$rom_build_sdk"
log "ROM/Recovery modversion" "$(get_prop "ro.modversion")"
log "Device Recovery" "$recovery"
log "Device Name" "$device_name"
log "Device Model" "$device_model"
log "Device Type" "$device_type"
log "Device CPU" "$device_architecture"
log "Device A/B-partitions" "$device_abpartition"
log "Installer Platform" "$BINARCH"
log "ROM Platform" "$arch"
log "Display Density Used" "$density"
log "Install Type" "$install_type"
log "Google Camera already installed" "$cameragoogle_inst"
log "VRMode Compatible" "$vrmode_compat"
log "Google Camera Compatible" "$cameragoogle_compat"
log "New Camera API Compatible" "$newcamera_compat"
log "Google Pixel Features" "$googlepixel_compat"

# Determine if a GApps package is installed and
# the version, type, and whether it's an Open GApps package
if [ -e "/system/priv-app/GoogleServicesFramework/GoogleServicesFramework.apk" ] || [ -e "/system/product/priv-app/GoogleServicesFramework/GoogleServicesFramework.apk" ] || [ -e "/system/priv-app/GoogleServicesFramework.apk" ] || [ -e "/system/product/priv-app/GoogleServicesFramework.apk" ]; then
  openversion="$(get_prop "ro.addon.open_version")"
  if [ -n "$openversion" ]; then
    log "Current GApps Version" "$openversion"
    opentype="$(get_prop "ro.addon.open_type")"
    if [ -z "$opentype" ]; then
      opentype="unknown"
    fi
    log "Current Open GApps Package" "$opentype"
  elif [ -e "/system/etc/g.prop" ]; then
    log "Current GApps Version" "NON Open GApps Package Currently Installed (FAILURE)"
    ui_print "* Incompatible GApps Currently Installed *"
    ui_print " "
    ui_print "This Open GApps package can ONLY be installed"
    ui_print "on top of an existing installation of Open GApps"
    ui_print "or a clean AOSP/CyanogenMod ROM installation,"
    ui_print "or a Stock ROM that conforms to Nexus standards."
    ui_print "You must wipe (format) your system partition"
    ui_print "and flash your ROM BEFORE installing Open GApps."
    ui_print " "
    ui_print "******* GApps Installation failed *******"
    ui_print " "
    install_note="${install_note}non_open_gapps_msg$newline"
    abort "$E_NONOPEN"
  else
    log "Current GApps Version" "Stock ROM GApps Currently Installed (NOTICE)"
    ui_print "* Stock ROM GApps Currently Installed *"
    ui_print " "
    ui_print "The installer detected that Stock ROM GApps are"
    ui_print "already installed. If you are flashing over a"
    ui_print "Nexus-compatible ROM there is no problem, but if"
    ui_print "you are flashing over a custom ROM, you may want"
    ui_print "to contact the developer to request the removal of"
    ui_print "the included GApps. The installation will now"
    ui_print "continue, but please be aware that any problems"
    ui_print "that may occur depend on your ROM."
    ui_print " "
    install_note="${install_note}fornexus_open_gapps_msg$newline"
  fi
else
  # User does NOT have a GApps package installed on their device
  log "Current GApps Version" "No GApps Installed"

  # Did this 6.0+ system already boot and generated runtime permissions
  if [ -e /data/system/users/0/runtime-permissions.xml ]; then
    # Check if permissions were granted to Google Setupwizard, this permissions should always be set in the file if GApps were installed before
    if ! grep -q "com.google.android.setupwizard" /data/system/users/*/runtime-permissions.xml; then
      # Purge the runtime permissions to prevent issues if flashing GApps for the first time on a dirty install
      rm -f /data/system/users/*/runtime-permissions.xml
      log "Runtime Permissions" "Reset"
    fi
  fi

  # Use the opportunity of No GApps installed to check for potential ROM conflicts when deleting existing GApps files
  while read gapps_file; do
    if [ -e "$gapps_file" ] && [ "$gapps_file" != "/system/lib/$WebView_lib_filename" ] && [ "$gapps_file" != "/system/lib64/$WebView_lib_filename" ]; then
      echo "$gapps_file" >> $conflicts_log
    fi
  done < $gapps_removal_list
fi

# _____________________________________________________________________________________________________________________
#                                                  Prepare the list of GApps being installed and AOSP/Stock apps being removed
# Build list of available GApps that can be installed (and check for a user package preset)
for pkg in $pkg_names; do
  eval "addto=\$${pkg}_gapps_list" # Look for method to combine this with line below
  all_gapps_list=${all_gapps_list}${addto} # Look for method to combine this with line above
  if ( grep -qiE "^${pkg}gapps\$" "$g_conf" ); then # user has selected a 'preset' install
    gapps_type=$pkg
    sed -i "/ro.addon.open_type/c\ro.addon.open_type=$pkg" "$TMP/g.prop" # modify g.prop to new package type
    break
  fi
done

# Prepare list of User specified GApps that will be installed
if [ "$g_conf" ]; then
  if [ "$config_type" = "include" ]; then # User is indicating the apps they WANT installed
    for gapp_name in $all_gapps_list; do
      if ( grep -qiE "^$gapp_name\$" "$g_conf" ); then
        gapps_list="$gapps_list$gapp_name$newline"
      fi
    done
  else # User is indicating the apps they DO NOT WANT installed
    for gapp_name in $all_gapps_list; do
      if ( ! grep -qiE "^$gapp_name\$" "$g_conf" ); then
        gapps_list="$gapps_list$gapp_name$newline"
      fi
    done
  fi
else # User is not using a gapps-config and we're doing the 'full monty'
  config_type="[Default]"
  gapps_list=$all_gapps_list
fi

# Configure default removal of Stock/AOSP apps - if we're installing Stock GApps or larger
if [ "$gapps_type" = "super" ] || [ "$gapps_type" = "stock" ] || [ "$gapps_type" = "aroma" ]; then
  for default_name in $default_stock_remove_list; do
    eval "remove_${default_name}=true[default]"
  done
else
  # Do not perform any default removals - but make them optional
  for default_name in $default_stock_remove_list; do
    eval "remove_${default_name}=false[default]"
  done
fi

# Prepare list of AOSP/ROM files that will be deleted using gapps-config
# We will look for +Browser, +CameraStock, +DialerStock, +Email, +Gallery, +Launcher, +MMS, +PicoTTS and more to prevent their removal
set_progress 0.03
if [ "$g_conf" ]; then
  for default_name in $default_stock_remove_list; do
    if ( grep -qiE "^\+$default_name\$" "$g_conf" ); then
      eval "remove_${default_name}=false[gapps-config]"
    elif [ "$gapps_type" = "super" ] || [ "$gapps_type" = "stock" ] || [ "$gapps_type" = "aroma" ]; then
      aosp_remove_list="$aosp_remove_list$default_name$newline"
      if ( grep -qiE "^$default_name\$" "$g_conf" ); then
        eval "remove_${default_name}=true[gapps-config]"
      fi
    else
      if ( grep -qiE "^$default_name\$" "$g_conf" ); then
        eval "remove_${default_name}=true[gapps-config]"
        aosp_remove_list="$aosp_remove_list$default_name$newline"
      fi
    fi
  done
  # Check gapps-config for other optional AOSP/ROM files that will be deleted
  for opt_name in $optional_aosp_remove_list; do
    if ( grep -qiE "^$opt_name\$" "$g_conf" ); then
      aosp_remove_list="$aosp_remove_list$opt_name$newline"
    fi
  done
else
  if [ "$gapps_type" = "super" ] || [ "$gapps_type" = "stock" ] || [ "$gapps_type" = "aroma" ]; then
      aosp_remove_list=$default_stock_remove_list
  fi
fi

# Provision folder always has to be removed (it conflicts with SetupWizard)
aosp_remove_list="${aosp_remove_list}provision$newline"
# Remove AOSP Android Shared Services in favour of our Google versions of it
aosp_remove_list="${aosp_remove_list}extsharedstock${newline}extservicesstock$newline"

# WebViewProvider rules differ Pre-Nougat and Nougat+
@webviewcheckhack@

# Cyanogenmod breaks Google's PackageInstaller don't install it on CM
if ( contains "$gapps_list" "packageinstallergoogle" ) && [ $cmcompatibilityhacks = "true" ]; then
  gapps_list=${gapps_list/packageinstallergoogle}
  install_note="${install_note}cmcompatibility_msg$newline" # make note that CM compatibility hacks are applied
fi

# Add Google Pixel config if this is a Pixel device (and remove if it is not)
if ( ! contains "$gapps_list" "googlepixelconfig" ) && [ $googlepixel_compat = "true" ]; then
  gapps_list="${gapps_list}googlepixelconfig$newline"
fi
if ( contains "$gapps_list" "googlepixelconfig" ) && [ $googlepixel_compat = "false" ]; then
  gapps_list=${gapps_list/googlepixelconfig}
fi

# If we're NOT installing chrome make certain 'browser' is NOT in $aosp_remove_list UNLESS 'browser' is in $g_conf
if ( ! contains "$gapps_list" "chrome" ) && ( ! grep -qiE '^browser$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/browser}
  remove_browser="false[NO_Chrome]"
fi

# If we're NOT installing gmail make certain 'email' is NOT in $aosp_remove_list UNLESS 'email' is in $g_conf
if ( ! contains "$gapps_list" "gmail" ) && ( ! grep -qiE '^email$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/email}
  remove_email="false[NO_Gmail]"
fi

# If we're NOT installing photos make certain 'gallery' is NOT in $aosp_remove_list UNLESS 'gallery' is in $g_conf
if ( ! contains "$gapps_list" "photos" ) && ( ! grep -qiE '^gallery$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/gallery}
  remove_gallery="false[NO_Photos]"
fi

# If $device_type is not a 'phone' make certain we're not installing messenger
if ( contains "$gapps_list" "messenger" ) && [ $device_type != "phone" ]; then
  gapps_list=${gapps_list/messenger} # we'll prevent messenger from being installed since this isn't a phone
fi

# If $device_type is not a 'phone' make certain we're not installing carrierservices (this is essential for messenger)
if ( contains "$gapps_list" "carrierservices" ) && [ $device_type != "phone" ]; then
  gapps_list=${gapps_list/carrierservices} # we'll prevent carrierservices from being installed since this isn't a phone
fi

# If $device_type is not a 'phone' make certain we're not installing dialerframework (implies no dialergoogle)
if ( contains "$gapps_list" "dialerframework" ) && [ $device_type != "phone" ]; then
  gapps_list=${gapps_list/dialerframework} # we'll prevent dialerframework from being installed since this isn't a phone
fi

# If we're NOT installing dialerframework then we MUST REMOVE dialergoogle from  $gapps_list (if it's currently there)
if ( ! contains "$gapps_list" "dialerframework" ) && ( contains "$gapps_list" "dialergoogle" ); then
  gapps_list=${gapps_list/dialergoogle}
  install_note="${install_note}dialergoogle_msg$newline" # make note that Google Dialer will NOT be installed as user requested
fi

# If we're NOT installing dialergoogle make certain 'dialerstock' is NOT in $aosp_remove_list UNLESS 'dialerstock' is in $g_conf
if ( ! contains "$gapps_list" "dialergoogle" ) && ( ! grep -qiE '^dialerstock$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/dialerstock}
  remove_dialerstock="false[NO_DialerGoogle]"
fi

# If we're NOT installing carrier services then we MUST REMOVE messenger from $gapps_list (if it's currently there)
if [ "$rom_build_sdk" -ge "23" ] && ( ! contains "$gapps_list" "carrierservices" ) && ( contains "$gapps_list" "messenger" ); then
  gapps_list=${gapps_list/messenger}
  install_note="${install_note}messenger_msg$newline" # make note that Google Messages will NOT be installed as user requested
fi

# If we're NOT installing messenger make certain 'mms' is NOT in $aosp_remove_list UNLESS 'mms' is in $g_conf
if ( ! contains "$gapps_list" "messenger" ) && ( ! grep -qiE '^mms$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/mms}
  remove_mms="false[NO_Messenger]"
fi

# If we're NOT installing messenger and mms is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "messenger" ) && ( contains "$aosp_remove_list" "mms" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/mms} # we'll prevent mms from being removed so user isn't left with no way to receive text messages
  remove_mms="false[NO_Override]"
  install_note="${install_note}nomms_msg$newline" # make note that MMS can't be removed unless user Overrides
fi

# If we're NOT installing googletts make certain 'picotts' is NOT in $aosp_remove_list UNLESS 'picotts' is in $g_conf
if ( ! contains "$gapps_list" "googletts" ) && ( ! grep -qiE '^picotts$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/picotts}
  remove_picotts="false[NO_GoogleTTS]"
fi

# If we're NOT installing wallpapers then we MUST REMOVE pixellauncher from  $gapps_list (if it's currently there)
if ( ! contains "$gapps_list" "wallpapers" ) && ( contains "$gapps_list" "pixellauncher" ); then
  gapps_list=${gapps_list/pixellauncher}
  install_note="${install_note}pixellauncher_msg$newline" # make note that Google Now Launcher will NOT be installed as user requested
fi

# If we're NOT installing search then we MUST REMOVE pixellauncher from  $gapps_list (if it's currently there)
if ( ! contains "$gapps_list" "search" ) && ( contains "$gapps_list" "pixellauncher" ); then
  gapps_list=${gapps_list/pixellauncher}
  install_note="${install_note}pixellauncher_msg$newline" # make note that Pixel Launcher will NOT be installed as user requested
fi

# If we're NOT installing search then we MUST REMOVE googlenow from  $gapps_list (if it's currently there)
if ( ! contains "$gapps_list" "search" ) && ( contains "$gapps_list" "googlenow" ); then
  gapps_list=${gapps_list/googlenow}
  install_note="${install_note}googlenow_msg$newline" # make note that Google Now Launcher will NOT be installed as user requested
fi

# If we're installing tvlauncher we MUST ADD tvlaunch to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "tvlauncher" ) && ( ! contains "$aosp_remove_list" "tvlaunch" ); then
  aosp_remove_list="${aosp_remove_list}tvlaunch$newline"
fi

# If we're NOT installing googlenow or pixellauncher make certain 'launcher' is NOT in $aosp_remove_list UNLESS 'launcher' is in $g_conf
if ( ! contains "$gapps_list" "googlenow" ) && ( ! contains "$gapps_list" "pixellauncher" ) && ( ! grep -qiE '^launcher$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/launcher}
  remove_launcher="false[NO_GoogleNow/PixelLauncher]"
fi

# If we're NOT installing googlenow or pixellauncher and launcher is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "googlenow" ) && ( ! contains "$gapps_list" "pixellauncher" ) && ( contains "$aosp_remove_list" "launcher" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/launcher} # we'll prevent launcher from being removed so user isn't left with no Launcher
  remove_launcher="false[NO_Override]"
  install_note="${install_note}nolauncher_msg$newline" # make note that Launcher can't be removed unless user Overrides
fi

@launcherhack@

# If we're installing calendargoogle we must ADD calendarstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "calendargoogle" ) && ( ! contains "$aosp_remove_list" "calendarstock" ); then
  aosp_remove_list="${aosp_remove_list}calendarstock$newline"
fi

# If we're installing calendargoogle we must NOT install calsync
if ( contains "$gapps_list" "calendargoogle" ); then
  gapps_list=${gapps_list/calsync}
fi

# If we're installing keyboardgoogle we must ADD keyboardstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "keyboardgoogle" ) && ( ! contains "$aosp_remove_list" "keyboardstock" ); then
  aosp_remove_list="${aosp_remove_list}keyboardstock$newline"
fi

# If we're NOT installing keyboardgoogle and keyboardstock is in $aosp_remove_list then user must override removal protection
if ( ! contains "$gapps_list" "keyboardgoogle" ) && ( contains "$aosp_remove_list" "keyboardstock" ) && ( ! grep -qi "override" "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/keyboardstock} # we'll prevent keyboardstock from being removed so user isn't left with no keyboard
  install_note="${install_note}nokeyboard_msg$newline" # make note that Stock Keyboard can't be removed unless user Overrides
fi

# Verify device is Google Camera compatible BEFORE we allow it in $gapps_list
if ( contains "$gapps_list" "cameragoogle" ) && [ $cameragoogle_compat = "false" ]; then
  gapps_list=${gapps_list/cameragoogle} # we must DISALLOW cameragoogle from being installed
  install_note="${install_note}camera_compat_msg$newline" # make note that Google Camera will NOT be installed as user requested
fi

# If user wants to install cameragoogle then it MUST be a Clean Install OR cameragoogle was previously installed in system partition
if ( contains "$gapps_list" "cameragoogle" ) && ( ! clean_inst ) && [ $cameragoogle_inst = "false" ]; then
  gapps_list=${gapps_list/cameragoogle} # we must DISALLOW cameragoogle from being installed
  aosp_remove_list=${aosp_remove_list/camerastock} # and we'll prevent camerastock from being removed so user isn't left with no camera
  install_note="${install_note}camera_sys_msg$newline" # make note that Google Camera will NOT be installed as user requested
fi

# If we're NOT installing cameragoogle make certain 'camerastock' is NOT in $aosp_remove_list UNLESS 'camerastock' is in $g_conf
if ( ! contains "$gapps_list" "cameragoogle" ) && ( ! grep -qiE '^camerastock$' "$g_conf" ); then
  aosp_remove_list=${aosp_remove_list/camerastock}
  remove_camerastock="false[NO_CameraGoogle]"
fi

# Verify device is VRMode compatible, BEFORE we allow vrservice in $gapps_list
if ( contains "$gapps_list" "vrservice" ) && [ "$vrmode_compat" = "false" ]; then
  gapps_list=${gapps_list/vrservice} # we must DISALLOW vrservice from being installed
  install_note="${install_note}vrservice_compat_msg$newline" # make note that VRService will NOT be installed as user requested
fi

# If we're installing clockgoogle we must ADD clockstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "clockgoogle" ) && ( ! contains "$aosp_remove_list" "clockstock" ); then
  aosp_remove_list="${aosp_remove_list}clockstock$newline"
fi

# If we're installing exchangegoogle we must ADD exchangestock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "exchangegoogle" ) && ( ! contains "$aosp_remove_list" "exchangestock" ); then
  aosp_remove_list="${aosp_remove_list}exchangestock$newline"
fi

# If we're installing printservicegoogle we must ADD printservicestock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "printservicegoogle" ) && ( ! contains "$aosp_remove_list" "printservicestock" ); then
  aosp_remove_list="${aosp_remove_list}printservicestock$newline"
fi

# If we're installing storagemanagergoogle we must ADD storagemanagerstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "storagemanagergoogle" ) && ( ! contains "$aosp_remove_list" "storagemanagerstock" ); then
  aosp_remove_list="${aosp_remove_list}storagemanagerstock$newline"
fi

# If we're installing taggoogle we must ADD tagstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "taggoogle" ) && ( ! contains "$aosp_remove_list" "tagstock" ); then
  aosp_remove_list="${aosp_remove_list}tagstock$newline"
fi

# If we're installing calculatorgoogle we MUST ADD calculatorstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "calculatorgoogle" ) && ( ! contains "$aosp_remove_list" "calculatorstock" ); then
  aosp_remove_list="${aosp_remove_list}calculatorstock$newline"
fi

# If we're installing contactsgoogle we MUST ADD contactsstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "contactsgoogle" ) && ( ! contains "$aosp_remove_list" "contactsstock" ); then
  aosp_remove_list="${aosp_remove_list}contactsstock$newline"
fi

# If we're installing packageinstallergoogle we MUST ADD packageinstallerstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "packageinstallergoogle" ) && ( ! contains "$aosp_remove_list" "packageinstallerstock" ); then
  aosp_remove_list="${aosp_remove_list}packageinstallerstock$newline"
fi

# If we're NOT installing gcs then we MUST REMOVE projectfi from  $gapps_list (if it's currently there)
if ( ! contains "$gapps_list" "gcs" ) && ( contains "$gapps_list" "projectfi" ); then
  gapps_list=${gapps_list/projectfi}
  install_note="${install_note}projectfi_msg$newline" # make note that Project Fi will NOT be installed as user requested
fi

# If we're installing wallpapers we must ADD wallpapersstock to $aosp_remove_list (if it's not already there)
if ( contains "$gapps_list" "wallpapers" ) && ( ! contains "$aosp_remove_list" "wallpapersstock" ); then
  aosp_remove_list="${aosp_remove_list}wallpapersstock$newline"
fi

# Some ROMs bundle Google Apps or the user might have installed a Google replacement app during an earlier install
# Some of these apps are crucial to a functioning system and should NOT be removed if no AOSP/Stock equivalent is available
# Unless override keyword is used, make sure they are not removed
# NOTICE: Only for Google Keyboard we need to take KitKat support into account, others are only Lollipop+
ignoregooglecontacts="true"
for f in $contactsstock_list; do
  if [ -e "/system/$f" ] || [ -e "/system/product/$f" ]; then
    ignoregooglecontacts="false"
    break #at least 1 aosp stock file is present
  fi
done
if [ "$ignoregooglecontacts" = "true" ]; then
  if ( ! contains "$gapps_list" "contactsgoogle" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
    sed -i "\:/system/priv-app/GoogleContacts:d" $gapps_removal_list
    sed -i "\:/system/product/priv-app/GoogleContacts:d" $gapps_removal_list
    ignoregooglecontacts="true[NoRemove]"
    install_note="${install_note}nogooglecontacts_removal_msg$newline" # make note that Google Contacts will not be removed
  else
    ignoregooglecontacts="false[ContactsGoogle]"
  fi
fi

ignoregoogledialer="true"
for f in $dialerstock_list; do
  if [ -e "/system/$f" ] || [ -e "/system/product/$f" ]; then
    ignoregoogledialer="false"
    break #at least 1 aosp stock file is present
  fi
done
if [ "$ignoregoogledialer" = "true" ]; then
  if ( ! contains "$gapps_list" "dialergoogle" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
    sed -i "\:/system/priv-app/GoogleDialer:d" $gapps_removal_list
    sed -i "\:/system/product/priv-app/GoogleDialer:d" $gapps_removal_list
    ignoregoogledialer="true[NoRemove]"
    install_note="${install_note}nogoogledialer_removal_msg$newline" # make note that Google Dialer will not be removed
  else
    ignoregoogledialer="false[DialerGoogle]"
  fi
fi

ignoregooglekeyboard="true"
for f in $keyboardstock_list; do
  if [ -e "/system/$f" ] || [ -e "/system/product/$f" ]; then
    ignoregooglekeyboard="false"
    break #at least 1 aosp stock file is present
  fi
done
if [ "$ignoregooglekeyboard" = "true" ]; then
  if ( ! contains "$gapps_list" "keyboardgoogle" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
@keyboardgooglenotremovehack@
    ignoregooglekeyboard="true[NoRemove]"
    install_note="${install_note}nogooglekeyboard_removal_msg$newline" # make note that Google Keyboard will not be removed
  else
    ignoregooglekeyboard="false[KeyboardGoogle]"
  fi
fi

ignoregooglepackageinstaller="true"
for f in $packageinstallerstock_list; do
  if [ -e "/system/$f" ] || [ -e "/system/product/$f" ]; then
    ignoregooglepackageinstaller="false"
    break #at least 1 aosp stock file is present
  fi
done
if [ "$ignoregooglepackageinstaller" = "true" ]; then
  if ( ! contains "$gapps_list" "packageinstallergoogle" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
    sed -i "\:/system/priv-app/GooglePackageInstaller:d" $gapps_removal_list
    sed -i "\:/system/product/priv-app/GooglePackageInstaller:d" $gapps_removal_list
    ignoregooglepackageinstaller="true[NoRemove]"
    install_note="${install_note}nogooglepackageinstaller_removal_msg$newline" # make note that Google Package Installer will not be removed
  else
    ignoregooglepackageinstaller="false[PackageInstallerGoogle]"
  fi
fi

ignoregoogletag="true"
for f in $tagstock_list; do
  if [ -e "/system/$f" ] || [ -e "/system/product/$f" ]; then
    ignoregoogletag="false"
    break #at least 1 aosp stock file is present
  fi
done
if [ "$ignoregoogletag" = "true" ]; then
  if ( ! contains "$gapps_list" "taggoogle" ) && ( ! grep -qiE '^override$' "$g_conf" ); then
    sed -i "\:/system/priv-app/TagGoogle:d" $gapps_removal_list
    sed -i "\:/system/product/priv-app/TagGoogle:d" $gapps_removal_list
    ignoregoogletag="true[NoRemove]"
    install_note="${install_note}nogoogletag_removal_msg$newline" # make note that Google Tag will not be removed
  else
    ignoregoogletag="false[TagGoogle]"
  fi
fi

ignoregooglewebview="true"
for f in $webviewstock_list; do
  if [ -e "/system/$f" ] || [ -e "/system/product/$f" ]; then
    ignoregooglewebview="false"
    break #at least 1 aosp stock file is present
  fi
done
# in Nougat Chrome and WebViewStub can also be used as WebViewProvider
@webviewignorehack@
# in Marshmallow we need to use the legacy camera that uses the older api
@camerav3compatibilityhack@

# Process User Application Removals for calculations and subsequent removal
if [ -n "$user_remove_list" ]; then
  for remove_apk in $user_remove_list; do
    testapk=$( echo "$remove_apk" | tr '[:upper:]'  '[:lower:]' )
    # Add apk extension if user didn't include it
    case $testapk in
      *".apk" ) ;;
      * )       testapk="${testapk}.apk" ;;
    esac
    # Create user_remove_folder_list if this is a system/ROM application
    for folder in /system/app /system/product/app /system/priv-app /system/product/priv-app; do # Check all subfolders of system app/priv-app folders for the apks
      file_count=0 # Reset Counter
      file_count=$(find $folder -iname "$testapk" 2>/dev/null | wc -l)
      case $file_count in
        0)  continue;;
#on kitkat the paths for the universalremover are different
@universalremoverhack@
            break;;
        *)  echo "$remove_apk" >> $user_remove_multiplefound_log # Add app to user_remove_multiplefound_log since we found more than 1 instance
            break;;
      esac
    done
    if [ "$file_count" -eq 0 ]; then
      echo "$remove_apk" >> $user_remove_notfound_log
    fi # Add 'not found' app to user_remove_notfound_log
  done
fi

# Removing old Chrome libraries
obsolete_libs_list=""
for f in $(find /system/lib /system/product/lib /system/lib64 /system/product/lib64 -name 'libchrome.*.so' 2>/dev/null); do
  obsolete_libs_list="${obsolete_libs_list}$f$newline"
done

# Read in gapps removal list from file and append old Chrome libs
full_removal_list="$(cat $gapps_removal_list)$newline${obsolete_libs_list}"

# Read in old user removal list from addon.d to allow for persistence
addond_remove_folder_list=$(sed -e "1,/# Remove 'user requested' apps (from gapps-config)/d" -e '/;;/,$d' -e 's/    rm -rf //' /system/addon.d/70-gapps.sh)

# Clean up and sort our lists for space calculations and installation
set_progress 0.04
gapps_list=$(echo "${gapps_list}" | sort | sed '/^$/d') # sort GApps list & remove empty lines
aosp_remove_list=$(echo "${aosp_remove_list}" | sort | sed '/^$/d') # sort AOSP Remove list & remove empty lines
full_removal_list=$(echo "${full_removal_list}" | sed '/^$/d') # Remove empty lines from FINAL GApps Removal list
remove_list=$(echo "${remove_list}" | sed '/^$/d') # Remove empty lines from remove_list
user_remove_folder_list=$(echo "${user_remove_folder_list}" | sed '/^$/d') # Remove empty lines from User Application Removal list

log "Installing GApps Zipfile" "$OPENGAZIP"
log "Installing GApps Version" "$gapps_version"
log "Installing GApps Type" "$gapps_type"
log "Config Type" "$config_type"
log "Using gapps-config" "$config_file"
log "Remove Stock/AOSP Browser" "$remove_browser"
log "Remove Stock/AOSP Camera" "$remove_camerastock"
log "Remove Stock/AOSP Dialer" "$remove_dialerstock"
log "Remove Stock/AOSP Email" "$remove_email"
log "Remove Stock/AOSP Gallery" "$remove_gallery"
log "Remove Stock/AOSP Launcher" "$remove_launcher"
log "Remove Stock/AOSP MMS App" "$remove_mms"
log "Remove Stock/AOSP Pico TTS" "$remove_picotts"
log "Ignore Google Contacts" "$ignoregooglecontacts"
log "Ignore Google Dialer" "$ignoregoogledialer"
log "Ignore Google Keyboard" "$ignoregooglekeyboard"
log "Ignore Google Package Installer" "$ignoregooglepackageinstaller"
log "Ignore Google NFC Tag" "$ignoregoogletag"
log "Ignore Google WebView" "$ignoregooglewebview"

# _____________________________________________________________________________________________________________________
#                                                  Perform space calculations
ui_print "- Performing system space calculations"
ui_print " "

# Perform calculations of core applications
core_size=0
for gapp_name in $core_gapps_list; do
  get_apparchives "Core/$gapp_name"
  for archive in $apparchives; do
    case $gapp_name in
      setupwizarddefault) if [ "$device_type" != "tablet" ]; then get_appsize "$archive"; fi;;
      setupwizardtablet)  if [ "$device_type"  = "tablet" ]; then get_appsize "$archive"; fi;;
      backuprestore) if [ "$googlepixel_compat" = "false" ]; then get_appsize "$archive"; fi;;
      datatransfertool) if [ "$googlepixel_compat" = "true" ]; then get_appsize "$archive"; fi;;
      *) get_appsize "$archive";;
    esac
    core_size=$((core_size + appsize))
  done
done

# Add swypelibs size to core, if it will be installed
if ( ! contains "$gapps_list" "keyboardgoogle" ) || [ "$skipswypelibs" = "false" ]; then
  get_appsize "Optional/swypelibs-lib-$arch"  # Keep it simple, swypelibs is only lib-$arch
  core_size=$((core_size + keybd_lib_size))  # Add Keyboard Lib size to core, if it exists
fi

# Read and save system partition size details
df=$(df -k /system | tail -n 1)
case $df in
  /dev/block/*) df=$(echo "$df" | awk '{ print substr($0, index($0,$2)) }');;
esac
total_system_size_kb=$(echo "$df" | awk '{ print $1 }')
used_system_size_kb=$(echo "$df" | awk '{ print $2 }')
free_system_size_kb=$(echo "$df" | awk '{ print $3 }')
log "Total System Size (KB)" "$total_system_size_kb"
log "Used System Space (KB)" "$used_system_size_kb"
log "Current Free Space (KB)" "$free_system_size_kb"

# Perform storage space calculations of existing GApps that will be deleted/replaced
reclaimed_gapps_space_kb=$(du -ck $(complete_gapps_list) | tail -n 1 | awk '{ print $1 }')

# Perform storage space calculations of other Removals that need to be deleted (Obsolete and Conflicting Apps)
set_progress 0.05
reclaimed_removal_space_kb=$(du -ck $(obsolete_gapps_list) | tail -n 1 | awk '{ print $1 }')

# Add information to calc.log that will later be added to open_gapps.log to assist user with app removals
post_install_size_kb=$((free_system_size_kb + reclaimed_gapps_space_kb)) # Add opening calculations
echo ------------------------------------------------------------------ > $calc_log
printf "%7s | %26s |   %7s | %7s\n" "TYPE " "DESCRIPTION       " "SIZE" "  TOTAL" >> $calc_log
printf "%7s | %26s |   %7d | %7d\n" "" "Current Free Space" "$free_system_size_kb" "$free_system_size_kb" >> $calc_log
printf "%7s | %26s | + %7d | %7d\n" "Remove" "Existing GApps" "$reclaimed_gapps_space_kb" $post_install_size_kb >> $calc_log
post_install_size_kb=$((post_install_size_kb + reclaimed_removal_space_kb)) # Add reclaimed_removal_space_kb
printf "%7s | %26s | + %7d | %7d\n" "Remove" "Obsolete Files" "$reclaimed_removal_space_kb" $post_install_size_kb >> $calc_log

# Perform calculations of AOSP/ROM files that will be deleted
set_progress 0.07
for aosp_name in $aosp_remove_list; do
  eval "list_name=\$${aosp_name}_list"
  aosp_size_kb=0 # Reset counter
  for file_name in $list_name; do
    for file_folder in "/system" "/system/product"; do
      if [ -d "$file_folder" ] && [ -e "$file_folder/$file_name" ]; then
        file_size_kb=$(du -ck "$file_folder/$file_name" | tail -n 1 | awk '{ print $1 }')
        aosp_size_kb=$((file_size_kb + aosp_size_kb))
        post_install_size_kb=$((post_install_size_kb + file_size_kb))
      fi
    done
  done
  log_add "Remove" "$aosp_name" $aosp_size_kb $post_install_size_kb
done

# Perform calculations of User App Removals that will be deleted
for remove_folder in $user_remove_folder_list; do
  if [ -e "$remove_folder" ]; then
    folder_size_kb=$(du -ck "$remove_folder" | tail -n 1 | awk '{ print $1 }')
    post_install_size_kb=$((post_install_size_kb + folder_size_kb))
    log_add "Remove" "$(basename "$remove_folder")*" "$folder_size_kb" $post_install_size_kb
  fi
done

# Perform calculations of GApps files that will be installed
set_progress 0.09
post_install_size_kb=$((post_install_size_kb - core_size)) # Add Core GApps
log_sub "Install" "Core" $core_size $post_install_size_kb

for gapp_name in $gapps_list; do
  case $gapp_name in
    photos)  if [ "$vrmode_compat" = "true" ] && [ "$arch" = "arm64" ] && [ "$rom_build_sdk" -ge "24" ]; then gapp_name="photosvrmode"; fi;;  # for now only available on Nougat arm64
    movies)  if [ "$vrmode_compat" = "true" ] && ( [ "$arch" = "arm" ] || [ "$arch" = "arm64" ] ) && [ "$rom_build_sdk" -ge "24" ]; then gapp_name="moviesvrmode"; fi;;  # for now only available on Nougat arm & arm64
    *)  ;;
  esac
  get_apparchives "GApps/$gapp_name"
  total_appsize=0
  for archive in $apparchives; do
    get_appsize "$archive"
    total_appsize=$((total_appsize + $appsize))
  done
@DATASIZESCODE@
  post_install_size_kb=$((post_install_size_kb - total_appsize))
  log_sub "Install" "$gapp_name" "$total_appsize" "$post_install_size_kb"
done

# Perform calculations of required Buffer Size
set_progress 0.11
if ( grep -qiE '^smallbuffer$' "$g_conf" ); then
  buffer_size_kb=$small_buffer_size
fi

post_install_size_kb=$((post_install_size_kb - buffer_size_kb))
log_sub "" "Buffer Space" "$buffer_size_kb" $post_install_size_kb
echo ------------------------------------------------------------------ >> $calc_log

if [ "$post_install_size_kb" -ge 0 ]; then
  printf "%47s | %7d\n" "  Post Install Free Space" $post_install_size_kb >> $calc_log
  log "Post Install Free Space (KB)" "$post_install_size_kb   << See Calculations Below"
else
  additional_size_kb=$((post_install_size_kb * -1))
  printf "%47s | %7d\n" "Additional Space Required" $additional_size_kb >> $calc_log
  log "Additional Space Required (KB)" "$additional_size_kb   << See Calculations Below"
fi

# Finish up Calculation Log
echo ------------------------------------------------------------------ >> $calc_log
if [ -n "$user_remove_folder_list" ]; then
  echo "              * User Requested Removal" >> $calc_log
fi

# Check whether there's enough free space to complete this installation
if [ "$post_install_size_kb" -lt 0 ]; then
  # We don't have enough system space to install everything user requested
  ui_print "Insufficient storage space available in"
  ui_print "System partition. You may want to use a"
  ui_print "smaller Open GApps package or consider"
  ui_print "removing some apps using gapps-config."
  ui_print "See:'$log_folder/open_gapps_log.txt'"
  ui_print "for complete details and information."
  ui_print " "
  install_note="${install_note}system_space_msg$newline" # make note that there is insufficient space in system to install
  abort "$E_NOSPACE"
fi

# Check to see if this is the 'real thing' or only a test
if ( grep -qiE '^test$' "$g_conf" ); then # user has selected a 'test' install ONLY
  ui_print "- Exiting Simulated Install"
  ui_print " "
  install_note="${install_note}simulation_msg$newline" # make note that this is only a test installation
  quit
  exxit 0
fi

# _____________________________________________________________________________________________________________________
#                                                  Perform Removals
# Remove ALL Existing GApps files
set_progress 0.13
ui_print "- Removing existing/obsolete Apps"
ui_print " "
rm -rf $(complete_gapps_list)

# Remove Obsolete and Conflicting Apps
rm -rf $(obsolete_gapps_list)

# Remove Stock/AOSP Apps and add Removals to addon.d script
aosp_remove_list=$(echo "${aosp_remove_list}" | sort -r) # reverse sort list for more readable output
for aosp_name in $aosp_remove_list; do
  eval "list_name=\$${aosp_name}_list"
  list_name=$(echo "${list_name}" | sort -r) # reverse sort list for more readable output
  for file_name in $list_name; do
    rm -rf "/system/$file_name" "/system/product/$file_name"
    sed -i "\:# Remove Stock/AOSP apps (from GApps Installer):a \    rm -rf \$SYS/$file_name" $bkup_tail
  done
done

# Add saved addon.d User App Removals to make them persistent through repeat dirty GApps installs though the app may have already been removed
user_remove_folder_list=$(echo -e "${user_remove_folder_list}\n${addond_remove_folder_list}" | sort -u | sed '/^$/d')  # remove duplicates and empty lines

# Perform User App Removals and add Removals to addon.d script
user_remove_folder_list=$(echo "${user_remove_folder_list}" | sort -r) # reverse sort list for more readable output
for user_app in $user_remove_folder_list; do
  rm -rf "$user_app"
  sed -i "\:# Remove 'user requested' apps (from gapps-config):a \    rm -rf ${user_app/\/system/\$SYS}" $bkup_tail
done

# Remove any empty folders we may have created during the removal process
for i in /system/app /system/product/app /system/priv-app /system/product/priv-app /system/vendor/pittpatt /system/usr/srec /system/etc/preferred-apps; do
  find "$i" -type d 2>/dev/null | xargs -r rmdir -p --ignore-fail-on-non-empty
done

# _____________________________________________________________________________________________________________________
#                                                  Perform Installs
ui_print "- Installing core GApps"
set_progress 0.15
for gapp_name in $core_gapps_list; do
  get_apparchives "Core/$gapp_name"
  for archive in $apparchives; do
    case $gapp_name in
      setupwizarddefault) if [ "$device_type" != "tablet" ]; then extract_app "$archive"; fi;;
      setupwizardtablet)  if [ "$device_type"  = "tablet" ]; then extract_app "$archive"; fi;;
      googlepixelconfig) if [ "$googlepixel_compat" = "true" ]; then extract_app "$archive"; fi;;
      backuprestore) if [ "$googlepixel_compat" = "false" ]; then extract_app "$archive"; fi;;
      datatransfertool) if [ "$googlepixel_compat" = "true" ]; then extract_app "$archive"; fi;;
      *)  extract_app "$archive";;
    esac
  done
done
ui_print " "
set_progress 0.25

@KEYBDINSTALLCODE@
@DATAINSTALLCODE@
# Progress Bar increment calculations for GApps Install process
set_progress 0.30
gapps_count=$(echo "${gapps_list}" | wc -w) # Count number of GApps left to be installed
if [ "$gapps_count" -lt 1 ]; then gapps_count=1; fi # Prevent division by zero
incr_amt=$(( 5000 / gapps_count )) # Determine increment factor of progress bar during GApps installation
prog_bar=3000 # Set Progress Bar start point (0.3000) for below

# Install the rest of GApps still in $gapps_list
for gapp_name in $gapps_list; do
  case $gapp_name in
    photos)  if [ "$vrmode_compat" = "true" ] && [ "$arch" = "arm64" ] && [ "$rom_build_sdk" -ge "24" ]; then gapp_name="photosvrmode"; fi;;  # for now only available on Nougat arm64
    movies)  if [ "$vrmode_compat" = "true" ] && ( [ "$arch" = "arm" ] || [ "$arch" = "arm64" ] ) && [ "$rom_build_sdk" -ge "24" ]; then gapp_name="moviesvrmode"; fi;;  # for now only available on Nougat arm & arm64
    *)  ;;
  esac
  ui_print "- Installing $gapp_name"
  get_apparchives "GApps/$gapp_name"
  for archive in $apparchives; do
    extract_app "$archive" # Installing User Selected GApps
  done
  prog_bar=$((prog_bar + incr_amt))
  set_progress 0.$prog_bar
done

ui_print " "
ui_print "- Miscellaneous tasks"
ui_print " "

# Use Gms (Google Play services) for feedback/bug reporting (instead of org.cyanogenmod.bugreport or others)
sed -i "s/ro.error.receiver.system.apps=.*/ro.error.receiver.system.apps=com.google.android.gms/g" /system/build.prop
sed -i "\:# Apply build.prop changes (from GApps Installer):a \    sed -i \"s/ro.error.receiver.system.apps=.*/ro.error.receiver.system.apps=com.google.android.gms/g\" \$SYS/build.prop" $bkup_tail

# Enable Google Assistant
if ( grep -qiE '^googleassistant$' "$g_conf" ); then  #TODO this is not enabled by default atm; because Assistant still has various regressions compared to Google Now
  if ! grep -q "ro.opa.eligible_device=" /system/build.prop; then
    echo "ro.opa.eligible_device=true" >> /system/build.prop
  fi
  sed -i "\:# Apply build.prop changes (from GApps Installer):a \    if ! grep -q \"ro.opa.eligible_device=\" /system/build.prop; then echo \"ro.opa.eligible_device=true\" >> \$SYS/build.prop; fi" $bkup_tail
fi

# Create Markup lib symlink if installed
if ( contains "$gapps_list" "markup" ); then
  install -d "/system/app/MarkupGoogle/lib/$arch"
  ln -sfn "/system/$libfolder/$markup_lib_filename" "/system/app/MarkupGoogle/lib/$arch/$markup_lib_filename"
  # Add same code to backup script to ensure symlinks are recreated on addon.d restore
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    ln -sfn \"\$SYS/$libfolder/$markup_lib_filename\" \"\$SYS/app/MarkupGoogle/lib/$arch/$markup_lib_filename\"" $bkup_tail
  sed -i "\:# Recreate required symlinks (from GApps Installer):a \    install -d \"\$SYS/app/MarkupGoogle/lib/$arch\"" $bkup_tail
fi

@tvremotelibsymlink@
@webviewlibsymlink@

# Copy g.prop over to /system/etc
cp -f "$TMP/g.prop" "$g_prop"

# _____________________________________________________________________________________________________________________
#                                                  Build and Install Addon.d Backup Script
# Add 'other' Removals to addon.d script
set_progress 0.80
other_list=$(echo "${other_list}" | sort -r) # reverse sort list for more readable output
for other_name in $other_list; do
  sed -i "\:# Remove 'other' apps (per installer.data):a \    rm -rf \$SYS/$other_name" $bkup_tail
done

# Add 'priv-app' Removals to addon.d script
privapp_list=$(echo "${privapp_list}" | sort -r) # reverse sort list for more readable output
for privapp_name in $privapp_list; do
  sed -i "\:# Remove 'priv-app' apps from 'app' (per installer.data):a \    rm -rf \$SYS/$privapp_name" $bkup_tail
done

# Add 'required' Removals to addon.d script
reqd_list=$(echo "${reqd_list}" | sort -r) # reverse sort list for more readable output
for reqdapp_name in $reqd_list; do
  sed -i "\:# Remove 'required' apps (per installer.data):a \    rm -rf ${reqdapp_name/\/system/\$SYS}" $bkup_tail
done

# Create final addon.d script in system
bkup_header="#!/sbin/sh
#
# ADDOND_VERSION=2
#
# /system/addon.d/70-gapps.sh
#
. /tmp/backuptool.functions
\n
if [ -z \$backuptool_ab ]; then
  SYS=\$S
  TMP="/tmp"
else
  SYS="/postinstall/system"
  TMP="/postinstall/tmp"
fi
\n
list_files() {
cat <<EOF"
bkup_list="$bkup_list${newline}etc/g.prop" # add g.prop to backup list
bkup_list=$(echo "${bkup_list}" | sort -u| sed '/^$/d') # sort list & remove duplicates and empty lines
install -d /system/addon.d
echo -e "$bkup_header" > /system/addon.d/70-gapps.sh
echo -e "$bkup_list" >> /system/addon.d/70-gapps.sh
cat $bkup_tail >> /system/addon.d/70-gapps.sh

# _____________________________________________________________________________________________________________________
#                                                  Fix Permissions
set_progress 0.85
find /system/vendor/pittpatt -type d -exec chown 0:2000 '{}' \; 2>/dev/null # Change pittpatt folders to root:shell per Google Factory Settings

set_perm 0 0 755 "/system/addon.d/70-gapps.sh"
ch_con system "/system/addon.d/70-gapps.sh"

set_perm 0 0 644 "$g_prop"
ch_con system "$g_prop"

set_progress 0.92
quit

ui_print "- Installation complete!"
ui_print " "

if ( contains "$gapps_list" "dialergoogle" ); then
  ui_print "You installed Google Dialer."
  ui_print "Please set it as default Phone"
  ui_print "application to prevent calls"
  ui_print "from rebooting your device."
  ui_print "See https://goo.gl/LTIJ0o"

  # set Google Dialer as default; based on the work of osm0sis @ xda-developers
  setver="122"  # lowest version in MM, tagged at 6.0.0
  setsec="/data/system/users/0/settings_secure.xml"
  if [ -f "$setsec" ]; then
    if grep -q 'dialer_default_application' "$setsec"; then
      if ! grep -q 'dialer_default_application" value="com.google.android.dialer' "$setsec"; then
        curentry="$(grep -o 'dialer_default_application" value=.*$' "$setsec")"
        newentry='dialer_default_application" value="com.google.android.dialer" package="android" />\r'
        sed -i "s;${curentry};${newentry};" "$setsec"
      fi
    else
      max="0"
      for i in $(grep -o 'id=.*$' "$setsec" | cut -d '"' -f 2); do
        [ "$i" -gt "$max" ] && max="$i"
      done
      entry='<setting id="'"$((max + 1))"'" name="dialer_default_application" value="com.google.android.dialer" package="android" />\r'
      sed -i "/<settings version=\"/a\ \ ${entry}" "$setsec"
    fi
  else
    if [ ! -d "/data/system/users/0" ]; then
      install -d "/data/system/users/0"
      chown -R 1000:1000 "/data/system"
      chmod -R 775 "/data/system"
      chmod 700 "/data/system/users/0"
    fi
    { echo -e "<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>\r"
    echo -e '<settings version="'$setver'">\r'
    echo -e '  <setting id="1" name="dialer_default_application" value="com.google.android.dialer" package="android" />\r'
    echo -e '</settings>'; } > "$setsec"
  fi
  chown 1000:1000 "$setsec"
  chmod 600 "$setsec"
fi

exxit 0
