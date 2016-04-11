# Airbitz iOS

## Build Airbitz iOS in xcode

    cd $REPO_DIR
    git clone git@github.com:Airbitz/airbitz-ios-gui.git
    
    cd Airbitz
    cp Config.h.example Config.h

Paste API keys from Airbitz into Config.h fields.
API keys for Airbitz Core can be obtained from 
https://developer.airbitz.co

Install Cocoapods

    sudo gem install cocoapods
    
Update Airbitz 'Podfile' to pull AirbitzCore from developer.airbitz.co

Uncomment the following line from 'airbitz-ios-gui/Podfile'

    pod 'AirbitzCore', :http => "https://developer.airbitz.co/download/airbitz-core-objc-newest.tgz"
    
Comment out the following line

    pod 'AirbitzCore', :path => '../airbitz-core-objc/'

Install the pods

    pod install

Fire up the xcode project

    open airbitz-ios-gui/AirBitz.xcworkspace

Once in xcode you can run Command-R to run it in an emulator.

