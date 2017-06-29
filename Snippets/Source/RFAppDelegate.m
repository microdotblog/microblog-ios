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
#import "RFMicropub.h"
#import "RFConstants.h"
#import "RFMacros.h"
#import "SSKeychain.h"
#import "UUAlert.h"
#import "UUString.h"
#import "NSString+Extras.h"
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
	else if ([url.host isEqualToString:@"micropub"]) {
		[self showMicropubWithURL:[url absoluteString]];
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

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler
{
	NSString* post_id = [userInfo[@"post_id"] stringValue];
	if (application.applicationState == UIApplicationStateActive) {
		NSString* message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
		if (post_id.length > 0) {
			[UIAlertView uuShowTwoButtonAlert:@"" message:message buttonOne:@"Cancel" buttonTwo:@"View" completionHandler:^(NSInteger buttonIndex) {
				if (buttonIndex == 1) {
					[self showConversationWithPostID:post_id];
				}
			}];
		}
		else {
			[UIAlertView uuShowOneButtonAlert:@"" message:message button:@"OK" completionHandler:NULL];
		}
	}
	else if (post_id.length > 0) {
		[self showConversationWithPostID:post_id];
	}
}

- (void) application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))handler
{
	if ([self hasValidToken] && [shortcutItem.type isEqualToString:kShortcutActionNewPost]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kOpenPostingNotification object:self];
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
	[self.timelineController loadViewIfNeeded];
	
	self.splitViewController = [[UISplitViewController alloc] init];
	self.splitViewController.delegate = self;
    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

	self.menuNavController = [[UINavigationController alloc] initWithRootViewController:self.menuController];
	self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.timelineController];

	self.splitViewController.viewControllers = @[ self.menuNavController, self.navigationController ];

	[self.window makeKeyAndVisible];
	[self.window setRootViewController:self.splitViewController];

	if (RFIsPhone()) {
		[self.menuNavController pushViewController:self.timelineController animated:NO];
	}
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUserProfileNotification:) name:kShowUserProfileNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showReplyPostNotification:) name:kShowReplyPostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postWasUnselectedNotification:) name:kPostWasUnselectedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetDetailNotification:) name:kResetDetailNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closePostingNotification:) name:kClosePostingNotification object:nil];
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

- (void) showUserProfileNotification:(NSNotification *)notification
{
	NSString* username = [notification.userInfo objectForKey:kShowUserProfileUsernameKey];
	[self showProfileWithUsername:username];
}

- (void) showReplyPostNotification:(NSNotification *)notification
{
	NSString* post_id = [notification.userInfo objectForKey:kShowReplyPostIDKey];
	NSString* username = [notification.userInfo objectForKey:kShowReplyPostUsernameKey];
	RFPostController* post_controller = [[RFPostController alloc] initWithReplyTo:post_id replyUsername:username];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:post_controller];
	[[self activeNavigationController] presentViewController:nav_controller animated:YES completion:NULL];
}

- (void) postWasUnselectedNotification:(NSNotification *)notification
{
	NSString* post_id = [notification.userInfo objectForKey:kPostNotificationPostIDKey];
	RFTimelineController* timeline_controller = (RFTimelineController *) [self activeNavigationController].topViewController;
	if ([timeline_controller isKindOfClass:[RFTimelineController class]]) {
		[timeline_controller setSelected:NO withPostID:post_id];
	}
}

- (void) resetDetailNotification:(NSNotification *)notification
{
	UIViewController* controller = [notification.userInfo objectForKey:kResetDetailControllerKey];
	if ([self.splitViewController isCollapsed]) {
		[self.menuNavController pushViewController:controller animated:YES];
	}
	else {
		self.navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		self.splitViewController.viewControllers = @[ self.menuNavController, self.navigationController ];
	}
}

- (void) closePostingNotification:(NSNotification *)notification
{
	[[self activeNavigationController] dismissViewControllerAnimated:YES completion:NULL];
}

- (UINavigationController *) activeNavigationController
{
	if ([self.splitViewController isCollapsed]) {
		return self.menuNavController;
	}
	else {
		return self.navigationController;
	}
}

- (void) showOptionsMenuWithPostID:(NSString *)postID
{
	RFTimelineController* timeline_controller = (RFTimelineController *) [self activeNavigationController].topViewController;
	if ([timeline_controller isKindOfClass:[RFTimelineController class]]) {
		[timeline_controller setSelected:YES withPostID:postID];
		CGRect r = [timeline_controller rectOfPostID:postID];
		RFOptionsPopoverType popover_type = [timeline_controller popoverTypeOfPostID:postID];
		NSString* username = [timeline_controller usernameOfPostID:postID];
		RFOptionsController* options_controller = [[RFOptionsController alloc] initWithPostID:postID username:username popoverType:popover_type];
		[options_controller attachToView:timeline_controller.webView atRect:r];
		[[self activeNavigationController] presentViewController:options_controller animated:YES completion:NULL];
	}
}

