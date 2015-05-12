Getting Started
---------------

To get started with building PA Gapps, you'll need to get the git sources:

To initialize your local repository using the PA Gapps trees, use a command like:
```
git clone git@github.com:pagapps/pagapps.git
```
Then sync the submodules to get the original APK sources as provided by Google
```
git submodule update --init --recursive
```

To update at a later moment your sources again with the latest revision:
```
git pull
git submodule foreach git pull origin master
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
