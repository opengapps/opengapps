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
makearomaconfig(){
tee "$build/META-INF/com/google/android/aroma-config" > /dev/null <<'EOFILE'
#This file is part of The Open GApps script of @raulx222.
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

# ROM Info
ini_set("rom_name", "Open GApps");
ini_set("rom_author", "Open GApps Team");
ini_set("rom_date", zipprop("g.prop", "ro.addon.open_version"));
ini_set("text_quit", "Exit");
ini_set("text_next", "Next");

##############################################
# UI/Font/Splash
##############################################
ini_set("force_colorspace", "rgba");
splash(
    3000,
    "open"
);
fontresload("0", "ttf/Roboto-Regular.ttf", "12");
fontresload("1", "ttf/Roboto-Regular.ttf", "14");
theme("material_green");

##############################################
# Welcome
##############################################
viewbox(
  "Welcome",

  "With AROMA Open GApps you can choose which GApps to install!\n\n\n\n" +
  "Package Information\n\n" +

    "   Name\t\t: <b><#scrollbar>" + ini_get("rom_name") + "</#></b>\n"+
    "   Author\t\t: <b><#scrollbar>" + ini_get("rom_author") + "</#></b>\n"+
    "   Supported devices: <b><#scrollbar>Any!</#></b>\n"+
    "   Supported Android: <b><#scrollbar>"+zipprop("g.prop", "ro.addon.platform")+"</#></b>\n"+
    "   Build date\t: <b><#scrollbar>" + ini_get("rom_date") + " </#></b>\n\n"+
    "<b>For support and updates visit our site! <#scrollbar>(http://opengapps.org)</#></b>"+"\n\n\n\n",

  "@welcome"
);

##############################################
# MENU
##############################################
menubox(
    "Open GApps",
    "Please select one of the choices below",
    "@apps",
    "menu.prop",
    "Customized installation",   "Select which apps you want",     "@personalize",      #-- selected = 1
    "Complete installation",     "Install the Super package",      "@default",         #-- selected = 2
    "Exit",              "Exit to recovery",    "@alert"      #-- selected = 3
);

#Exit
if prop("menu.prop", "selected")=="3" then
  if
    confirm(
      "Exit",
      "Are you sure want to exit the Installer?",
      "@alert"
    )=="yes"
  then
    exit("");
  endif;

  back("1");
endif;

##############################################
# Load Previous Choices
##############################################
checkviewbox(
  "Load Previous Choices",
  "Load Previous Choices\n\n\n\n\n<b>Do you want to load your choices from a previous install?</b>\n\n",
  "@welcome",

  "Load choices.", "1", "loadselections"
);

if
    getvar("loadselections")=="1"
  then
    if
        getvar("reset")!="1"
    then
        resexec("scripts/tools.sh", "load");
        setvar("reset", "1");
    endif;
  else
    if
      getvar("reset")=="1" then
        resexec("scripts/tools.sh", "reset");
        setvar("reset","0");
    endif;
endif;

if prop("menu.prop", "selected")=="1" then
##############################################
# Customized installation
##############################################
form(
    "Apps",
    "Please select which apps you want to include or exclude</#>",
    "@default",
    aromagapps.prop,
    "inclorexcl",     "Choose to include or exclude the apps below",        "",                    "group",
      "1",     "Include",   "Choose the apps you WANT installed from the list below.",             "select.selected",
      "0",     "Exclude",   "Choose the apps you DON'T WANT installed from the list below.",       "select",

    "gapps",     "Choose GApps which you want to add on install/exclude list",        "",                                         "group",
      "AndroidPay",     "<b>Android Pay</b>",       "",                      "check",
      "AndroidForWork",     "<b>Android For Work</b>",       "",                      "check",
      "Books",     "<b>Google Play Books</b>",       "",                      "check",
      "CalculatorGoogle",     "<b>Google Calculator</b>",       "",                      "check",
      "CalendarGoogle",     "<b>Google Calendar</b>",       "",                      "check",
      "CalSync",     "<b>Google Calendar Sync</b>",       "(installed by default when Google Calendar is NOT being installed)",                      "check",
      "CameraGoogle",     "<b>Google Camera</b>",       "",                      "check",
      "Chrome",     "<b>Google Chrome</b>",       "",                      "check",
      "ClockGoogle",     "<b>Google Clock</b>",       "",                      "check",
      "CloudPrint",     "<b>Google Cloud Print</b>",       "",                      "check",
      "ContactsGoogle",     "<b>Google Contacts</b>",       "",                      "check",
      "DMAgent",     "<b>Google Apps Device Policy</b>",       "",                      "check",
      "Docs",     "<b>Google Docs</b>",       "",                      "check",
      "Drive",     "<b>Google Drive</b>",       "",                      "check",
      "Ears",     "<b>Sound Search for Google Play</b>",       "",                      "check",
      "Earth",     "<b>Google Earth</b>",       "",                      "check",
      "ExchangeGoogle",     "<b>Google Exchange Services</b>",       "",                      "check",
      "FaceDetect",     "<b>Face Detection for Media</b>",       "",                      "check",
      "FaceUnlock",     "<b>Face Unlock</b>",       "",                      "check",
      "Fitness",     "<b>Google Fit</b>",       "",                      "check",
      "GCS",     "<b>Google Connectivity Services</b>",       "To Exclude BOTH Google Connectivity Services AND Project Fi by Google <#f00>OR</#> To Include Google Connectivity Services",                      "check",
      "Gmail",     "<b>Gmail</b>",       "",                      "check",
      "GoogleNow",     "<b>Google Now Launcher</b>",       "",                      "check",
      "GooglePlus",     "<b>Google+</b>",       "",                      "check",
      "GoogleTTS",     "<b>Google Text-to-Speech</b>",       "",                      "check",
      "Hangouts",     "<b>Google Hangouts</b>",       "",                      "check",
      "Indic",     "<b>Google Indic Keyboard</b>",       "",                      "check",
      "Japanese",     "<b>Google Japanese Input</b>",       "",                      "check",
      "Keep",     "<b>Google Keep</b>",       "",                      "check",
      "KeyboardGoogle",     "<b>Google Keyboard</b>",       "",                      "check",
      "Korean",     "<b>Google Korean Input</b>",       "",                      "check",
      "Maps",     "<b>Google Maps</b>",       "",                      "check",
      "Messenger",     "<b>Messenger</b>",       "(not installed on tablet devices)",                      "check",
      "Movies",     "<b>Google Play Movies & TV</b>",       "",                      "check",
      "Music",     "<b>Google Play Music</b>",       "",                      "check",
      "NewsStand",     "<b>Google Play Newsstand</b>",       "",                      "check",
      "NewsWidget",     "<b>Google News & Weather</b>",       "",                      "check",
      "Pinyin",     "<b>Google Pinyin Input</b>",       "",                      "check",
      "Photos",     "<b>Google Photos</b>",       "",                      "check",
      "PlayGames",     "<b>Google Play Games</b>",       "",                      "check",
      "ProjectFi",     "<b>Project Fi by Google</b>",       "",                      "check",
      "Sheets",     "<b>Google Sheets</b>",       "",                      "check",
      "Slides",     "<b>Google Slides</b>",       "",                      "check",
      "Search",     "<b>Google Search</b>",       "To Exclude BOTH Google Search AND Google Now Launcher <#f00>OR</#> To Include Google Search",                      "check",
      "Speech",     "<b>Offline Speech Files</b>",       "(Required for offline voice dicatation support)",                      "check",
      "Street",     "<b>Google Street View</b>",       "",                      "check",
      "TagGoogle",     "<b>Google NFC Tags</b>",       "",                      "check",
      "Talkback",     "<b>Talkback</b>",       "",                      "check",
      "Translate",     "<b>Google Translate</b>",       "",                      "check",
      "WebViewGoogle",     "<b>Android System WebView</b>",       "",                      "check",
      "YouTube",     "<b>YouTube</b>",       "",                      "check",
      "Zhuyin",     "<b>Google Zhuyin Input</b>",       "",                      "check"
);
# Duplicate aromagapps.prop and rename it to gapps.prop - this is useful because the selections won't be erased by the complete installation (menu.prop selected ==2)
resexec("scripts/props.sh");
endif;

#IF COMPLETE INSTALLATION IS CHOOSEN - reset gapps.prop
if prop("menu.prop", "selected")=="2" then
  writetmpfile("gapps.prop", " ");
endif;

form(
    "Default removal bypass",
    "Careful, you can override the default removal of Stock/AOSP applications below. Please only select if you are sure you want them installed alongside the Google replacement.",
    "@default",
    bypass.prop,
    "bypassrem",     "Bypass the automatic removal of Stock/AOSP apps",        "",     "group",
      "+Browser",     "<b>+Browser</b>",      "",    "check",
      "+Email",     "<b>+Email</b>",      "",        "check",
      "+Gallery",     "<b>+Gallery</b>",      "",    "check",
      "+Launcher",     "<b>+Launcher</b>",      "",  "check",
      "+MMS",     "<b>+MMS</b>",      "",            "check",
      "+PicoTTS",     "<b>+PicoTTS</b>",      "",    "check"
);

form(
    "Remove",
    "Please select which Stock/AOSP apps you want to remove\n</#>",
    "@default",
    rem.prop,
    "remove",     "Choose apps which you want to remove",        "",                                         "group",
      "BasicDreams",     "<b>Basic Dreams Live Wallpaper</b>",       "",                      "check",
      "Browser",     "<b>Stock/AOSP Browser</b>",       "",                      "check",
      "CalendarStock",     "<b>Stock/AOSP Calendar</b>",       "(automatically removed when Google Calendar is installed)",                      "check",
      "CameraStock",     "<b>Stock/AOSP/Moto Camera</b>",       "(automatically removed when Google Camera is installed)",                      "check",
      "ClockStock",     "<b>Stock/AOSP Clock</b>",       "(automatically removed when Google Clock is installed)",                      "check",
      "CMAccount",     "<b>CyanogenMod Account</b>",       "",                      "check",
      "CMAudioFX",     "<b>CyanogenMod AudioFX</b>",       "",                      "check",
      "CMEleven",     "<b>CyanogenMod Music</b>",       "",                      "check",
      "CMFileManager",     "<b>CyanogenMod File Manager</b>",       "",                      "check",
      "CMSetupWizard",     "<b>CyanogenMod Setup Wizard</b>",       "",                      "check",
      "CMUpdater",     "<b>CyanogenMod Updater</b>",       "",                      "check",
      "CMWallpapers",     "<b>CyanogenMod Wallpapers</b>",       "",                      "check",
      "DashClock",     "<b>DashClock Widget</b>",       "(a widget found in certain ROMs)",                      "check",
      "Email",     "<b>Stock/AOSP Email</b>",       "",                      "check",
      "ExchangeStock",     "<b>Stock/AOSP Exchange Services</b>",       "(automatically removed when Google Exchange Services is installed)",                      "check",
      "FMRadio",     "<b>Stock/AOSP FM Radio</b>",       "(not found on all devices or ROM's)",                      "check",
      "Galaxy",     "<b>Galaxy Live Wallpaper</b>",       "",                      "check",
      "Gallery",     "<b>Stock/AOSP Gallery</b>",       "",                      "check",
      "HoloSpiral",     "<b>Holo Spiral Live Wallpaper</b>",       "",                      "check",
      "KeyboardStock",     "<b>Stock/AOSP Keyboard</b>",       "(automatically removed when Google Keyboard is installed)",                      "check",
      "Launcher",     "<b>Stock/AOSP Launcher(s)</b>",       "",                      "check",
      "LiveWallpapers",     "<b>Live Wallpapers</b>",       "",                      "check",
      "LockClock",     "<b>Lock Clock</b>",       "(a widget found in certain ROMs)",                      "check",
      "MMS",     "<b>Stock/AOSP MMS</b>",       "",                      "check",
      "NoiseField",     "<b>NoiseField Live Wallpaper</b>",       "",                      "check",
      "Phasebeam",     "<b>Phasebeam Live Wallpaper</b>",       "",                      "check",
      "PhotoPhase",     "<b>PhotoPhase Live Wallpaper</b>",       "",                      "check",
      "PhotoTable",     "<b>PhotoTable Live Wallpaper</b>",       "",                      "check",
      "PicoTTS",     "<b>Stock/AOSP Text-to-Speech</b>",       "",                      "check",
      "SimToolKit",     "<b>Stock/AOSP Sim ToolKit</b>",       "",                      "check",
      "Studio",     "<b>Stock/AOSP Movie Studio</b>",       "",                      "check",
      "SykoPath",     "<b>SykoPath Layers Manager</b>",       "(found in certain ROM's)",                      "check",
      "Terminal",     "<b>Terminal</b>",       "",                      "check",
      "Themes",     "<b>CyanogenMod Theme Engine</b>",       "(Will break the link in Settings to Themes!)",                      "check",
      "VisualizationWallpapers",     "<b>Visualization Live Wallpaper</b>",       "",                      "check",
      "WhisperPush",     "<b>WhisperPush</b>",       "",                      "check"
);
form(
    "Advanced Options",
    "Some advanced options that most likely don't need to be used.\n</#>",
    "@default",
    extra.prop,
    "extra",     "Advanced Options",        "",                                         "group",
      "ex1",     "<b>No Debug Log</b>",       "To disable debugging",                      "check",
      "ex2",     "<b>Test</b>",       "To perform a simulation generating a detailed log, but <u>WILL NOT MAKE ANY CHANGES</u> to your device.",                      "check"
);

##############################################
# Write the gapps-config file
##############################################
setvar("gapps","");

# ADVANCED OPTIONS
if
  prop("extra.prop", "ex1")=="1"
then
  appendvar("gapps", "NoDebug\n");
endif;
if
  prop("extra.prop", "ex2")=="1"
then
  appendvar("gapps", "Test\n");
endif;

# INCLUDE/EXCLUDE
if
  prop("gapps.prop", "inclorexcl")=="1"
then
  appendvar("gapps", "Include");
else
  appendvar("gapps", "Exclude");
endif;

# APP CHOICES
appendvar("gapps", "\n\n");

if
  prop("gapps.prop", "AndroidPay")=="1"
then
  appendvar("gapps", "AndroidPay\n");
endif;

if
  prop("gapps.prop", "AndroidForWork")=="1"
then
  appendvar("gapps", "AndroidForWork\n");
endif;

if
  prop("gapps.prop", "Books")=="1"
then
  appendvar("gapps", "Books\n");
endif;

if
  prop("gapps.prop", "CalculatorGoogle")=="1"
then
  appendvar("gapps", "CalculatorGoogle\n");
endif;

if
  prop("gapps.prop", "CalendarGoogle")=="1"
then
  appendvar("gapps", "CalendarGoogle\n");
endif;

if
  prop("gapps.prop", "CalSync")=="1"
then
  appendvar("gapps", "CalSync\n");
endif;

if
  prop("gapps.prop", "CameraGoogle")=="1"
then
  appendvar("gapps", "CameraGoogle\n");
endif;

if
  prop("gapps.prop", "Chrome")=="1"
then
  appendvar("gapps", "Chrome\n");
endif;

if
  prop("gapps.prop", "ClockGoogle")=="1"
then
  appendvar("gapps", "ClockGoogle\n");
endif;

if
  prop("gapps.prop", "CloudPrint")=="1"
then
  appendvar("gapps", "CloudPrint\n");
endif;

if
  prop("gapps.prop", "ContactsGoogle")=="1"
then
  appendvar("gapps", "ContactsGoogle\n");
endif;

if
  prop("gapps.prop", "DMAgent")=="1"
then
  appendvar("gapps", "DMAgent\n");
endif;

if
  prop("gapps.prop", "Docs")=="1"
then
  appendvar("gapps", "Docs\n");
endif;

if
  prop("gapps.prop", "Drive")=="1"
then
  appendvar("gapps", "Drive\n");
endif;

if
  prop("gapps.prop", "Ears")=="1"
then
  appendvar("gapps", "Ears\n");
endif;

if
  prop("gapps.prop", "Earth")=="1"
then
  appendvar("gapps", "Earth\n");
endif;

if
  prop("gapps.prop", "ExchangeGoogle")=="1"
then
  appendvar("gapps", "ExchangeGoogle\n");
endif;

if
  prop("gapps.prop", "FaceDetect")=="1"
then
  appendvar("gapps", "FaceDetect\n");
endif;

if
  prop("gapps.prop", "FaceUnlock")=="1"
then
  appendvar("gapps", "FaceUnlock\n");
endif;

if
  prop("gapps.prop", "Fitness")=="1"
then
  appendvar("gapps", "Fitness\n");
endif;

if
  prop("gapps.prop", "GCS")=="1"
then
  appendvar("gapps", "GCS\n");
endif;

if
  prop("gapps.prop", "Gmail")=="1"
then
  appendvar("gapps", "Gmail\n");
endif;

if
  prop("gapps.prop", "GoogleNow")=="1"
then
  appendvar("gapps", "GoogleNow\n");
endif;

if
  prop("gapps.prop", "GooglePlus")=="1"
then
  appendvar("gapps", "GooglePlus\n");
endif;

if
  prop("gapps.prop", "GoogleTTS")=="1"
then
  appendvar("gapps", "GoogleTTS\n");
endif;

if
  prop("gapps.prop", "Hangouts")=="1"
then
  appendvar("gapps", "Hangouts\n");
endif;

if
  prop("gapps.prop", "Indic")=="1"
then
  appendvar("gapps", "Indic\n");
endif;

if
  prop("gapps.prop", "Japanese")=="1"
then
  appendvar("gapps", "Japanese\n");
endif;

if
  prop("gapps.prop", "Keep")=="1"
then
  appendvar("gapps", "Keep\n");
endif;

if
  prop("gapps.prop", "KeyboardGoogle")=="1"
then
  appendvar("gapps", "KeyboardGoogle\n");
endif;

if
  prop("gapps.prop", "Korean")=="1"
then
  appendvar("gapps", "Korean\n");
endif;

if
  prop("gapps.prop", "Maps")=="1"
then
  appendvar("gapps", "Maps\n");
endif;

if
  prop("gapps.prop", "Messenger")=="1"
then
  appendvar("gapps", "Messenger\n");
endif;

if
  prop("gapps.prop", "Movies")=="1"
then
  appendvar("gapps", "Movies\n");
endif;

if
  prop("gapps.prop", "Music")=="1"
then
  appendvar("gapps", "Music\n");
endif;

if
  prop("gapps.prop", "NewsStand")=="1"
then
  appendvar("gapps", "NewsStand\n");
endif;

if
  prop("gapps.prop", "NewsWidget")=="1"
then
  appendvar("gapps", "NewsWidget\n");
endif;

if
  prop("gapps.prop", "Pinyin")=="1"
then
  appendvar("gapps", "Pinyin\n");
endif;

if
  prop("gapps.prop", "Photos")=="1"
then
  appendvar("gapps", "Photos\n");
endif;

if
  prop("gapps.prop", "PlayGames")=="1"
then
  appendvar("gapps", "PlayGames\n");
endif;

if
  prop("gapps.prop", "ProjectFi")=="1"
then
  appendvar("gapps", "ProjectFi\n");
endif;

if
  prop("gapps.prop", "Sheets")=="1"
then
  appendvar("gapps", "Sheets\n");
endif;

if
  prop("gapps.prop", "Slides")=="1"
then
  appendvar("gapps", "Slides\n");
endif;

if
  prop("gapps.prop", "Search")=="1"
then
  appendvar("gapps", "Search\n");
endif;

if
  prop("gapps.prop", "Speech")=="1"
then
  appendvar("gapps", "Speech\n");
endif;

if
  prop("gapps.prop", "Street")=="1"
then
  appendvar("gapps", "Street\n");
endif;

if
  prop("gapps.prop", "TagGoogle")=="1"
then
  appendvar("gapps", "TagGoogle\n");
endif;

if
  prop("gapps.prop", "Talkback")=="1"
then
  appendvar("gapps", "Talkback\n");
endif;

if
  prop("gapps.prop", "Translate")=="1"
then
  appendvar("gapps", "Translate\n");
endif;

if
  prop("gapps.prop", "WebViewGoogle")=="1"
then
  appendvar("gapps", "WebViewGoogle\n");
endif;

if
  prop("gapps.prop", "YouTube")=="1"
then
  appendvar("gapps", "YouTube\n");
endif;

if
  prop("gapps.prop", "Zhuyin")=="1"
then
  appendvar("gapps", "Zhuyin\n");
endif;

appendvar("gapps", "\n");

# REMOVALS
if
  prop("rem.prop", "BasicDreams")=="1"
then
  appendvar("gapps", "BasicDreams\n");
endif;

if
  prop("rem.prop", "Browser")=="1"
then
  appendvar("gapps", "Browser\n");
endif;

if
  prop("rem.prop", "CalendarStock")=="1"
then
  appendvar("gapps", "CalendarStock\n");
endif;

if
  prop("rem.prop", "ClockStock")=="1"
then
  appendvar("gapps", "ClockStock\n");
endif;

if
  prop("rem.prop", "CameraStock")=="1"
then
  appendvar("gapps", "CameraStock\n");
endif;

if
  prop("rem.prop", "CMAccount")=="1"
then
  appendvar("gapps", "CMAccount\n");
endif;

if
  prop("rem.prop", "CMAudioFX")=="1"
then
  appendvar("gapps", "CMAudioFX\n");
endif;

if
  prop("rem.prop", "CMEleven")=="1"
then
  appendvar("gapps", "CMEleven\n");
endif;

if
  prop("rem.prop", "CMFileManager")=="1"
then
  appendvar("gapps", "CMFileManager\n");
endif;

if
  prop("rem.prop", "CMSetupWizard")=="1"
then
  appendvar("gapps", "CMSetupWizard\n");
endif;

if
  prop("rem.prop", "CMUpdater")=="1"
then
  appendvar("gapps", "CMUpdater\n");
endif;

if
  prop("rem.prop", "CMWallpapers")=="1"
then
  appendvar("gapps", "CMWallpapers\n");
endif;

if
  prop("rem.prop", "DashClock")=="1"
then
  appendvar("gapps", "DashClock\n");
endif;

if
  prop("rem.prop", "Email")=="1"
then
  appendvar("gapps", "Email\n");
endif;

if
  prop("rem.prop", "ExchangeStock")=="1"
then
  appendvar("gapps", "ExchangeStock\n");
endif;

if
  prop("rem.prop", "FMRadio")=="1"
then
  appendvar("gapps", "FMRadio\n");
endif;

if
  prop("rem.prop", "Galaxy")=="1"
then
  appendvar("gapps", "Galaxy\n");
endif;

if
  prop("rem.prop", "Gallery")=="1"
then
  appendvar("gapps", "Gallery\n");
endif;

if
  prop("rem.prop", "HoloSpiral")=="1"
then
  appendvar("gapps", "HoloSpiral\n");
endif;

if
  prop("rem.prop", "KeyboardStock")=="1"
then
  appendvar("gapps", "KeyboardStock\n");
endif;

if
  prop("rem.prop", "Launcher")=="1"
then
  appendvar("gapps", "Launcher \n");
endif;

if
  prop("rem.prop", "LiveWallpapers")=="1"
then
  appendvar("gapps", "LiveWallpapers\n");
endif;

if
  prop("rem.prop", "LockClock")=="1"
then
  appendvar("gapps", "LockClock\n");
endif;

if
  prop("rem.prop", "MMS")=="1"
then
  appendvar("gapps", "MMS\n");
endif;

if
  prop("rem.prop", "NoiseField")=="1"
then
  appendvar("gapps", "NoiseField\n");
endif;

if
  prop("rem.prop", "Phasebeam")=="1"
then
  appendvar("gapps", "Phasebeam\n");
endif;

if
  prop("rem.prop", "PhotoPhase")=="1"
then
  appendvar("gapps", "PhotoPhase\n");
endif;

if
  prop("rem.prop", "PhotoTable")=="1"
then
  appendvar("gapps", "PhotoTable\n");
endif;

if
  prop("rem.prop", "PicoTTS")=="1"
then
  appendvar("gapps", "PicoTTS\n");
endif;

if
  prop("rem.prop", "SimToolKit")=="1"
then
  appendvar("gapps", "SimToolKit\n");
endif;

if
  prop("rem.prop", "Studio")=="1"
then
  appendvar("gapps", "Studio\n");
endif;

if
  prop("rem.prop", "SykoPath")=="1"
then
  appendvar("gapps", "SykoPath\n");
endif;

if
  prop("rem.prop", "Terminal")=="1"
then
  appendvar("gapps", "Terminal\n");
endif;

if
  prop("rem.prop", "Themes")=="1"
then
  appendvar("gapps", "Themes\n");
endif;

if
  prop("rem.prop", "VisualizationWallpapers")=="1"
then
  appendvar("gapps", "VisualizationWallpapers\n");
endif;

if
  prop("rem.prop", "WhisperPush")=="1"
then
  appendvar("gapps", "WhisperPush\n");
endif;



# BYPASS REMOVALS
appendvar("gapps", "\n\n");
if
  prop("bypass.prop", "+Browser")=="1"
then
  appendvar("gapps", "+Browser\n");
endif;
if
  prop("bypass.prop", "+Email")=="1"
then
  appendvar("gapps", "+Email\n");
endif;
if
  prop("bypass.prop", "+Gallery")=="1"
then
  appendvar("gapps", "+Gallery\n");
endif;
if
  prop("bypass.prop", "+Launcher")=="1"
then
  appendvar("gapps", "+Launcher\n");
endif;
if
  prop("bypass.prop", "+MMS")=="1"
then
  appendvar("gapps", "+MMS\n");
endif;
if
  prop("bypass.prop", "+PicoTTS")=="1"
then
  appendvar("gapps", "+PicoTTS\n");
endif;

# WRITE CONFIG TO TEMP AND DISPLAY IT
writetmpfile(".gapps-config", getvar("gapps"));

textbox(
    "gapps-config",
    "Your gapps-config file.",
    "@update",
    read("tmp/aroma/.gapps-config")
);

##############################################
# Save Choices
##############################################
checkviewbox(
  "Save Choices",
  "Save Choices: /sdcard/Open-GApps\n\n\n\n\n<b>Do you want to save your choices? It will save time in future installations.</b>\n\n",
  "@welcome",

  "Save Choices", "1", "saveselections"
);
if
    getvar("saveselections")=="1"
  then
    resexec("scripts/tools.sh", "save");
endif;

# Pre-Install
ini_set("text_next", "Install GApps");
viewbox(
  "Save config and perform GApps install.",
  "Are you ready to install GApps based on your preferences?\n\n\n\n\n" +
  "Press <b>Install GApps</b> to perform the install.\n\n" +
  "If you want to review or change any of your settings, press <b>Back</b>.",
  "@install"
);

# Install
ini_set("text_next", "Next");
install(
  "Installing",
  "<b>Open GApps</b> are being installed.\n\n" +
  "Please wait until the process is finished",
  "@install",
  "Press Next to continue."
);

# Post-Install
ini_set("text_next", "Finish");
checkviewbox(
  "Installed",
  "<b>Congratulations!</b>\n\n\n\n\n" +
  "Open GApps has been installed into your device.",
  "@welcome",

  "Reboot your device now.", "0", "reboot_it"
);

#Reboot
if
  getvar("reboot_it")=="1"
then
  reboot("onfinish");
endif;
EOFILE
}
