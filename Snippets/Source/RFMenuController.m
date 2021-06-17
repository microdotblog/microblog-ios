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
#import "RFBookmarksController.h"
#import "RFAllPostsController.h"
#import "RFAllRepliesController.h"
#import "RFAccountsController.h"
#import "RFAccount.h"
#import "RFMenuCell.h"
#import "RFClient.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "RFSettings.h"
#import "UUImageView.h"
#import "UUAlert.h"
#import "SSKeychain.h"
#import "UIBarButtonItem+Extras.h"
#import <SafariServices/SafariServices.h>

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
	[self setupNotifications];
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

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshUserNotification:) name:kRefreshUserNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMenuNotification:) name:kRefreshMenuNotification object:nil];
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
	
	RFAccount* a = [[RFAccount alloc] init];
	a.username = username;
	NSString* avatar_url = [a profileURL];

	if (full_name && username) {
		self.fullNameField.text = full_name;
		self.usernameField.text = [NSString stringWithFormat:@"@%@", username];
		self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.size.width / 2.0;
		[self.profileImageView uuLoadImageFromURL:[NSURL URLWithString:avatar_url] defaultImage:nil loadCompleteHandler:NULL];
	}
	else {
		self.fullNameField.text = @"";
		self.usernameField.text = @"";
	}	
}

- (void) setupTable
{
	[self.tableView registerNib:[UINib nibWithNibName:@"MenuCell" bundle:nil] forCellReuseIdentifier:kMenuCellIdentifier];
}

- (void) setupMenu
{
	self.menuItems = [[NSMutableArray alloc] init];
	self.menuIcons = [[NSMutableArray alloc] init];

	[self.menuItems addObject:@"Timeline"];
	[self.menuIcons addObject:@"bubble.left.and.bubble.right"];
	
	[self.menuItems addObject:@"Mentions"];
	[self.menuIcons addObject:@"at"];

	[self.menuItems addObject:@"Bookmarks"];
	[self.menuIcons addObject:@"star"];

	[self.menuItems addObject:@"Discover"];
	[self.menuIcons addObject:@"magnifyingglass"];

	[self.menuItems addObject:@""];
	[self.menuIcons addObject:@""];

	if ([RFSettings hasSnippetsBlog]) {
		[self.menuItems addObject:@"Posts"];
		[self.menuIcons addObject:@"doc"];

		[self.menuItems addObject:@"Pages"];
		[self.menuIcons addObject:@"rectangle.stack"];

		[self.menuItems addObject:@"Uploads"];
		[self.menuIcons addObject:@"photo.on.rectangle"];

		[self.menuItems addObject:@""];
		[self.menuIcons addObject:@""];
	}
	
	[self.menuItems addObject:@"Replies"];
	[self.menuIcons addObject:@"bubble.left"];

	[self.menuItems addObject:@"Help"];
	[self.menuIcons addObject:@"questionmark.circle"];

	[self.menuItems addObject:@"Settings"];
	if (@available(iOS 14.0, *)) {
		[self.menuIcons addObject:@"gearshape"];
	}
	else {
		[self.menuIcons addObject:@"gear"];
	}

	NSIndexPath* index_path = [self.tableView indexPathForSelectedRow];
	[self.tableView reloadData];
	if (index_path) {
		[self.tableView selectRowAtIndexPath:index_path animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
}

- (void) checkUserDetails
{
	RFAccount* a = [RFAccount defaultAccount];
	if (a) {
		NSString* token = [a password];
		if (token) {
			RFClient* client = [[RFClient alloc] initWithPath:@"/account/verify"];
			NSDictionary* params = @{
				@"token": token
			};
			[client postWithParams:params completion:^(UUHttpResponse* response) {
				if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]]) {
					NSString* error = [response.parsedResponse objectForKey:@"error"];
					if (error != nil) {
						RFDispatchMain (^{
							[UUAlertViewController uuShowTwoButtonAlert:error message:@"Signing out will reset your settings and let you sign in with a new account or different microblog." buttonOne:@"Cancel" buttonTwo:@"Sign Out" completionHandler:^(NSInteger buttonIndex) {
								if (buttonIndex == 1) {
									[RFSettings clearAllSettings];
									[[NSNotificationCenter defaultCenter] postNotificationName:kShowSigninNotification object:self];
								}
							}];
						});
					}
					else {
						NSString* full_name = [response.parsedResponse objectForKey:@"full_name"];
						NSString* username = [response.parsedResponse objectForKey:@"username"];

						[RFSettings setSnippetsAccountFullName:full_name];
						[RFSettings setSnippetsUsername:username];
						[RFSettings setSnippetsPassword:token useCurrentUser:YES];

						RFDispatchMain (^{
							[self setupProfileInfo];
						});

						// download the user's blogs
						RFClient* client = [[RFClient alloc] initWithPath:@"/micropub?q=config"];
						[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
							NSArray* blogs = [response.parsedResponse objectForKey:@"destination"];
							[RFSettings setBlogList:blogs];
							
							RFDispatchMain (^{
								[self setupMenu];
							});
						}];
					}
				}
			}];
		}
	}
}

- (void) refreshUserNotification:(NSNotification *)notification
{
	[self setupProfileInfo];
	[self checkUserDetails];

	RFDispatchSeconds(0.5, ^{
		if ([[notification.userInfo objectForKey:kRefreshUserGoToTimelineKey] boolValue]) {
			NSIndexPath* index_path = [NSIndexPath indexPathForRow:0 inSection:0];
			[self.tableView selectRowAtIndexPath:index_path animated:NO scrollPosition:UITableViewScrollPositionNone];
			[self showTimeline:nil];
		}
	});
}

