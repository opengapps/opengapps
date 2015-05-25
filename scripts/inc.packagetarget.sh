#This file is part of The PA GApps script of @mfonville.
#
#    The PA GApps scripts are free software: you can redistribute it and/or modify
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

addpackagescripts() {
	install -d "$build"META-INF/com/google/android
	echo "# Dummy file; update-binary is a shell script.">"$build"META-INF/com/google/android/updater-script
	makeupdatebinary
	makegappsremovetxt
	makegprop
	makesizesprop
	makeinstallerdata
	copy "$SCRIPTS/bkup_tail.sh" "$build"
}

createzip() {
	if [ -f "$unsignedzip" ]
	then
		rm "$unsignedzip"
	fi
	cd "$build"
	zip -q -r -D -X -9 "$unsignedzip" Core GApps GMSCore Optional PlayGames META-INF bkup_tail.sh g.prop gapps-remove.txt installer.data sizes.prop
	cd "$TOP"
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
	echo "SUCCESS: Built PA GApps with API $API level for $ARCH as $signedzip"
}
