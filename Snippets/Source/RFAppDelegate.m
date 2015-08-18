//
//  RFAppDelegate.m
//  Snippets
//
//  Created by Manton Reece on 6/4/15.
//  Copyright (c) 2015 Riverfold Software. All rights reserved.
//

#import "RFAppDelegate.h"

#import "RFSignInController.h"
#import "RFMenuController.h"
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
	
	self.menuController = [[RFMenuController alloc] init];
	self.timelineController = [[RFTimelineController alloc] init];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:self.menuController];
	[nav_controller pushViewController:self.timelineController animated:NO];

    [self.window makeKeyAndVisible];
	[self.window setRootViewController:nav_controller];
}

- (void) setupAppearance
{
}

@end