- (void) showConversationWithPostID:(NSString *)postID
{
	NSString* path = [NSString stringWithFormat:@"/hybrid/conversation/%@", postID];
	RFTimelineController* conversation_controller = [[RFTimelineController alloc] initWithEndpoint:path title:@"Conversation"];
	[[self activeNavigationController] pushViewController:conversation_controller animated:YES];
}

- (void) showProfileWithUsername:(NSString *)username
{
	NSString* path = [NSString stringWithFormat:@"/hybrid/posts/%@", username];
	RFUserController* user_controller = [[RFUserController alloc] initWithEndpoint:path username:username];
	[[self activeNavigationController] pushViewController:user_controller animated:YES];
}

- (void) showSigninWithToken:(NSString *)appToken
{
	[self setupSigninWithToken:appToken];
}

- (void) showMicropubWithURL:(NSString *)url
{
	NSString* code = [url uuFindQueryStringArg:@"code"];
	NSString* state = [url uuFindQueryStringArg:@"state"];
	NSString* me = [url uuFindQueryStringArg:@"me"];

	if (!code || !state || !me) {
		NSString* msg = [NSString stringWithFormat:@"Authorization \"code\", \"state\", or \"me\" parameters were missing."];
		[UIAlertView uuShowOneButtonAlert:@"Micropub Error" message:msg button:@"OK" completionHandler:NULL];
		return;
	}
	
	NSString* saved_state = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubState"];
	NSString* saved_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubTokenEndpoint"];
	
	if (![state isEqualToString:saved_state]) {
		[UIAlertView uuShowOneButtonAlert:@"Micropub Error" message:@"Authorization state did not match." button:@"OK" completionHandler:NULL];
	}
	else {
		NSDictionary* info = @{
			@"grant_type": @"authorization_code",
			@"me": me,
			@"code": code,
			@"redirect_uri": @"https://micro.blog/micropub/redirect",
			@"client_id": @"https://micro.blog/",
			@"state": state
		};
		
		RFMicropub* mp = [[RFMicropub alloc] initWithURL:saved_endpoint];
		[mp postWithParams:info completion:^(UUHttpResponse* response) {
			RFDispatchMain (^{
				if ([response.parsedResponse isKindOfClass:[NSString class]]) {
					NSString* msg = response.parsedResponse;
					if (msg.length > 200) {
						msg = @"";
					}
					[UIAlertView uuShowOneButtonAlert:@"Micropub Error" message:msg button:@"OK" completionHandler:NULL];
				}
				else {
					NSString* access_token = [response.parsedResponse objectForKey:@"access_token"];
					if (access_token == nil) {
						NSString* msg = [response.parsedResponse objectForKey:@"error_description"];
						[UIAlertView uuShowOneButtonAlert:@"Micropub Error" message:msg button:@"OK" completionHandler:NULL];
					}
					else {
						[[NSUserDefaults standardUserDefaults] setObject:me forKey:@"ExternalMicropubMe"];
						[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ExternalBlogIsPreferred"];
						[SSKeychain setPassword:access_token forService:@"ExternalMicropub" account:@"default"];
					}
					
					[[self activeNavigationController] dismissViewControllerAnimated:YES completion:^{
						[[NSNotificationCenter defaultCenter] postNotificationName:kOpenPostingNotification object:self];
					}];
				}
			});
		}];
	}
}

- (BOOL) hasValidToken
{
	NSString* token = [SSKeychain passwordForService:@"Snippets" account:@"default"];
	NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:@"AccountUsername"];

	return ((token.length > 0) && (username.length > 0));
}

#pragma mark -

- (BOOL) splitViewController:(UISplitViewController *)splitViewController showViewController:(UIViewController *)vc sender:(id)sender
{
	return NO;
}

- (BOOL) splitViewController:(UISplitViewController *)splitViewController showDetailViewController:(UIViewController *)vc sender:(id)sender
{
	return NO;
}

- (UIViewController *) primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController
{
	return self.menuNavController;
}

- (UIViewController *) primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController
{
	return self.menuNavController;
}

- (BOOL) splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
	[self.menuNavController popToRootViewControllerAnimated:YES];
	return YES;
}

- (UIViewController *) splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
{
	[self.menuNavController popToRootViewControllerAnimated:YES];
	return self.navigationController;
}

@end
