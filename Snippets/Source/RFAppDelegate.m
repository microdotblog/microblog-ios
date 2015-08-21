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
#import "SSKeychain.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@implementation RFAppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[self setupCrashlytics];
	[self setupWindow];
	[self setupAppearance];
	
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

- (void) setupCrashlytics
{
	[Fabric with:@[ CrashlyticsKit ]];
}

- (void) setupWindow
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	[self setupTimeline];
	NSString* token = [SSKeychain passwordForService:@"Snippets" account:@"default"];
	if (token == nil) {
		[self setupSignin];
	}
}

- (void) setupAppearance
{
	[[UINavigationBar appearance] setTitleTextAttributes:@{
		NSForegroundColorAttributeName: [UIColor colorWithWhite:0.259 alpha:1.000],
		NSFontAttributeName: [UIFont fontWithName:@"Avenir-Light" size:16]
	}];
	[[UIBarButtonItem appearance] setTitleTextAttributes:@{
		NSForegroundColorAttributeName: [UIColor colorWithWhite:0.259 alpha:1.000],
		NSFontAttributeName: [UIFont fontWithName:@"Avenir-Medium" size:16]
	} forState:UIControlStateNormal];
}

- (void) setupTimeline
{
	self.menuController = [[RFMenuController alloc] init];
	self.timelineController = [[RFTimelineController alloc] init];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:self.menuController];
	[nav_controller pushViewController:self.timelineController animated:NO];

    [self.window makeKeyAndVisible];
	[self.window setRootViewController:nav_controller];
}

- (void) setupSignin
{
	self.signInController = [[RFSignInController alloc] init];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:self.signInController];
	[self.menuController.navigationController presentViewController:nav_controller animated:YES completion:NULL];
}

@end
