#This file is part of The Open GApps script of @mfonville.
#
#	The Open GApps scripts are free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	These scripts are distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#

alignbuild() {
	for f in $(find "$build" -name '*.apk'); do
		mv "$f" "$f.orig"
		zipalign 4 "$f.orig" "$f"
		rm "$f.orig"
	done
}

commonscripts() {
	install -d "$build"META-INF/com/google/android
	echo "# Dummy file; update-binary is a shell script.">"$build"META-INF/com/google/android/updater-script
	makegappsremovetxt
	copy "$SCRIPTS/bkup_tail.sh" "$build"
}

variantscripts() {
	makeupdatebinary
	makegprop
	makeinstallerdata
}

aromascripts() {
	aromaupdatebinary
	makearomaconfig
	install -d "$build"META-INF/com/google/android/aroma #not necessary, but is safe
	copy "$SCRIPTS/aroma-resources/fonts" "$build"META-INF/com/google/android/aroma/fonts
	copy "$SCRIPTS/aroma-resources/icons" "$build"META-INF/com/google/android/aroma/icons
	copy "$SCRIPTS/aroma-resources/langs" "$build"META-INF/com/google/android/aroma/langs
	copy "$SCRIPTS/aroma-resources/scripts" "$build"META-INF/com/google/android/aroma/scripts
	copy "$SCRIPTS/aroma-resources/themes" "$build"META-INF/com/google/android/aroma/themes
	copy "$SCRIPTS/aroma-resources/ttf" "$build"META-INF/com/google/android/aroma/ttf
	copy "$SCRIPTS/aroma-resources/open.png" "$build"META-INF/com/google/android/aroma
}

aromaupdatebinary() {
	if [ -f "$build"META-INF/com/google/android/update-binary-installer ]
	then
		rm "$build"META-INF/com/google/android/update-binary-installer
	fi
	mv "$build"META-INF/com/google/android/update-binary "$build"META-INF/com/google/android/update-binary-installer
	copy "$SCRIPTS/aroma-resources/update-binary" "$build"META-INF/com/google/android/update-binary
}

createzip() {
	echo "Compressing apps in tar.xz archives..."
	cd "$build"Core
	for f in $(ls); do # ls is safe here because there are no directories with spaces
		echo "Compressing Core/$f"
		XZ_OPT=-9e tar --remove-files -cJf "$f.tar.xz" "$f"
	done
	cd "$build"GApps
	for f in $(ls); do # ls is safe here because there are no directories with spaces
		echo "Compressing GApps/$f"
		XZ_OPT=-9e tar --remove-files -cJf "$f.tar.xz" "$f"
	done
	if [ "$API" -gt "19" ]; then
		cd "$build"Optional
		for f in $(ls); do # ls is safe here because there are no directories with spaces
			echo "Compressing Optional/$f"
			XZ_OPT=-9e tar --remove-files -cJf "$f.tar.xz" "$f"
		done
	fi

	unsignedzip="$BUILD/$ARCH/$API/$VARIANT.zip"
	signedzip="$OUT/open_gapps-$ARCH-$PLATFORM-$VARIANT-$DATE.zip"

	zipfolders="Core GApps META-INF bkup_tail.sh g.prop gapps-remove.txt installer.data app_densities.txt"
	if [ "$API" -gt "19" ]; then
		zipfolders="$zipfolders Optional"
	fi

	if [ -f "$unsignedzip" ]
	then
		rm "$unsignedzip"
	fi
	cd "$build"
	echo "Packaging and signing $signedzip..."
	# Store only the files in the zip without compressing them (-0 switch): further compression will be useless and will slow down the building process
	zip -q -r -D -X -0 "$unsignedzip" $zipfolders #don't doublequote zipfolders, contains multiple (safe) arguments
	cd "$TOP"
	signzip
}

signzip() {
	install -d "$OUT"
	if [ -f "$signedzip" ]
	then
		rm "$signedzip"
	fi

	cd "$SCRIPTS"
	if ./inc.signapk.sh -q sign "$unsignedzip" "$signedzip"; then #if signing did succeed
		rm "$unsignedzip"
	else
		echo "ERROR: Creating Flashable ZIP-file failed"
		cd "$TOP"
		exit 1
	fi
	cd "$TOP"
	echo "SUCCESS: Built Open GApps variation $VARIANT with API $API level for $ARCH as $signedzip"
}
