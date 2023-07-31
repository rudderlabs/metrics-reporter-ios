source 'https://github.com/rudderlabs/Specs.git'
workspace 'MetricsReporter.xcworkspace'
use_frameworks!
inhibit_all_warnings!
install! 'cocoapods', :warn_for_unused_master_specs_repo => false

def shared_pods
    pod 'MetricsReporter', :path => '.'
end

def shared_dependent_pods
    pod 'RSCrashReporter', :path => '/Users/pallabmaiti/Documents/Rudder/crash-reporter-ios'
    pod 'RudderKit', '~> 1.4.0'
end

target 'MetricsReporter-iOS' do
    project 'MetricsReporter.xcodeproj'
    platform :ios, '12.0'
    shared_dependent_pods
    target 'MetricsReporterTests-iOS' do
        inherit! :search_paths
        shared_dependent_pods
    end
end

target 'MetricsReporter-tvOS' do
    project 'MetricsReporter.xcodeproj'
    platform :tvos, '11.0'
    shared_dependent_pods
    target 'MetricsReporterTests-tvOS' do
        inherit! :search_paths
        shared_dependent_pods
    end
end

target 'MetricsReporter-watchOS' do
    project 'MetricsReporter.xcodeproj'
    platform :watchos, '7.0'
    shared_dependent_pods
    target 'MetricsReporterTests-watchOS' do
        inherit! :search_paths
        shared_dependent_pods
    end
end

target 'MetricsReporter-macOS' do
    project 'MetricsReporter.xcodeproj'
    platform :macos, '10.13'
    shared_dependent_pods
    target 'MetricsReporterTests-macOS' do
        inherit! :search_paths
        shared_dependent_pods
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
