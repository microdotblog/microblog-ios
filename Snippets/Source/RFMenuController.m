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
#import "RFConstants.h"
#import "UUImageView.h"
#import "SSKeychain.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <ZendeskSDK/ZendeskSDK.h>

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
	
	self.title = @"Snippets.today";
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:@"AccountUsername"];
	NSString* gravatar_url = [[NSUserDefaults standardUserDefaults] objectForKey:@"AccountGravatarURL"];

	if (username) {
		self.usernameField.text = username;
		self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.size.width / 2.0;
		[self.profileImageView uuLoadImageFromURL:[NSURL URLWithString:gravatar_url] defaultImage:nil loadCompleteHandler:NULL];
	}
	else {
		self.usernameField.text = @"";
	}
}

- (IBAction) showTimeline:(id)sender
{
	RFTimelineController* timeline_controller = [[RFTimelineController alloc] init];
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showMentions:(id)sender
{
	RFTimelineController* timeline_controller = [[RFTimelineController alloc] initWithEndpoint:@"/iphone/mentions" title:@"Mentions"];
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showFavorites:(id)sender
{
	RFTimelineController* timeline_controller = [[RFTimelineController alloc] initWithEndpoint:@"/iphone/favorites" title:@"Favorites"];
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showHelp:(id)sender
{
	ZDKAnonymousIdentity* identity = [[ZDKAnonymousIdentity alloc] init];
	identity.name = [[NSUserDefaults standardUserDefaults] objectForKey:@"AccountFullName"];
	identity.email = [[NSUserDefaults standardUserDefaults] objectForKey:@"AccountEmail"];
	[ZDKConfig instance].userIdentity = identity;

	[ZDKRequests presentRequestCreationWithViewController:self.navigationController];
}

- (IBAction) showSettings:(id)sender
{
	RFSettingsController* settings_controller = [[RFSettingsController alloc] init];
	[self notifyResetDetail:settings_controller];
}

- (IBAction) signOut:(id)sender
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AccountUsername"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AccountGravatarURL"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ExternalBlogUsername"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ExternalBlogApp"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ExternalBlogEndpoint"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ExternalBlogID"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ExternalBlogIsPreferred"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HasSnippetsBlog"];

	[SSKeychain deletePasswordForService:@"Snippets" account:@"default"];
	[SSKeychain deletePasswordForService:@"ExternalBlog" account:@"default"];

	[Answers logCustomEventWithName:@"Sign Out" customAttributes:nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:kShowSigninNotification object:self];
}

- (void) notifyResetDetail:(UIViewController *)controller
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kResetDetailNotification object:self userInfo:@{ kResetDetailControllerKey: controller }];
}

@end
