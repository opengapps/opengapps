Getting Started
---------------

To get started with building PA Gapps, you'll need to get the git sources:

To initialize your local repository using the PA Gapps trees, use a command like:
```
git clone git@github.com:pagapps/pagapps.git
```
Then sync the submodules to get the original APK sources as provided by Google.
You can also use this command to update at a later moment the sources to the most recent version
```
./download_sources.sh
```

To build PA GApps for all platforms and all android releases:
```
make
```
To build PA GApps for a specific android release on a specific platform,
define both the platform and the API level of that release, seperated by a dash.
A (most widely used) example:
```
make arm-22
```
One can update the sources used with the command:
```
./add_sourceapp.sh /path/to/the/file/you/want/to/add.apk [/even/more/files.apk...]
```
For contributors, these can be uploaded, by browsing to one of the sources-subdirectories and pushing it to the repository.
```
cd sources/architecture
git commit -a
git push
```
