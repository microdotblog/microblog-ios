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
#import "RFUserController.h"
#import "RFPostController.h"
#import "RFOptionsController.h"
#import "RFClient.h"
#import "RFConstants.h"
#import "SSKeychain.h"
#import "UUAlert.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@implementation RFAppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[self setupCrashlytics];
	[self setupWindow];
	[self setupAppearance];
	[self setupNotifications];
	[self setupShortcuts];
	
	return YES;
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	NSString* param = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
	if ([url.host isEqualToString:@"open"]) {
		[self showOptionsMenuWithPostID:param];
	}
	else if ([url.host isEqualToString:@"user"]) {
		[self showProfileWithUsername:param];
	}
	else if ([url.host isEqualToString:@"conversation"]) {
		[self showConversationWithPostID:param];
	}
	else if ([url.host isEqualToString:@"signin"]) {
		[self showSigninWithToken:param];
	}
	
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

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	const unsigned *bytes = [(NSData *)deviceToken bytes]; // borrowed from mattt's Orbiter
	NSString* token_s = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x", ntohl(bytes[0]), ntohl(bytes[1]), ntohl(bytes[2]), ntohl(bytes[3]), ntohl(bytes[4]), ntohl(bytes[5]), ntohl(bytes[6]), ntohl(bytes[7])];

#if APPSTORE
	NSDictionary* args = @{
		@"push_env": @"prod",
		@"device_token": token_s
	};
#else
	NSDictionary* args = @{
		@"push_env": @"dev",
		@"device_token": token_s
	};
#endif
	
	RFClient* client = [[RFClient alloc] initWithPath:@"/users/push/register"];
	[client postWithParams:args completion:^(UUHttpResponse* response) {
	}];
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	if (application.applicationState == UIApplicationStateActive) {
		NSString* message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
		[UIAlertView uuShowOneButtonAlert:@"" message:message button:@"OK" completionHandler:NULL];
	}
}

- (void) application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))handler
{
	if ([self hasValidToken] && [shortcutItem.type isEqualToString:kShortcutActionNewPost]) {
		[self.timelineController promptNewPost:nil];
		handler (YES);
	}
	else {
		handler (NO);
	}
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
	if ([self hasValidToken]) {
		[self setupPushNotifications];
	}
	else {
		[self setupSignin];
	}
}

- (void) setupPushNotifications
{
	UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert categories:nil];
	[[UIApplication sharedApplication] registerUserNotificationSettings:settings];
	[[UIApplication sharedApplication] registerForRemoteNotifications];
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
	self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.menuController];
	[self.navigationController pushViewController:self.timelineController animated:NO];

    [self.window makeKeyAndVisible];
	[self.window setRootViewController:self.navigationController];
}

- (void) setupSignin
{
	[self setupSigninWithToken:@""];
}

- (void) setupSigninWithToken:(NSString *)appToken
{
	if (self.signInController == nil) {
		self.signInController = [[RFSignInController alloc] init];
		UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:self.signInController];
		[self.menuController.navigationController presentViewController:nav_controller animated:YES completion:NULL];
	}
	
	[self.signInController updateToken:appToken];
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSigninNotification:) name:kShowSigninNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showConversationNotification:) name:kShowConversationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showReplyPostNotification:) name:kShowReplyPostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postWasUnselectedNotification:) name:kPostWasUnselectedNotification object:nil];
}

- (void) setupShortcuts
{
	UIApplicationShortcutIcon* post_icon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"new_button"];
	UIApplicationShortcutItem* post_item = [[UIApplicationShortcutItem alloc] initWithType:kShortcutActionNewPost localizedTitle:@"New Post" localizedSubtitle:@"Post to your microblog" icon:post_icon userInfo:nil];
	[[UIApplication sharedApplication] setShortcutItems:@[ post_item ]];
}

#pragma mark -

- (void) showSigninNotification:(NSNotification *)notification
{
	self.signInController = nil;
	[self setupSignin];
}

- (void) showConversationNotification:(NSNotification *)notification
{
	NSString* post_id = [notification.userInfo objectForKey:kShowConversationPostIDKey];
	[self showConversationWithPostID:post_id];
}

- (void) showReplyPostNotification:(NSNotification *)notification
{
	NSString* post_id = [notification.userInfo objectForKey:kShowReplyPostIDKey];
	NSString* username = [notification.userInfo objectForKey:kShowReplyPostUsernameKey];
	RFPostController* post_controller = [[RFPostController alloc] initWithReplyTo:post_id replyUsername:username];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:post_controller];
	[self.navigationController presentViewController:nav_controller animated:YES completion:NULL];
}

- (void) postWasUnselectedNotification:(NSNotification *)notification
{
	NSString* post_id = [notification.userInfo objectForKey:kPostNotificationPostIDKey];
	RFTimelineController* timeline_controller = (RFTimelineController *) self.navigationController.topViewController;
	if ([timeline_controller isKindOfClass:[RFTimelineController class]]) {
		[timeline_controller setSelected:NO withPostID:post_id];
	}
}

- (void) showOptionsMenuWithPostID:(NSString *)postID
{
	RFTimelineController* timeline_controller = (RFTimelineController *) self.navigationController.topViewController;
	if ([timeline_controller isKindOfClass:[RFTimelineController class]]) {
		[timeline_controller setSelected:YES withPostID:postID];
		CGRect r = [timeline_controller rectOfPostID:postID];
		RFOptionsPopoverType popover_type = [timeline_controller popoverTypeOfPostID:postID];
		NSString* username = [timeline_controller usernameOfPostID:postID];
		RFOptionsController* options_controller = [[RFOptionsController alloc] initWithPostID:postID username:username popoverType:popover_type];
		[options_controller attachToView:timeline_controller.webView atRect:r];
		[self.navigationController presentViewController:options_controller animated:YES completion:NULL];
	}
}

- (void) showConversationWithPostID:(NSString *)postID
{
	NSString* path = [NSString stringWithFormat:@"/iphone/conversation/%@", postID];
	RFTimelineController* conversation_controller = [[RFTimelineController alloc] initWithEndpoint:path title:@"Conversation"];
	[self.navigationController pushViewController:conversation_controller animated:YES];
}

- (void) showProfileWithUsername:(NSString *)username
{
	NSString* path = [NSString stringWithFormat:@"/iphone/posts/%@", username];
	RFUserController* user_controller = [[RFUserController alloc] initWithEndpoint:path title:username];
	[self.navigationController pushViewController:user_controller animated:YES];
}

- (void) showSigninWithToken:(NSString *)appToken
{
	[self setupSigninWithToken:appToken];
}

- (BOOL) hasValidToken
{
	NSString* token = [SSKeychain passwordForService:@"Snippets" account:@"default"];
	return (token != nil);
}

@end
