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
CERTIFICATES="$SCRIPTS/certificates"
alignbuild() {
	for f in $(find "$build" -name '*.apk'); do
		mv "$f" "$f.orig"
		zipalign 4 "$f.orig" "$f"
		rm "$f.orig"
	done
}

commonscripts() {
	install -d "$build/META-INF/com/google/android"
	echo "# Dummy file; update-binary is a shell script.">"$build/META-INF/com/google/android/updater-script"
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
	install -d "$build/META-INF/com/google/android/aroma #not necessary, but is safe"
	copy "$SCRIPTS/aroma-resources/fonts" "$build/META-INF/com/google/android/aroma/fonts"
	copy "$SCRIPTS/aroma-resources/icons" "$build/META-INF/com/google/android/aroma/icons"
	copy "$SCRIPTS/aroma-resources/langs" "$build/META-INF/com/google/android/aroma/langs"
	copy "$SCRIPTS/aroma-resources/scripts" "$build/META-INF/com/google/android/aroma/scripts"
	copy "$SCRIPTS/aroma-resources/themes" "$build/META-INF/com/google/android/aroma/themes"
	copy "$SCRIPTS/aroma-resources/ttf" "$build/META-INF/com/google/android/aroma/ttf"
	copy "$SCRIPTS/aroma-resources/open.png" "$build/META-INF/com/google/android/aroma"
}

aromaupdatebinary() {
	if [ -f "$build/META-INF/com/google/android/update-binary-installer" ]
	then
		rm "$build/META-INF/com/google/android/update-binary-installer"
	fi
	mv "$build/META-INF/com/google/android/update-binary" "$build/META-INF/com/google/android/update-binary-installer"
	copy "$SCRIPTS/aroma-resources/update-binary" "$build/META-INF/com/google/android/update-binary"
}

createzip() {
	find "$build" -exec touch -d "2008-02-28 21:33:46.000000000 +0100" {} \;
	cd "$build"
	for d in $(ls -d */ | grep -v "META-INF"); do #notice that d will end with a slash, ls is safe here because there are no directories with spaces
		cd "$build/$d"
		for f in $(ls); do # ls is safe here because there are no directories with spaces
			for g in $(ls "$f"); do
				foldersize="$(du -ck "$f/$g/" | tail -n1 | awk '{ print $1 }')"
				printf "%s\t%s\t%d\n" "$f" "$g" "$foldersize" >> "$build/app_sizes.txt"
			done
			hash="$(tar -cf - "$f" | md5sum | cut -f1 -d' ')"
			if [ -f "$CACHE/$hash.tar.xz" ]; then #we have this xz in cache
				echo "Fetching $d$f from the cache"
				rm -rf "$f" #remove the folder
				cp "$CACHE/$hash.tar.xz" "$f.tar.xz" #copy from the cache
			else
				echo "Compressing $d$f"
				XZ_OPT=-9e tar --remove-files -cJf "$f.tar.xz" "$f"
				cp "$f.tar.xz" "$CACHE/$hash.tar.xz" #copy into the cache
			fi
			touch -d "2008-02-28 21:33:46.000000000 +0100" "$f.tar.xz"
		done
	done

	unsignedzip="$BUILD/$ARCH/$API/$VARIANT.zip"
	signedzip="$OUT/open_gapps-$ARCH-$PLATFORM-$VARIANT-$DATE.zip"

	if [ -f "$unsignedzip" ]
	then
		rm "$unsignedzip"
	fi
	cd "$build"
	echo "Packaging and signing $signedzip..."
	# Store only the files in the zip without compressing them (-0 switch): further compression will be useless and will slow down the building process
	zip -q -r -D -X -0 "$unsignedzip" ./* #don't doublequote zipfolders, contains multiple (safe) arguments
	cd "$TOP"
	signzip
}

signzip() {
	install -d "$OUT"
	if [ -f "$signedzip" ]
	then
		rm "$signedzip"
	fi

	if java -jar "$SCRIPTS/inc.signapk.jar" -w "$CERTIFICATES/testkey.x509.pem" "$CERTIFICATES/testkey.pk8" "$unsignedzip" "$signedzip"; then #if signing did succeed
		rm "$unsignedzip"
	else
		echo "ERROR: Creating Flashable ZIP-file failed"
		exit 1
	fi
	echo "SUCCESS: Built Open GApps variation $VARIANT with API $API level for $ARCH as $signedzip"
}
