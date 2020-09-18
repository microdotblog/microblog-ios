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
#import "RFBrowserActivity.h"
#import "RFSwipeNavigationController.h"
#import "RFConstants.h"
#import "RFMacros.h"
#import "SSKeychain.h"
#import "UUAlert.h"
#import "UUString.h"
#import "NSString+Extras.h"
#import "UITraitCollection+Extras.h"
#import "RFPopupNotificationViewController.h"
#import "RFAutoCompleteCache.h"
#import <SafariServices/SafariServices.h>
#import "RFSettings.h"
#import "RFAutoCompleteCache.h"
#import "UUDataCache.h"
#import <AuthenticationServices/AuthenticationServices.h>

@import UserNotifications;

@implementation RFAppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[RFSettings migrateAllKeys];
	[RFSettings migrateCurrentUserKeys];
	
	// We should only cache images for 24 hours...
	[UUDataCache uuSetCacheExpirationLength:24.0 * 60.0 * 60.0];
	[UUDataCache uuPurgeExpiredContent];
	
	[self setupAppleID];
	[self setupWindow];
	[self setupAppearance];
	[self setupNotifications];
	[self setupShortcuts];
	[self setupFollowerAutoComplete];
	
	return YES;
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	NSString* param = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
	if ([url.host isEqualToString:@"open"]) {
		[self showOptionsMenuWithPostID:param];
	}
	else if ([url.host isEqualToString:@"video"]) {
		NSString* video_url = [url.path substringFromIndex:1];
		[self showVideoWithURL:video_url];
	}
	else if ([url.host isEqualToString:@"photo"]) {
		NSString* photo_url = [url.path substringFromIndex:1];
		[self showPhotoWithURL:photo_url];
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
	else if ([url.host isEqualToString:@"post"]) {
		NSString* text = [[[url absoluteString] uuFindQueryStringArg:@"text"] uuUrlDecoded];
		[self showNewPostWithText:text];
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
	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub?q=config"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		if (response.parsedResponse) {
			if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
				NSArray* blogs = [response.parsedResponse objectForKey:@"destination"];
				if (blogs) {
					RFDispatchMainAsync(^{
						[RFSettings setBlogList:blogs];

						NSDictionary* selectedBlogInfo = [RFSettings selectedBlogInfo];
						NSString* selectedUid = [selectedBlogInfo objectForKey:@"uid"];

						for (NSDictionary* blogInfo in blogs) {
							NSString* uid = [blogInfo objectForKey:@"uid"];
							if ([uid isEqualToString:selectedUid]) {
								[RFSettings setSelectedBlogInfo:blogInfo];
							}
						}

						[[NSNotificationCenter defaultCenter] postNotificationName:kRefreshMenuNotification object:self];
					});
				}
			}
		}
	}];
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
		NSLog(@"%@", response);
	}];
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler
{
	NSString* post_id = [userInfo[@"post_id"] stringValue];
	NSString* from_username = userInfo[@"from_user"][@"username"];

	if (application.applicationState == UIApplicationStateActive) {
		NSString* message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[RFPopupNotificationViewController show:message fromUsername:from_username  inController:UIApplication.sharedApplication.keyWindow.rootViewController completionBlock:^
			{
				if (post_id.length > 0)
				{
					[self showConversationWithPostID:post_id];
				}
			}];
		});
	}
	else if (post_id.length > 0) {
		[self showConversationWithPostID:post_id];
	}

	if (completionHandler)
		completionHandler(UIBackgroundFetchResultNewData);
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

- (UIInterfaceOrientationMask) application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window
{
	if (RFIsPhone()) {
		return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
	}
	else {
		return UIInterfaceOrientationMaskAll;
	}
}

#pragma mark -

- (void) setupFollowerAutoComplete
{
	NSString* username = [RFSettings snippetsUsername];
	if (username == nil) {
		return;
	}
	
	NSString* path = [NSString stringWithFormat:@"/users/following/%@", username];
	RFClient* client = [[RFClient alloc] initWithPath:path];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse *response)
	{
		// We didn't get a valid response...
		if (response.httpResponse.statusCode < 200 || response.httpResponse.statusCode > 299)
		{
			return;
		}
		
		NSArray* array = response.parsedResponse;
		if (array && [array isKindOfClass:[NSArray class]])
		{
 			for (NSDictionary* dictionary in array)
			{
				NSString* username = dictionary[@"username"];
				if (username)
				{
					[RFAutoCompleteCache addAutoCompleteString:username];
				}
			}
		}
	}];
}

