//
//  RFMenuController.m
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFMenuController.h"

#import "RFTimelineController.h"
#import "RFSettingsController.h"
#import "RFDiscoverController.h"
#import "RFExternalController.h"
#import "RFPostController.h"
#import "RFHelpController.h"
#import "RFAllPostsController.h"
#import "RFClient.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "RFSettings.h"
#import "UUImageView.h"
#import "UUAlert.h"
#import "SSKeychain.h"
#import "UIBarButtonItem+Extras.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@implementation RFMenuController

- (instancetype) init
{
	self = [super initWithNibName:@"Menu" bundle:nil];
	if (self) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self setupProfileInfo];
	[self checkUserDetails];
}

- (void) setupNavigation
{
	self.title = @"Micro.blog";
	self.fullNameField.text = @"";
	self.usernameField.text = @"";
	
	if ([UIScreen mainScreen].traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
		self.navigationItem.rightBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"new_post_button" target:self action:@selector(promptNewPost:)];
	}
	else {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (void) setupProfileInfo
{
	NSString* full_name = [RFSettings snippetsAccountFullName];
	NSString* username = [RFSettings snippetsUsername];
	NSString* gravatar_url = [RFSettings snippetsGravatarURL];

	if (full_name && username) {
		self.fullNameField.text = full_name;
		self.usernameField.text = [NSString stringWithFormat:@"@%@", username];
		self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.size.width / 2.0;
		[self.profileImageView uuLoadImageFromURL:[NSURL URLWithString:gravatar_url] defaultImage:nil loadCompleteHandler:NULL];
	}
	else {
		self.fullNameField.text = @"";
		self.usernameField.text = @"";
	}	
}

- (void) checkUserDetails
{
	NSString* token = [SSKeychain passwordForService:@"Snippets" account:@"default"];
	if (token) {
		RFClient* client = [[RFClient alloc] initWithPath:@"/account/verify"];
		NSDictionary* params = @{
			@"token": token
		};
		[client postWithParams:params completion:^(UUHttpResponse* response) {
			if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]]) {
				NSString* full_name = [response.parsedResponse objectForKey:@"full_name"];
				NSString* username = [response.parsedResponse objectForKey:@"username"];
				NSString* gravatar_url = [response.parsedResponse objectForKey:@"gravatar_url"];

				[RFSettings setSnippetsAccountFullName:full_name];
				[RFSettings setSnippetsUsername:username];
				[RFSettings setSnippetsGravatarURL:gravatar_url];

				RFDispatchMain (^{
					[self setupProfileInfo];
				});
			}
		}];
		
		// Update the list of blogs assigned to the users...
		client = [[RFClient alloc] initWithPath:@"/micropub?q=config"];
		[client getWithQueryArguments:nil completion:^(UUHttpResponse* response)
		{
			NSArray* blogs = [response.parsedResponse objectForKey:@"destination"];
			[RFSettings setBlogList:blogs];
			RFDispatchMain (^{
				[self setupProfileInfo];
			});
		}];
	}
}

- (IBAction) onSwitchMicroBlog:(id)sender
{
	NSArray* availableMicroBlogs = [RFSettings blogList];
	if (availableMicroBlogs.count > 1)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kMicroblogSelectNotification object:nil];
	}
}

- (BOOL) canBecomeFirstResponder
{
	return YES;
}

- (NSArray *) keyCommands
{
	NSMutableArray* commands = [NSMutableArray array];
	
	UIKeyCommand* newpost_key = [UIKeyCommand keyCommandWithInput:@"N" modifierFlags:UIKeyModifierCommand action:@selector(promptNewPost:) discoverabilityTitle:@"New Post"];
	UIKeyCommand* timeline_key = [UIKeyCommand keyCommandWithInput:@"1" modifierFlags:UIKeyModifierCommand action:@selector(showTimeline:) discoverabilityTitle:@"Timeline"];
	UIKeyCommand* mentions_key = [UIKeyCommand keyCommandWithInput:@"2" modifierFlags:UIKeyModifierCommand action:@selector(showMentions:) discoverabilityTitle:@"Mentions"];
	UIKeyCommand* favorites_key = [UIKeyCommand keyCommandWithInput:@"3" modifierFlags:UIKeyModifierCommand action:@selector(showFavorites:) discoverabilityTitle:@"Favorites"];
	
	[commands addObject:newpost_key];
	[commands addObject:timeline_key];
	[commands addObject:mentions_key];
	[commands addObject:favorites_key];
	
	return commands;
}

#pragma mark -

- (IBAction) promptNewPost:(id)sender
{
	if ([RFSettings needsExternalBlogSetup]) {
		RFExternalController* wordpress_controller = [[RFExternalController alloc] init];
		UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:wordpress_controller];
		[self.navigationController presentViewController:nav_controller animated:YES completion:NULL];
	}
	else {
		RFPostController* post_controller = [[RFPostController alloc] init];
		UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:post_controller];
		[self.navigationController presentViewController:nav_controller animated:YES completion:NULL];
	}
}

- (IBAction) showUserProfile:(id)sender
{
	NSString* username = [RFSettings snippetsUsername];
	if (username) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kShowUserProfileNotification object:self userInfo:@{ kShowUserProfileUsernameKey: username }];
	}
}

- (IBAction) showTimeline:(id)sender
{
	RFTimelineController* timeline_controller = [[RFTimelineController alloc] init];
	timeline_controller.menuController = self;
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showDiscover:(id)sender
{
	RFDiscoverController* timeline_controller = [[RFDiscoverController alloc] initWithEndpoint:@"/hybrid/discover" title:@"Discover"];
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showMentions:(id)sender
{
	RFTimelineController* timeline_controller = [[RFTimelineController alloc] initWithEndpoint:@"/hybrid/mentions" title:@"Mentions"];
	timeline_controller.menuController = self;
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showFavorites:(id)sender
{
	RFTimelineController* timeline_controller = [[RFTimelineController alloc] initWithEndpoint:@"/hybrid/favorites" title:@"Favorites"];
	timeline_controller.menuController = self;
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showPosts:(id)sender
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"AllPosts" bundle:nil];
	UIViewController* posts_controller = [storyboard instantiateInitialViewController];
	[self notifyResetDetail:posts_controller];
}

- (IBAction) showHelp:(id)sender
{
	RFHelpController* help_controller = [[RFHelpController alloc] init];
	[self notifyResetDetail:help_controller];
}

- (IBAction) showSettings:(id)sender
{
	RFSettingsController* settings_controller = [[RFSettingsController alloc] init];
	[self notifyResetDetail:settings_controller];
}

- (IBAction) signOut:(id)sender
{
	[UUAlertViewController uuShowTwoButtonAlert:@"Sign out of Micro.blog?" message:@"Signing out will reset your settings and let you sign in with a new account or different microblog." buttonOne:@"Cancel" buttonTwo:@"Sign Out" completionHandler:^(NSInteger buttonIndex) {
		if (buttonIndex == 1) {
			[RFSettings clearAllSettings];

			[Answers logCustomEventWithName:@"Sign Out" customAttributes:nil];

			[[NSNotificationCenter defaultCenter] postNotificationName:kShowSigninNotification object:self];
		}
	}];
}

- (void) notifyResetDetail:(UIViewController *)controller
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kResetDetailNotification object:self userInfo:@{ kResetDetailControllerKey: controller }];
}

@end
