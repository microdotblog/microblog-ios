//
//  RFAppDelegate.m
//  Snippets
//
//  Created by Manton Reece on 6/4/15.
//  Copyright (c) 2015 Riverfold Software. All rights reserved.
//

#import "RFAppDelegate.h"

#import "RFTimelineController.h"

@implementation RFAppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[self setupWindow];
	
	return YES;
}

- (void) applicationWillResignActive:(UIApplication *)application
{
}

- (void) applicationDidEnterBackground:(UIApplication *)application
{
}

- (void) applicationWillEnterForeground:(UIApplication *)application
{
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
}

- (void) applicationWillTerminate:(UIApplication *)application
{
}

#pragma mark -

- (void) setupWindow
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.timelineController = [[RFTimelineController alloc] init];

    [self.window makeKeyAndVisible];
	[self.window setRootViewController:self.timelineController];
}

@end
