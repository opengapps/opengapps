Getting Started
---------------

To get started with building Open GApps, you'll need to get the git sources:

To initialize your local repository using the Open GApps trees, use a command like:
```
git clone git@github.com:pagapps/pagapps.git
```
Then sync the submodules to get the original APK sources as provided by Google.
You can also use this command to update at a later moment the sources to the most recent version
```
./download_sources.sh
```

To build Open GApps for all platforms and all android releases:
```
make
```
To build Open GApps for a specific android release on a specific platform,
define both the platform and the API level of that release, seperated by a dash.
A (most widely used) example:
```
make arm-22
```
One can update the sources used with the command:
```
./add_sourceapp.sh /path/to/the/file/you/want/to/add.apk [/even/more/files.apk...]
```
Be careful! If add_sourceapp finds multiple architectures in the native code, it expects it to be a 'universal' package. This not always true with 64-bit packages though!
For contributors, updated sources can be uploaded by browsing to one of the sources-subdirectories and pushing it to the repository:
```
cd sources/architecture
git add *
git commit
git push
```
