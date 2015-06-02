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
	rm -f /sdcard/Open-GApps/extra.prop
	[ ! -d /sdcard/Open-GApps ] && mkdir /sdcard/Open-GApps
	cp /tmp/aroma/aromagapps.prop /sdcard/Open-GApps/aromagapps.prop
	cp /tmp/aroma/bypass.prop /sdcard/Open-GApps/bypass.prop
	cp /tmp/aroma/rem.prop /sdcard/Open-GApps/rem.prop
	cp /tmp/aroma/extra.prop /sdcard/Open-GApps/extra.prop
	;;
	load)
	[ -f /sdcard/Open-GApps/aromagapps.prop ] && rm -f /tmp/aroma/aromagapps.prop && cp /sdcard/Open-GApps/aromagapps.prop /tmp/aroma/aromagapps.prop
	[ -f /sdcard/Open-GApps/bypass.prop ] && rm -f /tmp/aroma/bypass.prop && cp /sdcard/Open-GApps/bypass.prop /tmp/aroma/bypass.prop
	[ -f /sdcard/Open-GApps/rem.prop ] && rm -f /tmp/aroma/rem.prop && cp /sdcard/Open-GApps/rem.prop /tmp/aroma/rem.prop
	[ -f /sdcard/Open-GApps/extra.prop ] && rm -f /tmp/aroma/extra.prop && cp /sdcard/Open-GApps/extra.prop /tmp/aroma/extra.prop
	;;
	reset)
	rm -f /tmp/aroma/aromagapps.prop
	rm -f /tmp/aroma/bypass.prop
	rm -f /tmp/aroma/rem.prop
	rm -f /tmp/aroma/extra.prop
	;;
esac
