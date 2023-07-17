source 'https://github.com/CocoaPods/Specs.git'
workspace 'MetricsReporter.xcworkspace'
use_frameworks!
inhibit_all_warnings!

def shared_pods
    pod 'MetricsReporter', :path => '.'
end

target 'MetricsReporter' do
    project 'MetricsReporter.xcodeproj'
    platform :ios, '12.0'
    pod 'RudderKit', '~> 1.2.0'
    target 'MetricsReporterTests' do
        inherit! :search_paths
        pod 'RudderKit', '~> 1.2.0'
    end
end

target 'SampleSwift' do
    project 'Examples/SampleSwift/SampleSwift.xcodeproj'
    platform :ios, '12.0'
    shared_pods
end

target 'SampleObjC' do
    project 'Examples/SampleObjC/SampleObjC.xcodeproj'
    platform :ios, '12.0'
    shared_pods
end
