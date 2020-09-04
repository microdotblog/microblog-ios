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
#import "RFAccountsController.h"
#import "RFMenuCell.h"
#import "RFClient.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "RFSettings.h"
#import "UUImageView.h"
#import "UUAlert.h"
#import "SSKeychain.h"
#import "UIBarButtonItem+Extras.h"

static NSString* const kMenuCellIdentifier = @"MenuCell";

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
	[self setupDefaultSource];
	[self setupTable];
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
		if (@available(iOS 13.0, *)) {
			UIImage* upload_img = [UIImage systemImageNamed:@"square.and.pencil"];
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:upload_img style:UIBarButtonItemStylePlain target:self action:@selector(promptNewPost:)];
		}
		else {
			self.navigationItem.rightBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"new_post_button" target:self action:@selector(promptNewPost:)];
		}
	}
	else {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (void) setupDefaultSource
{
	NSIndexPath* index_path = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView selectRowAtIndexPath:index_path animated:NO scrollPosition:UITableViewScrollPositionNone];
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

- (void) setupTable
{
	[self.tableView registerNib:[UINib nibWithNibName:@"MenuCell" bundle:nil] forCellReuseIdentifier:kMenuCellIdentifier];

	self.menuItems = [[NSMutableArray alloc] init];
	
	[self.menuItems addObject:@"Timeline"];
	[self.menuItems addObject:@"Mentions"];
	[self.menuItems addObject:@"Bookmarks"];
	[self.menuItems addObject:@"Discover"];

	[self.menuItems addObject:@""];

	if ([RFSettings hasSnippetsBlog]) {
		[self.menuItems addObject:@"Posts"];
		[self.menuItems addObject:@"Pages"];
		[self.menuItems addObject:@"Uploads"];

		[self.menuItems addObject:@""];
	}
	
	[self.menuItems addObject:@"Help"];
	[self.menuItems addObject:@"Settings"];
	[self.menuItems addObject:@"Sign Out"];
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
	UIKeyCommand* favorites_key = [UIKeyCommand keyCommandWithInput:@"3" modifierFlags:UIKeyModifierCommand action:@selector(showFavorites:) discoverabilityTitle:@"Bookmarks"];
	
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
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
	RFAccountsController* accounts_controller = [storyboard instantiateInitialViewController];
	[self.navigationController presentViewController:accounts_controller animated:YES completion:NULL];
	
//	NSString* username = [RFSettings snippetsUsername];
//	if (username) {
//		[[NSNotificationCenter defaultCenter] postNotificationName:kShowUserProfileNotification object:self userInfo:@{ kShowUserProfileUsernameKey: username }];
//	}
}

- (IBAction) showTimeline:(id)sender
{
	RFTimelineController* timeline_controller = [[RFTimelineController alloc] init];
	timeline_controller.menuController = self;
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
	RFTimelineController* timeline_controller = [[RFTimelineController alloc] initWithEndpoint:@"/hybrid/favorites" title:@"Bookmarks"];
	timeline_controller.menuController = self;
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showDiscover:(id)sender
{
	RFDiscoverController* timeline_controller = [[RFDiscoverController alloc] initWithEndpoint:@"/hybrid/discover" title:@"Discover"];
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showPosts:(id)sender
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"AllPosts" bundle:nil];

	RFAllPostsController* posts_controller = [storyboard instantiateInitialViewController];
	posts_controller.isShowingPages = NO;
	
	[self notifyResetDetail:posts_controller];
}

- (IBAction) showPages:(id)sender
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"AllPosts" bundle:nil];

	RFAllPostsController* posts_controller = [storyboard instantiateInitialViewController];
	posts_controller.isShowingPages = YES;
	
	[self notifyResetDetail:posts_controller];
}

- (IBAction) showUploads:(id)sender
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"AllUploads" bundle:nil];

	UIViewController* uploads_controller = [storyboard instantiateInitialViewController];
	
	[self notifyResetDetail:uploads_controller];
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
			[[NSNotificationCenter defaultCenter] postNotificationName:kShowSigninNotification object:self];
		}
	}];
}

- (void) notifyResetDetail:(UIViewController *)controller
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kResetDetailNotification object:self userInfo:@{ kResetDetailControllerKey: controller }];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.menuItems count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFMenuCell* cell = [tableView dequeueReusableCellWithIdentifier:kMenuCellIdentifier forIndexPath:indexPath];
	
	NSString* title = [self.menuItems objectAtIndex:indexPath.row];
	cell.titleField.text = title;
	
	return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* title = [self.menuItems objectAtIndex:indexPath.row];
	if (title.length > 0) {
		return 44;
	}
	else {
		return 15;
	}
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* title = [self.menuItems objectAtIndex:indexPath.row];
	if ([title isEqualToString:@"Timeline"]) {
		[self showTimeline:nil];
	}
	else if ([title isEqualToString:@"Mentions"]) {
		[self showMentions:nil];
	}
	else if ([title isEqualToString:@"Bookmarks"]) {
		[self showFavorites:nil];
	}
	else if ([title isEqualToString:@"Discover"]) {
		[self showDiscover:nil];
	}
	else if ([title isEqualToString:@"Posts"]) {
		[self showPosts:nil];
	}
	else if ([title isEqualToString:@"Pages"]) {
		[self showPages:nil];
	}
	else if ([title isEqualToString:@"Uploads"]) {
		[self showUploads:nil];
	}
	else if ([title isEqualToString:@"Help"]) {
		[self showHelp:nil];
	}
	else if ([title isEqualToString:@"Settings"]) {
		[self showSettings:nil];
	}
	else if ([title isEqualToString:@"Sign Out"]) {
		[self signOut:nil];
	}
}

@end
