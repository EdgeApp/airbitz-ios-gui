source 'https://github.com/CocoaPods/Specs.git'

def import_pods
    pod 'Reachability', '~>3.2'
    pod "AFNetworking", "~> 2.0"
    #pod 'AirbitzCore', :http => "https://developer.airbitz.co/download/airbitz-core-objc-newest.tgz"
    pod 'AirbitzCore', :path => '../airbitz-core-objc/'
end

def import_pods_ios
    pod "ZBarSDK", "~> 1.3"
    pod 'SDWebImage', '~>3.6'
end

target "Airbitz" do
    platform :ios, '8.0'
    import_pods
    import_pods_ios
end

target "Airbitz-Develop" do
    import_pods
    import_pods_ios
end

target "Airbitz-Testnet" do
    import_pods
    import_pods_ios
end

target 'Airbitz-OSX' do
    platform :osx, '10.9'
    import_pods
end
