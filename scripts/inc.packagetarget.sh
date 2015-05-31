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

alignbuild() {
	for f in `find "$build" -name '*.apk'`; do
		mv "$f" "$f.orig"
		zipalign 4 "$f.orig" "$f"
		rm "$f.orig"
	done
}

commonscripts() {
	install -d "$build"META-INF/com/google/android
	echo "# Dummy file; update-binary is a shell script.">"$build"META-INF/com/google/android/updater-script
	makesizesprop
	makegappsremovetxt
	copy "$SCRIPTS/bkup_tail.sh" "$build"
}

variantscripts() {
	makeupdatebinary
	makegprop
	makeinstallerdata
}

createzip() {
	unsignedzip="$BUILD/$ARCH/$API.zip"
	signedzip="$OUT/open_gapps-$ARCH-$PLATFORM-$VARIANT-$DATE.zip"

	case "$VARIANT" in
		stock)	getzipfolders "$STOCK $FULL $MINI $MICRO $NANO $PICO";;
		full)	getzipfolders "$FULL $MINI $MICRO $NANO $PICO";;
		mini)	getzipfolders "$MINI $MICRO $NANO $PICO";;
		micro)	getzipfolders "$MICRO $NANO $PICO";;
		nano)	getzipfolders "$NANO $PICO";;
		pico)	getzipfolders "$PICO";;
	esac

	if [ -f "$unsignedzip" ]
	then
		rm "$unsignedzip"
	fi
	cd "$build"
	zip -q -r -D -X -9 "$unsignedzip" $zipfolders 
	cd "$TOP"
	signzip
}

getzipfolders() {
	zipfolders="Core GMSCore Optional META-INF bkup_tail.sh g.prop gapps-remove.txt installer.data sizes.prop"
	for app in $1; do
		case "$app" in
		messenger)	zipfolders="$zipfolders Messenger";;
		playgames)	zipfolders="$zipfolders PlayGames";;
		*)		zipfolders="$zipfolders GApps/$app";;
		esac
	done
}

signzip() {	
	install -d "$OUT"
	if [ -f "$signedzip" ]
	then
		rm "$signedzip"
	fi

	cd "$SCRIPTS"
	./inc.signapk.sh -q sign "$unsignedzip" "$signedzip"
	if [ $? -eq 0 ]; then #if signing did succeed
	    rm "$unsignedzip"
	else
		echo "ERROR: Creating Flashable ZIP-file failed"
		cd "$TOP"
		exit 1
	fi
	cd "$TOP"
	echo "SUCCESS: Built Open GApps variation $VARIANT with API $API level for $ARCH as $signedzip"
}