- (void) setupAppleID
{
	if (@available(iOS 13.0, *)) {
		NSString* apple_id_user_id = @"";
		if (apple_id_user_id.length > 0) {
			ASAuthorizationAppleIDProvider* provider = [[ASAuthorizationAppleIDProvider alloc] init];
			[provider getCredentialStateForUserID:apple_id_user_id completion:^(ASAuthorizationAppleIDProviderCredentialState credentialState, NSError* error) {
				if (credentialState == ASAuthorizationAppleIDProviderCredentialAuthorized) {
					// ...
				}
				else {
					// ...
				}
			}];
		}
	}
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
	UNAuthorizationOptions options = UNAuthorizationOptionBadge | UNAuthorizationOptionAlert | UNAuthorizationOptionSound;
	[[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[UIApplication.sharedApplication registerForRemoteNotifications];
		});
	}];
}

- (void) setupAppearance
{
	NSString* content_size = [UIApplication sharedApplication].preferredContentSizeCategory;
	[RFSettings setPreferredContentSize:content_size];
}

- (void) setupTimeline
{
	self.menuController = [[RFMenuController alloc] init];
	self.timelineController = [[RFTimelineController alloc] init];
	self.timelineController.menuController = self.menuController;
	[self.timelineController loadViewIfNeeded];
	
	self.splitViewController = [[UISplitViewController alloc] init];
	self.splitViewController.delegate = self;
    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    self.splitViewController.preferredPrimaryColumnWidthFraction = 0.3;

	self.self.menuNavController = [[RFSwipeNavigationController alloc] initWithRootViewController:self.menuController];
	self.navigationController = [[RFSwipeNavigationController alloc] initWithRootViewController:self.timelineController];

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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareConversationNotification:) name:kPrepareConversationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sharePostNotification:) name:kSharePostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUserProfileNotification:) name:kShowUserProfileNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showReplyPostNotification:) name:kShowReplyPostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postWasUnselectedNotification:) name:kPostWasUnselectedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetDetailNotification:) name:kResetDetailNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closePostingNotification:) name:kClosePostingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openURLNotification:) name:kOpenURLNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUserFollowingNotification:) name:kShowUserFollowingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUserDiscoverNotification:) name:kShowUserDiscoverNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showTopicNotification:) name:kShowTopicNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNewPostNotification:) name:kShowNewPostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timelineDidStopScrollingNotification:) name:kTimelineDidStopScrollingNotification object:nil];

	if (@available(iOS 13.0, *)) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appleCredentialRevoked:) name:ASAuthorizationAppleIDProviderCredentialRevokedNotification object:nil];
	}
}

- (void) setupShortcuts
{
	UIApplicationShortcutIcon* post_icon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"new_post_button"];
	UIApplicationShortcutItem* post_item = [[UIApplicationShortcutItem alloc] initWithType:kShortcutActionNewPost localizedTitle:@"New Post" localizedSubtitle:@"Post to your microblog" icon:post_icon userInfo:nil];
	[[UIApplication sharedApplication] setShortcutItems:@[ post_item ]];
}

- (void) delaySelection
{
	self.isDelayingSelection = YES;
	[NSTimer scheduledTimerWithTimeInterval:0.4 repeats:NO block:^(NSTimer * _Nonnull timer) {
			self.isDelayingSelection = NO;
	}];
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
	if (post_id) {
		[self showConversationWithPostID:post_id];
	}
}

- (void) prepareConversationNotification:(NSNotification *)notification
{
	NSMutableArray* new_controllers = [notification.userInfo objectForKey:kPrepareConversationControllersKey];
	RFTimelineController* timeline_controller = [notification.userInfo objectForKey:kPrepareConversationTimelineKey];
	CGFloat y = [[notification.userInfo objectForKey:kPrepareConversationPointKey] floatValue];
	NSArray* post_ids = [timeline_controller allPostIDs];
	for (NSString* post_id in post_ids) {
		CGRect r = [timeline_controller rectOfPostID:post_id];
		CGFloat adjusted_y = y + timeline_controller.webView.scrollView.contentOffset.y - timeline_controller.webView.frame.origin.y;
		r.origin.y = r.origin.y + timeline_controller.webView.scrollView.contentOffset.y;
		CGPoint pt = CGPointMake (5, adjusted_y);
		if (CGRectContainsPoint(r, pt)) {
			NSString* path = [NSString stringWithFormat:@"/hybrid/conversation/%@", post_id];
			RFTimelineController* conversation_controller = [[RFTimelineController alloc] initWithEndpoint:path title:@"Conversation"];
			conversation_controller.menuController = self.menuController;
			[new_controllers addObject:conversation_controller];
			break;
		}
	}
}

