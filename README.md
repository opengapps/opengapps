Getting the latest pre-built Open GApps
---------------
The latest version of pre-built Open GApps can be found at http://opengapps.org

Support for the pre-built packages from OpenGApps.org
---------------
If you have any questions check out the [Open GApps Wiki](https://github.com/opengapps/opengapps/wiki) especially the [FAQ](https://github.com/opengapps/opengapps/wiki/FAQ) answers most questions.
If you can't find the answer to your question use the [XDA Q&A Thread](http://forum.xda-developers.com/showthread.php?t=3124506) to receive support. *Don't forget to add at least the Open GApps installer debug log and if experiencing Force Closures also include a logcat*.

If you did find a bug in the Pre-built OpenGApps.org packages you can report it at the [XDA Open GApps Development Thread](http://forum.xda-developers.com/android/software/Open-GApps-t3098071). *Also on this thread you need to include at minimum the Open GApps installer debug log and if applicable a logcat*.

Please **don't** file directly any GitHub issues to file problems with the Pre-built packages. The GitHub issues tracker is only used for issues concerning the Open GApps Project scripts themselves.

Build your own Open GApps
---------------
**These scripts assume you have a [GitHub account](https://github.com/join) and have set-up [SSH authentication](https://help.github.com/articles/set-up-git/#connecting-over-ssh).**

If you want to build your own version of Open GApps, you'll need to fetch the git sources:

To initialize your local repository using the Open GApps source tree, use a command like:
```
git clone git@github.com:opengapps/opengapps.git
```
Then sync the submodules to get the original APK sources as provided by Google.
You can also use this command to update the sources at a later moment to their most recent version:
```
./download_sources.sh [--shallow] [arch]
```
* ```--shallow``` will order to fetch only the latest snapshot of the APKs (reduces space used and amount of data to be retrieved by git, by not fetching the APKs' history)
* ```arch``` can be one of the following "arm, arm64, x86, x86_64" to fetch only data required for specified architecture (note that fallback architectures will be be fetched too)

To build Open GApps for all platforms and all Android releases:
```
make
```
To build Open GApps for a specific Android release on a specific platform,
define both the platform and the API level of that release, seperated by a dash and optionally add the variant with another dash.
Two examples (for building for Android 5.1 on ARM):
```
make arm-22
```
or
```
make arm-22-stock
```
To add updated source APKs to the sources archive (you can add more than one at once):
```
./add_sourceapp.sh [/path/to/the/files/you/want/to/add.apk]* [beta] [/apps/that/should/be/marked/as/beta.apk...]*
```
For contributors, updated sources can be uploaded by using this command:
```
./upload_sources.sh
```
If you want an overview of the locally available sources:
```
./report_sources.sh
```
You can add extra arguments to report_sources to do your more advanced bidding too:
```
./report_sources.sh ( ([sdk] [archs]*) || [arch-sdk] ) && [hash] || [nohelp] || [nosig]
```

License
---------------
The Open GApps Project itself is licensed under the GPLv3 with an addendum called the
Open GApps installable zip exception. A short explanation of these license terms and the terms used by the pre-built OpenGApps.org packages:
* The license and its exception are very comparable to the GNU Compiler Collection.
* The Open GApps Project itself is like a "compiler" that is licensed under the GPLv3.
* The "Installable zips" produced by the Open GApps Project is a assorted product of which its components adhere to various different licenses. E.g. the Open GApps installer scripts are still GPLv3 licensed.
* The author of an "installable zip" can choose the license for this assorted end-product themselves, as long as any changes to the version of The Open GApps Project compiler used during the creation of the "installable zip" are published under the GPLv3 with the "installable zip" too. Also the individual components within the "installable zip" are still licensed under their respective terms.
* The pre-built packages from OpenGApps.org are made available under the terms that they can be freely used for personal use only, and are not allowed to be mirrored to the public other than OpenGApps.org
