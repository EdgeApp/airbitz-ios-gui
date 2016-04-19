source 'https://github.com/CocoaPods/Specs.git'

def import_pods
    pod 'Reachability', '~>3.2'
    pod "AFNetworking", "~> 2.0"
    #pod 'AirbitzCore', :http => "https://developer.airbitz.co/download/airbitz-core-objc-newest.tgz"
    pod 'AirbitzCore', :path => '../airbitz-core-objc/'
end

target :ios do
    platform :ios, '8.0'
    pod 'SDWebImage', '~>3.6'
    link_with 'Airbitz', 'Airbitz-Develop', 'Airbitz-Testnet'
    import_pods
end

target :osx do
    platform :osx, '10.9'
    link_with 'Airbitz-OSX'
    import_pods
end



