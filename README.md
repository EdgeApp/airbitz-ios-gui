# Airbitz iOS

## Setup your environment

You will need Xcode to build the environment. First install it! Then run:

    xcode-select --install

Next install [macports](http://www.macports.org/install.php) and then run the
following to obtain all the needed tools.

    sudo port install wget autoconf automake libtool pkgconfig git-core

Lastly fix the certificate authorities for wget

    sudo port install curl-ca-bundle
    echo CA_CERTIFICATE=/opt/local/share/curl/curl-ca-bundle.crt >> ~/.wgetrc

Now setup your working directory.

    REPO_DIR=$HOME/airbitz
    mkdir -p $REPO_DIR
    cd $REPO_DIR

Set your `$REPO_DIR` to whatever you want.

## Setting up airbitz walletcore

    cd $REPO_DIR
    git clone git@github.com:Airbitz/airbitz-walletcore.git
    cd airbitz-walletcore
    WALLET_CORE=`pwd`
    cd deps
    make

## Build Airbitz iOS in xcode

    cd $REPO_DIR
    git clone git@github.com:Airbitz/airbitz-ios-gui.git

    # Copy files into project
    cp $WALLET_CORE/deps/build/prefix/arm/armv7/lib/*.a AirBitz/ABC/
    cp $WALLET_CORE/deps/build/prefix/arm/armv7/includes/*.h AirBitz/ABC/

    # Fire up in xcode
    open airbitz-ios-gui/AirBitz.xcodeproj

Once in xcode you can run Command-R to run it in an emulator.

