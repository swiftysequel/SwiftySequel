install! 'cocoapods', :disable_input_output_paths => true
platform :osx, '10.14'
swift_version = '5.0'
use_frameworks!

def testing_pods
    pod 'Nimble', '~> 8.0', :configurations => ['Debug'], :inhibit_warnings => true
    pod 'Quick', '~> 2.1', :configurations => ['Debug'], :inhibit_warnings => true
end

target 'SwiftySequel' do
    # Dev dependencies
    pod 'PickwareStyleGuide', :git => 'git@github.com:VIISON/style-guide.git', :branch => 'master'

    # Public pods
    pod 'CocoaLumberjack/Swift', '~> 3.5', :inhibit_warnings => true
    pod 'PromiseKit', '~> 6.8', :inhibit_warnings => true
    pod 'RxSwift', '~> 5.0', :inhibit_warnings => true

    target 'SwiftySequelTests' do
        inherit! :search_paths
        testing_pods
    end
end

target 'SwiftySequelUITests' do
    testing_pods
end
