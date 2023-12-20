//
//  AppDelegate.m
//  SampleObjC
//
//  Created by Pallab Maiti on 19/06/23.
//

#import "AppDelegate.h"

@import MetricsReporter;
@import RudderKit;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    RSMetricConfiguration *config = [[RSMetricConfiguration alloc] initWithLogLevel:RudderLogLevelVerbose writeKey:@"WRITE_KEY" sdkVersion:@"1.1.1"];
    RSMetricsClient *client = [[RSMetricsClient alloc] initWithConfiguration:config];
    
    RSCount *count = [[RSCount alloc] initWithName:@"test_count" labels:@{@"key_1": @"value_1"} value:10];
    [client process:count];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
