//
//  RSCrashReporter.h
//
//  Created by Conrad Irwin on 2014-10-01.
//
//  Copyright (c) 2014 Bugsnag, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import <Foundation/Foundation.h>

#import <RSCrashReporter/BugsnagApp.h>
#import <RSCrashReporter/BugsnagAppWithState.h>
#import <RSCrashReporter/BugsnagClient.h>
#import <RSCrashReporter/BugsnagConfiguration.h>
#import <RSCrashReporter/BugsnagDefines.h>
#import <RSCrashReporter/BugsnagDevice.h>
#import <RSCrashReporter/BugsnagDeviceWithState.h>
#import <RSCrashReporter/BugsnagEndpointConfiguration.h>
#import <RSCrashReporter/BugsnagError.h>
#import <RSCrashReporter/BugsnagErrorTypes.h>
#import <RSCrashReporter/BugsnagEvent.h>
#import <RSCrashReporter/BugsnagFeatureFlag.h>
#import <RSCrashReporter/BugsnagLastRunInfo.h>
#import <RSCrashReporter/BugsnagMetadata.h>
#import <RSCrashReporter/BugsnagPlugin.h>
#import <RSCrashReporter/BugsnagSession.h>
#import <RSCrashReporter/BugsnagStackframe.h>
#import <RSCrashReporter/BugsnagThread.h>

/**
 * Static access to a RSCrashReporter Client, the easiest way to use RSCrashReporter in your app.
 */
BUGSNAG_EXTERN
@interface RSCrashReporter : NSObject 

/**
 * All RSCrashReporter access is class-level.  Prevent the creation of instances.
 */
- (instancetype _Nonnull )init NS_UNAVAILABLE NS_SWIFT_UNAVAILABLE("Use class methods to initialise Bugsnag.");

/**
 * Start listening for crashes.
 *
 * This method initializes RSCrashReporter.
 *
 * Once successfully initialized, NSExceptions, C++ exceptions, Mach exceptions and
 * signals will be logged to disk before your app crashes. The next time your app
 * launches, these reports will be sent to you.
 */

+ (void)startWithDelegate:(id<RSCrashReporterNotifyDelegate> _Nullable)delegate;

// =============================================================================
// MARK: - Breadcrumbs
// =============================================================================

/**
 * Leave a "breadcrumb" log message, representing an action that occurred
 * in your app, to aid with debugging.
 *
 * @param message  the log message to leave
 */
+ (void)leaveBreadcrumbWithMessage:(NSString *_Nonnull)message;

/**
 *  Leave a "breadcrumb" log message each time a notification with a provided
 *  name is received by the application
 *
 *  @param notificationName name of the notification to capture
 */
+ (void)leaveBreadcrumbForNotificationName:(NSString *_Nonnull)notificationName;

/**
 * Leave a "breadcrumb" log message, representing an action that occurred
 * in your app, to aid with debugging, along with additional metadata and
 * a type.
 *
 * @param message The log message to leave.
 * @param metadata Diagnostic data relating to the breadcrumb.
 *                 Values should be serializable to JSON with NSJSONSerialization.
 * @param type A BSGBreadcrumbTypeValue denoting the type of breadcrumb.
 */
+ (void)leaveBreadcrumbWithMessage:(NSString *_Nonnull)message
                          metadata:(NSDictionary *_Nullable)metadata
                           andType:(BSGBreadcrumbType)type
    NS_SWIFT_NAME(leaveBreadcrumb(_:metadata:type:));

/**
 * Leave a "breadcrumb" log message representing a completed network request.
 */
+ (void)leaveNetworkRequestBreadcrumbForTask:(nonnull NSURLSessionTask *)task
                                     metrics:(nonnull NSURLSessionTaskMetrics *)metrics
    API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0))
    NS_SWIFT_NAME(leaveNetworkRequestBreadcrumb(task:metrics:));

/**
 * Returns the current buffer of breadcrumbs that will be sent with captured events. This
 * ordered list represents the most recent breadcrumbs to be captured up to the limit
 * set in `BugsnagConfiguration.maxBreadcrumbs`
 */
+ (NSArray<BugsnagBreadcrumb *> *_Nonnull)breadcrumbs;

@end