- (void) refreshMenuNotification:(NSNotification *)notification
{
	[self setupProfileInfo];
	[self setupMenu];
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
	UIKeyCommand* discover_key = [UIKeyCommand keyCommandWithInput:@"4" modifierFlags:UIKeyModifierCommand action:@selector(showDiscover:) discoverabilityTitle:@"Discover"];

	UIKeyCommand* posts_key = [UIKeyCommand keyCommandWithInput:@"5" modifierFlags:UIKeyModifierCommand action:@selector(showPosts:) discoverabilityTitle:@"Posts"];
	UIKeyCommand* pages_key = [UIKeyCommand keyCommandWithInput:@"6" modifierFlags:UIKeyModifierCommand action:@selector(showPages:) discoverabilityTitle:@"Pages"];
	UIKeyCommand* uploads_key = [UIKeyCommand keyCommandWithInput:@"7" modifierFlags:UIKeyModifierCommand action:@selector(showUploads:) discoverabilityTitle:@"Uploads"];

	[commands addObject:newpost_key];

	[commands addObject:timeline_key];
	[commands addObject:mentions_key];
	[commands addObject:favorites_key];
	[commands addObject:discover_key];

	if ([RFSettings hasSnippetsBlog]) {
		[commands addObject:posts_key];
		[commands addObject:pages_key];
		[commands addObject:uploads_key];
	}
	
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
	NSIndexPath* index_path = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView selectRowAtIndexPath:index_path animated:YES scrollPosition:UITableViewScrollPositionNone];

	RFTimelineController* timeline_controller = [[RFTimelineController alloc] init];
	timeline_controller.menuController = self;
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showMentions:(id)sender
{
	NSIndexPath* index_path = [NSIndexPath indexPathForRow:1 inSection:0];
	[self.tableView selectRowAtIndexPath:index_path animated:YES scrollPosition:UITableViewScrollPositionNone];

	RFTimelineController* timeline_controller = [[RFTimelineController alloc] initWithEndpoint:@"/hybrid/mentions" title:@"Mentions"];
	timeline_controller.menuController = self;
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showFavorites:(id)sender
{
	NSIndexPath* index_path = [NSIndexPath indexPathForRow:2 inSection:0];
	[self.tableView selectRowAtIndexPath:index_path animated:YES scrollPosition:UITableViewScrollPositionNone];

	RFTimelineController* timeline_controller = [[RFBookmarksController alloc] initWithEndpoint:@"/hybrid/favorites" title:@"Bookmarks"];
	timeline_controller.menuController = self;
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showDiscover:(id)sender
{
	NSIndexPath* index_path = [NSIndexPath indexPathForRow:3 inSection:0];
	[self.tableView selectRowAtIndexPath:index_path animated:YES scrollPosition:UITableViewScrollPositionNone];

	RFDiscoverController* timeline_controller = [[RFDiscoverController alloc] initWithEndpoint:@"/hybrid/discover" title:@"Discover"];
	[self notifyResetDetail:timeline_controller];
}

- (IBAction) showPosts:(id)sender
{
	NSIndexPath* index_path = [NSIndexPath indexPathForRow:5 inSection:0];
	[self.tableView selectRowAtIndexPath:index_path animated:YES scrollPosition:UITableViewScrollPositionNone];

	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"AllPosts" bundle:nil];

	RFAllPostsController* posts_controller = [storyboard instantiateInitialViewController];
	posts_controller.isShowingPages = NO;
	
	[self notifyResetDetail:posts_controller];
}

- (IBAction) showPages:(id)sender
{
	NSIndexPath* index_path = [NSIndexPath indexPathForRow:6 inSection:0];
	[self.tableView selectRowAtIndexPath:index_path animated:YES scrollPosition:UITableViewScrollPositionNone];

	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"AllPosts" bundle:nil];

	RFAllPostsController* posts_controller = [storyboard instantiateInitialViewController];
	posts_controller.isShowingPages = YES;
	
	[self notifyResetDetail:posts_controller];
}

- (IBAction) showUploads:(id)sender
{
	NSIndexPath* index_path = [NSIndexPath indexPathForRow:7 inSection:0];
	[self.tableView selectRowAtIndexPath:index_path animated:YES scrollPosition:UITableViewScrollPositionNone];

	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"AllUploads" bundle:nil];

	UIViewController* uploads_controller = [storyboard instantiateInitialViewController];
	
	[self notifyResetDetail:uploads_controller];
}

- (IBAction) showReplies:(id)sender
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"AllReplies" bundle:nil];

	RFAllRepliesController* posts_controller = [storyboard instantiateInitialViewController];
	
	[self notifyResetDetail:posts_controller];
}

- (IBAction) showHelp:(id)sender
{
//	SFSafariViewController* help_controller = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://help.micro.blog/"]];
//	[self presentViewController:help_controller animated:YES completion:NULL];

	RFHelpController* help_controller = [[RFHelpController alloc] init];
	[self notifyResetDetail:help_controller];
}

- (IBAction) showSettings:(id)sender
{
	RFSettingsController* settings_controller = [[RFSettingsController alloc] init];
	[self notifyResetDetail:settings_controller];
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
	NSString* icon_name = [self.menuIcons objectAtIndex:indexPath.row];
	[cell setupWithTitle:title icon:icon_name];
	
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

- (BOOL) tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* title = [self.menuItems objectAtIndex:indexPath.row];
	if (title.length > 0) {
		return YES;
	}
	else {
		return NO;
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
	else if ([title isEqualToString:@"Replies"]) {
		[self showReplies:nil];
	}
	else if ([title isEqualToString:@"Help"]) {
		[self showHelp:nil];
	}
	else if ([title isEqualToString:@"Settings"]) {
		[self showSettings:nil];
	}
}

@end
