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

    DITTY_PATH=/Projects/Ditty\ Labs/Clients/AirBitz/Project/AirBitz/AirBitz/ABC
    sudo mkdir -p $DITTY_PATH
    sudo cp prefix/arm/armv7/lib/*.a $DITTY_PATH

## Build Airbitz iOS in xcode

    cd $REPO_DIR
    git clone git@github.com:Airbitz/airbitz-ios-gui.git

    # copy headers 
    mkdir airbitz-ios-gui/AirBiz/ABC
    cp $WALLET_CORE/src/*.h airbitz-ios-gui/AirBiz/ABC

    # Fire up in xcode
    open airbitz-ios-gui/AirBitz.xcodeproj

Once in xcode you can run Command-R to run it in an emulator.

