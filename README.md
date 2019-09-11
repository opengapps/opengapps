# Open GApps

## Getting the latest pre-built Open GApps

The latest version of pre-built Open GApps can be found at <https://opengapps.org>, hosted on SourceForge.

|                                                                             [Support Project](http://opengapps.org/donate) | [![Donate](https://img.shields.io/badge/donate-on%20paypal-009cde.svg?maxAge=86400)](http://opengapps.org/donate)                                                     |
| -------------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|                                                      [Q&A Forum](http://forum.xda-developers.com/showthread.php?t=3124506) | [![XDA Q&A](https://img.shields.io/badge/Q%26A-on%20xda-de7300.svg?maxAge=86400)](http://forum.xda-developers.com/showthread.php?t=3124506)                           |
|                                  [Development Forum](http://forum.xda-developers.com/android/software/Open-GApps-t3098071) | [![XDA Development](https://img.shields.io/badge/development-on%20xda-de7300.svg?maxAge=86400)](http://forum.xda-developers.com/android/software/Open-GApps-t3098071) |
|                                                                        [Support Chat](https://gitter.im/opengapps/general) | [![Gitter](https://img.shields.io/gitter/room/opengapps/general.js.svg?maxAge=86400)](https://gitter.im/opengapps/general)                                            |
| [![Download OpenGApps](https://sourceforge.net/sflogo.php?type=13&group_id=3112703)](https://sourceforge.net/p/opengapps/) | [![Download OpenGApps](https://img.shields.io/sourceforge/dd/opengapps.svg)](https://sourceforge.net/projects/opengapps/files/)                                       |

## Support for the pre-built packages from OpenGApps.org

If you have any questions, check out the [Open GApps Wiki](https://github.com/opengapps/opengapps/wiki), especially the [FAQ](https://github.com/opengapps/opengapps/wiki/FAQ) since it'd answer most of the questions.
If you can't find the answer to your question use the [XDA Q&A Thread](http://forum.xda-developers.com/showthread.php?t=3124506) or join us on [Gitter](https://gitter.im/opengapps/general) to receive support. *Don't forget to add at least the Open GApps installer debug log and if experiencing Force Closures also include a logcat*.

If you did find a bug in the Pre-built OpenGApps.org packages you can report it at the [XDA Open GApps Development Thread](http://forum.xda-developers.com/android/software/Open-GApps-t3098071). *Remember to include at minimum the Open GApps installer debug log and if applicable a logcat*.

Please **don't** file directly any GitHub issues to file problems with the Pre-built packages. The GitHub issues tracker is only used for issues concerning the Open GApps Project scripts themselves.

## Build your own Open GApps

**The example git commands assume you have a [GitHub account](https://github.com/join) and have set-up [SSH authentication](https://help.github.com/articles/set-up-git/#connecting-over-ssh).**

If you want to build your own version of Open GApps, you'll need to fetch the git sources:

To initialize your local repository using the Open GApps source tree, clone the main repository with the command:

```shellscript
git clone git@github.com:opengapps/opengapps.git
```

Then sync the submodules to get the original APK sources as provided by Google. Take note that these repositories are very large (in the order of GiBs).
You can also use this command to update the sources at a later moment to their most recent version:

```shellscript
./download_sources.sh [--shallow] [arch]
```

* `--shallow` will order to fetch only the latest snapshot of the APKs (reduces space used and amount of data to be retrieved by git, by not fetching the APKs' history)
* `arch` can be one of the following "arm, arm64, x86, x86_64" to fetch only data required for specified architecture (note that fallback architectures will be fetched too)

**To build Open GApps you'll need the Android build tools installed and set-up in your $PATH. If you use Ubuntu you can check out [@mfonville's Android build tools for Ubuntu](http://mfonville.github.io/android-build-tools/).**

To build Open GApps for all platforms and all Android releases:

```shellscript
make
```

To build Open GApps for a specific Android release on a specific platform,
define both the platform and the API level of that release, seperated by a dash and optionally add the variant with another dash.

Two examples (for building for Android 6.0 on ARM):

```shellscript
make arm-23
```

or

```shellscript
make arm-23-stock
```

To add updated source APKs to the sources archive (you can add more than one at once):

```shellscript
./add_sourceapp.sh [/path/to/the/files/you/want/to/add.apk]* [beta] [/apps/that/should/be/marked/as/beta.apk...]*
```

For contributors, updated sources can be uploaded. Either without an argument for every architecture, or with one or more arguments for a subset of architectures:

```shellscript
./upload_sources.sh [archs]*
```

If you want an overview of the locally available sources:

```shellscript
./report_sources.sh
```

You can add extra arguments to report_sources to do your more advanced bidding too:

```shellscript
./report_sources.sh ( ([sdk] [archs]*) || [arch-sdk] ) && [hash] || [max*mb] || [min*mb] || [nobeta] || [nohelp] || [noleanback] || [nosig]
```

## License

The Open GApps Project itself is licensed under the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.txt) with an addendum called the
**Open GApps installable zip exception**.

A short explanation of these license terms and the terms used by the pre-built OpenGApps.org packages:

* The license and its exception are very comparable to the GNU Compiler Collection.
* The Open GApps Project itself is like a "compiler" that is licensed under the GPLv3.
* The "Installable zips" produced by the Open GApps Project is a assorted product of which its components adhere to various different licenses. E.g. the Open GApps installer scripts are still GPLv3 licensed.
* The author of an "installable zip" can choose the license for this assorted end-product themselves, as long as any changes to the version of The Open GApps Project compiler used during the creation of the "installable zip" are published under the GPLv3 with the "installable zip" too. Also the individual components within the "installable zip" are still licensed under their respective terms.
* The pre-built packages from OpenGApps.org are made available under the terms that they can be freely used for personal use only, and are not allowed to be mirrored to the public other than OpenGApps.org
