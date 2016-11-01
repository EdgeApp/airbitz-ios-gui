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
    
If you want to use the 'develop' build of `airbitz-core` with functionality of the next release. Use this line instead

    pod 'AirbitzCore', :http => "https://developer.airbitz.co/download/airbitz-core-objc-develop-newest.tgz"

Comment out the following line

    pod 'AirbitzCore', :path => '../airbitz-core-objc/'

Install the pods

    pod install
    
Due to a bug in Cocoapods, you may need to also run 

    xcproj touch
    
This will clear up the project file which gets corrupted by pod install turning the ASCII format into XML

Next fire up the xcode project

    open airbitz-ios-gui/Airbitz.xcworkspace

Once in xcode you can run Command-R to run it in an emulator.

