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
    git clone git@github.com:Airbitz/airbitz-core.git
    cd airbitz-core/abcd
    cp config.h.example config.h

    # Put API keys into fields in config.h

## Build Airbitz iOS in xcode

    cd $REPO_DIR
    git clone git@github.com:Airbitz/airbitz-ios-gui.git
    
    cd AirBitz
    cp Config.h.example Config.h

    # Paste API keys from Airbitz into Config.h fields

    # Go back up one directory
    cd ..

    # Build ABC and Copy files into project. This could take 30-60 mins
    ./mkabc

    # Install the pods
    pod install

    # Fire the xcode project
    open airbitz-ios-gui/AirBitz.xcworkspace

Once in xcode you can run Command-R to run it in an emulator.

