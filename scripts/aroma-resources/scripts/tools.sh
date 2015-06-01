#!/sbin/sh
#
#Open GApps Tools
#by raulx222
#

case "$1" in
	save)
	rm -f /sdcard/Open-GApps/aromagapps.prop
	rm -f /sdcard/Open-GApps/bypass.prop
	rm -f /sdcard/Open-GApps/rem.prop
	[ ! -d /sdcard/Open-GApps ] && mkdir /sdcard/Open-GApps
	cp /tmp/aroma/aromagapps.prop /sdcard/Open-GApps/aromagapps.prop
	cp /tmp/aroma/bypass.prop /sdcard/Open-GApps/bypass.prop
	cp /tmp/aroma/rem.prop /sdcard/Open-GApps/rem.prop
	;;
	load)
	[ -f /sdcard/Open-GApps/aromagapps.prop ] && rm -f /tmp/aroma/aromagapps.prop && cp /sdcard/Open-GApps/aromagapps.prop /tmp/aroma/aromagapps.prop
	[ -f /sdcard/Open-GApps/bypass.prop ] && rm -f /tmp/aroma/bypass.prop && cp /sdcard/Open-GApps/bypass.prop /tmp/aroma/bypass.prop
	[ -f /sdcard/Open-GApps/rem.prop ] && rm -f /tmp/aroma/rem.prop && cp /sdcard/Open-GApps/rem.prop /tmp/aroma/rem.prop
	;;
	reset)
	rm -f /tmp/aroma/aromagapps.prop
	rm -f /tmp/aroma/bypass.prop
	rm -f /tmp/aroma/rem.prop
	;;
esac
