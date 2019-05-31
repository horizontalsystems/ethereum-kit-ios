#!/bin/sh
set -ex

curl https://gethstore.blob.core.windows.net/builds/geth-ios-all-1.9.0-unstable-30263ad3.tar.gz | tar -xvz
mkdir EthereumKit/Frameworks
mv geth-ios-all-1.9.0-unstable-30263ad3/Geth.framework EthereumKit/Frameworks
rm -rf geth-ios-all-1.9.0-unstable-30263ad3

exit 0
