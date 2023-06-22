//
//  Bugsnag.m
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

#import "RSCrashReporter.h"

#import "BSGStorageMigratorV0V1.h"
#import "Bugsnag+Private.h"
#import "BugsnagBreadcrumbs.h"
#import "BugsnagClient+Private.h"
#import "BugsnagInternals.h"
#import "BugsnagLogger.h"

static BugsnagClient *bsg_g_bugsnag_client = NULL;

BSG_OBJC_DIRECT_MEMBERS
@implementation RSCrashReporter

+ (void)startWithDelegate:(id<RSCrashReporterNotifyDelegate> _Nullable)delegate {
    @synchronized(self) {
        if (bsg_g_bugsnag_client == nil) {
            [BSGStorageMigratorV0V1 migrate];
            bsg_g_bugsnag_client = [[BugsnagClient alloc] initWithConfiguration:[BugsnagConfiguration loadConfig] delegate:delegate];
            [bsg_g_bugsnag_client start];
        } else {
            bsg_log_warn(@"Multiple RSCrashReporter.start calls detected. Ignoring.");
        }
    }
}

/**
 * Purge the global client so that it will be regenerated on the next call to start.
 * This is only used by the unit tests.
 */

+ (void)purge {
    bsg_g_bugsnag_client = nil;
}

+ (BugsnagClient *)client {
    return bsg_g_bugsnag_client;
}

+ (void)notifyError:(NSError *)error {
    if ([self bugsnagReadyForInternalCalls]) {
        [self.client notifyError:error];
    }
}

+ (void)notifyError:(NSError *)error block:(BugsnagOnErrorBlock)block {
    if ([self bugsnagReadyForInternalCalls]) {
        [self.client notifyError:error block:block];
    }
}

+ (BOOL)bugsnagReadyForInternalCalls {
    if (!self.client.readyForInternalCalls) {
        return NO;
    }
    return YES;
}

+ (void)leaveBreadcrumbWithMessage:(NSString *)message {
    if ([self bugsnagReadyForInternalCalls]) {
        [self.client leaveBreadcrumbWithMessage:message];
    }
}

+ (void)leaveBreadcrumbForNotificationName:
    (NSString *_Nonnull)notificationName {
    if ([self bugsnagReadyForInternalCalls]) {
        [self.client leaveBreadcrumbForNotificationName:notificationName];
    }
}

+ (void)leaveBreadcrumbWithMessage:(NSString *_Nonnull)message
                          metadata:(NSDictionary *_Nullable)metadata
                           andType:(BSGBreadcrumbType)type
{
    if ([self bugsnagReadyForInternalCalls]) {
        [self.client leaveBreadcrumbWithMessage:message
                                       metadata:metadata
                                        andType:type];
    }
}

+ (void)leaveNetworkRequestBreadcrumbForTask:(NSURLSessionTask *)task
                                     metrics:(NSURLSessionTaskMetrics *)metrics {
    if ([self bugsnagReadyForInternalCalls]) {
        [self.client leaveNetworkRequestBreadcrumbForTask:task metrics:metrics];
    }
}

+ (NSArray<BugsnagBreadcrumb *> *_Nonnull)breadcrumbs {
    if ([self bugsnagReadyForInternalCalls]) {
        return self.client.breadcrumbs;
    } else {
        return @[];
    }
}

@end