- (void) sharePostNotification:(NSNotification *)notification
{
	NSString* post_id = [notification.userInfo objectForKey:kSharePostIDKey];
	[self showShareSheetWithPostID:post_id];
}

- (void) showUserProfileNotification:(NSNotification *)notification
{
	NSString* username = [notification.userInfo objectForKey:kShowUserProfileUsernameKey];
	[self showProfileWithUsername:username];
}

- (void) showUserFollowingNotification:(NSNotification *)notification
{
	NSString* username = [notification.userInfo objectForKey:kShowUserFollowingUsernameKey];
	[self showUserFollowingWithUsername:username];
}

- (void) showUserDiscoverNotification:(NSNotification *)notification
{
	NSString* username = [notification.userInfo objectForKey:kShowUserDiscoverUsernameKey];
	[self showUserDiscoverWithUsername:username];
}

- (void) showTopicNotification:(NSNotification *)notification
{
	NSString* term = [notification.userInfo objectForKey:kShowTopicKey];
	[self showTopicWithSearch:term];
}

- (void) showNewPostNotification:(NSNotification *)notification
{
	NSString* s = [notification.userInfo objectForKey:kShowNewPostText];
	if (s == nil) {
		s = @"";
	}
	[self showNewPostWithText:s];
}

- (void) timelineDidStopScrollingNotification:(NSNotification *)notification
{
	[self delaySelection];
}

- (void) appleCredentialRevoked:(NSNotification *)notification
{
	// TODO: sign user out
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
	
	[self delaySelection];
}

- (void) resetDetailNotification:(NSNotification *)notification
{
	UIViewController* controller = [notification.userInfo objectForKey:kResetDetailControllerKey];
	if ([self.splitViewController isCollapsed]) {
		[self.menuNavController pushViewController:controller animated:YES];
	}
	else {
		self.navigationController = [[RFSwipeNavigationController alloc] initWithRootViewController:controller];
		self.splitViewController.viewControllers = @[ self.menuNavController, self.navigationController ];
	}
}

- (void) closePostingNotification:(NSNotification *)notification
{
	[[self activeNavigationController] dismissViewControllerAnimated:YES completion:NULL];
}

- (void) openURLNotification:(NSNotification *)notification
{
	NSURL* url = [notification.userInfo objectForKey:kOpenURLKey];
	SFSafariViewController* safari_controller = [[SFSafariViewController alloc] initWithURL:url];
	[[self activeNavigationController] presentViewController:safari_controller animated:YES completion:NULL];
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

- (void) showNewPostWithText:(NSString *)text
{
	RFPostController* post_controller = [[RFPostController alloc] initWithText:text];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:post_controller];
	[[self activeNavigationController] presentViewController:nav_controller animated:YES completion:NULL];
}

- (void) showOptionsMenuWithPostID:(NSString *)postID
{
	if (self.isDelayingSelection) {
		return;
	}
	
	RFTimelineController* timeline_controller = (RFTimelineController *) [self activeNavigationController].topViewController;
	if ([timeline_controller isKindOfClass:[RFTimelineController class]]) {		
		[timeline_controller setSelected:YES withPostID:postID];
		CGRect r = [timeline_controller rectOfPostID:postID];
		RFOptionsPopoverType popover_type = [timeline_controller popoverTypeOfPostID:postID];
		NSString* username = [timeline_controller usernameOfPostID:postID];
		
		[RFAutoCompleteCache addAutoCompleteString:username];
		
		RFOptionsController* options_controller = [[RFOptionsController alloc] initWithPostID:postID username:username popoverType:popover_type];
		[options_controller attachToView:timeline_controller.webView atRect:r];
		[[self activeNavigationController] presentViewController:options_controller animated:YES completion:NULL];
	}
}

- (void) showPhotoWithURL:(NSString *)photoURL
{
	if (self.isDelayingSelection) {
		return;
	}

	RFTimelineController* timeline_controller = (RFTimelineController *) [self activeNavigationController].topViewController;
	if ([timeline_controller isKindOfClass:[RFTimelineController class]]) {
		[timeline_controller openImageViewer:photoURL];
	}
}

- (void) showVideoWithURL:(NSString *)videoURL
{
	if (self.isDelayingSelection) {
		return;
	}

	RFTimelineController* timeline_controller = (RFTimelineController *) [self activeNavigationController].topViewController;
	if ([timeline_controller isKindOfClass:[RFTimelineController class]]) {
		[timeline_controller openVideoViewer:videoURL];
	}
}


- (void) showShareSheetWithPostID:(NSString *)postID
{
	RFTimelineController* timeline_controller = (RFTimelineController *) [self activeNavigationController].topViewController;
	if ([timeline_controller isKindOfClass:[RFTimelineController class]]) {
		[timeline_controller setSelected:NO withPostID:postID];
		CGRect r = [timeline_controller rectOfPostID:postID];
		NSString* link = [timeline_controller linkOfPostID:postID];
		NSURL* url = [NSURL URLWithString:link];
		UIActivity* browser_activity = [[RFBrowserActivity alloc] init];
		UIActivityViewController* activity_controller = [[UIActivityViewController alloc] initWithActivityItems:@[ url ] applicationActivities:@[ browser_activity ]];
		activity_controller.popoverPresentationController.sourceView = timeline_controller.view;
		activity_controller.popoverPresentationController.sourceRect = r;
		[[self activeNavigationController] presentViewController:activity_controller animated:YES completion:NULL];
	}
}

- (void) showConversationWithPostID:(NSString *)postID
{
	NSString* path = [NSString stringWithFormat:@"/hybrid/conversation/%@", postID];
	RFTimelineController* conversation_controller = [[RFTimelineController alloc] initWithEndpoint:path title:@"Conversation"];
	conversation_controller.menuController = self.menuController;
	[[self activeNavigationController] pushViewController:conversation_controller animated:YES];
}

- (void) showProfileWithUsername:(NSString *)username
{
	NSString* path = [NSString stringWithFormat:@"/hybrid/posts/%@", username];
	RFUserController* user_controller = [[RFUserController alloc] initWithEndpoint:path username:username];
	[[self activeNavigationController] pushViewController:user_controller animated:YES];
}

- (void) showUserFollowingWithUsername:(NSString*)username
{
	NSString* path = [NSString stringWithFormat:@"/hybrid/following/%@", username];
	RFTimelineController* user_controller = [[RFTimelineController alloc] initWithEndpoint:path title:@"Following"];
	[[self activeNavigationController] pushViewController:user_controller animated:YES];
}

- (void) showUserDiscoverWithUsername:(NSString*)username
{
	NSString* path = [NSString stringWithFormat:@"/hybrid/users/discover/%@", username];
	RFTimelineController* user_controller = [[RFTimelineController alloc] initWithEndpoint:path title:@"Following"];
	[[self activeNavigationController] pushViewController:user_controller animated:YES];
}

- (void) showTopicWithSearch:(NSString *)term
{
	NSString* path = [NSString stringWithFormat:@"/hybrid/discover/%@", term];
	RFTimelineController* user_controller = [[RFTimelineController alloc] initWithEndpoint:path title:term];
	[[self activeNavigationController] pushViewController:user_controller animated:YES];
}

- (void) showSigninWithToken:(NSString *)appToken
{
	[self setupSigninWithToken:appToken];
}

- (void) showMicropubWithURL:(NSString *)url
{
	NSString* code = [[url uuFindQueryStringArg:@"code"] uuUrlDecoded];
	NSString* state = [[url uuFindQueryStringArg:@"state"] uuUrlDecoded];
	NSString* me = [[url uuFindQueryStringArg:@"me"] uuUrlDecoded];

	if (!code || !state || !me) {
		NSString* msg = [NSString stringWithFormat:@"Authorization \"code\", \"state\", or \"me\" parameters were missing."];
		[UUAlertViewController uuShowOneButtonAlert:@"Micropub Error" message:msg button:@"OK" completionHandler:NULL];
		return;
	}
	
	NSString* saved_state = [RFSettings externalMicropubState];
	NSString* saved_endpoint = [RFSettings externalMicropubTokenEndpoint];
	
	if (![state isEqualToString:saved_state]) {
		[UUAlertViewController uuShowOneButtonAlert:@"Micropub Error" message:@"Authorization state did not match." button:@"OK" completionHandler:NULL];
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
					[UUAlertViewController uuShowOneButtonAlert:@"Micropub Error" message:msg button:@"OK" completionHandler:NULL];
				}
				else {
					NSString* access_token = [response.parsedResponse objectForKey:@"access_token"];
					if (access_token == nil) {
						NSString* msg = [response.parsedResponse objectForKey:@"error_description"];
						[UUAlertViewController uuShowOneButtonAlert:@"Micropub Error" message:msg button:@"OK" completionHandler:NULL];
					}
					else {
						[RFSettings setExternalMicropubMe:me];
						[RFSettings setPrefersExternalBlog:YES];
						[RFSettings setExternalBlogPassword:access_token];
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
	NSString* token = [RFSettings snippetsPassword];
	NSString* username = [RFSettings snippetsUsername];

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
