//
//  RFSettingsController.m
//  Snippets
//
//  Created by Manton Reece on 9/1/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFSettingsController.h"

#import "RFSettingChoiceCell.h"
#import "RFConstants.h"
#import "RFSettings.h"
#import "UIBarButtonItem+Extras.h"
#import "RFXMLRPCRequest.h"
#import "RFXMLRPCParser.h"
#import "SSKeychain.h"
#import "RFMacros.h"

static NSString* const kServerCellIdentifier = @"ServerCell";

@implementation RFSettingsController

- (instancetype) init
{
	self = [super initWithNibName:@"Settings" bundle:nil];
	if (self) {
//		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupNavigation];
	[self setupSharing];
	[self setupServers];
	[self setupCategories];
	[self setupVersion];
//	[self setupGestures];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	NSIndexPath* index_path;

	if ([RFSettings prefersPlainSharedURLs]) {
		index_path = [NSIndexPath indexPathForRow:1 inSection:0];
	}
	else {
		index_path = [NSIndexPath indexPathForRow:0 inSection:0];
	}

	[self.sharingTableView selectRowAtIndexPath:index_path animated:NO scrollPosition:UITableViewScrollPositionNone];

	if ([RFSettings prefersExternalBlog]) {
		index_path = [NSIndexPath indexPathForRow:1 inSection:0];
	}
	else {
		index_path = [NSIndexPath indexPathForRow:0 inSection:0];
	}

	[self.serversTableView selectRowAtIndexPath:index_path animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self setupNavigation];
}

- (void) setupNavigation
{
	self.title = @"Settings";
	
	UIViewController* root_controller = [self.navigationController.viewControllers firstObject];
	if (self.navigationController.topViewController != root_controller) {
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_backBarButtonWithTarget:self action:@selector(back:)];
	}
}

- (void) setupSharing
{
	self.sharingNames = @[ @"Markdown link", @"Plain URL" ];

	[self.sharingTableView registerNib:[UINib nibWithNibName:@"SettingChoiceCell" bundle:nil] forCellReuseIdentifier:kServerCellIdentifier];
	self.sharingTableView.layer.cornerRadius = 5.0;
}

- (void) setupServers
{
	self.serverNames = @[ @"Micro.blog hosted weblog", @"WordPress or Micropub blog" ];

	[self.serversTableView registerNib:[UINib nibWithNibName:@"SettingChoiceCell" bundle:nil] forCellReuseIdentifier:kServerCellIdentifier];
	self.serversTableView.layer.cornerRadius = 5.0;
}

- (void) setupCategories
{
	self.categoryValues = @[ ];
	self.selectedCategory = @"";

	NSString* xmlrpc_endpoint = [RFSettings externalBlogEndpoint];
	NSString* blog_s = [RFSettings externalBlogID];
	NSString* username = [RFSettings externalBlogUsername];
	NSString* password = [RFSettings externalBlogPassword];

	if (![RFSettings externalBlogUsesWordPress]) {
		self.categoriesIntroField.hidden = YES;
		self.categoriesTableView.hidden = YES;
		return;
	}

	[self.categoriesTableView registerNib:[UINib nibWithNibName:@"SettingChoiceCell" bundle:nil] forCellReuseIdentifier:kServerCellIdentifier];
	self.categoriesTableView.layer.cornerRadius = 5.0;
	
	if (xmlrpc_endpoint && blog_s && username && password) {
		[self.categoriesProgressSpinner startAnimating];
		
		NSNumber* blog_id = [NSNumber numberWithInteger:[blog_s integerValue]];
		NSString* taxonomy = @"category";
		
		NSArray* params = @[ blog_id, username, password, taxonomy ];
		
		RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:xmlrpc_endpoint];
		[request sendMethod:@"wp.getTerms" params:params completion:^(UUHttpResponse* response) {
			RFXMLRPCParser* xmlrpc = [RFXMLRPCParser parsedResponseFromData:response.rawResponse];

			NSMutableArray* new_categories = [NSMutableArray array];
			NSMutableArray* new_ids = [NSMutableArray array];
			for (NSDictionary* cat_info in xmlrpc.responseParams.firstObject) {
				[new_categories addObject:cat_info[@"name"]];
				[new_ids addObject:cat_info[@"term_id"]];
			}

			RFDispatchMainAsync (^{
				self.categoryValues = new_categories;
				self.categoryIDs = new_ids;
				[self.categoriesTableView reloadData];
				[self.categoriesProgressSpinner stopAnimating];
				[self setupSelectedCategory];
			});
		}];
	}
}

- (void) setupVersion
{
	NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
	NSString* version = [info objectForKey:@"CFBundleShortVersionString"];

	self.versionField.text = [NSString stringWithFormat:@"Version %@", version];
}

- (void) setupGestures
{
	UISwipeGestureRecognizer* swipe_right_gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
	swipe_right_gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:swipe_right_gesture];
}

- (void) setupSelectedCategory
{
	NSString* selected_category = [RFSettings externalBlogCategory];
	if (selected_category) {
		NSUInteger row = [self.categoryIDs indexOfObject:selected_category];
		if (row != NSNotFound) {
			NSIndexPath* index_path = [NSIndexPath indexPathForRow:row inSection:0];
			[self.categoriesTableView selectRowAtIndexPath:index_path animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}
}

#pragma mark -

- (void) swipeRight:(UIGestureRecognizer *)gesture
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.sharingTableView) {
		return self.sharingNames.count;
	}
	else if (tableView == self.serversTableView) {
		return self.serverNames.count;
	}
	else if (tableView == self.categoriesTableView) {
		return self.categoryValues.count;
	}
	else {
		return 0;
	}
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFSettingChoiceCell* cell = [tableView dequeueReusableCellWithIdentifier:kServerCellIdentifier forIndexPath:indexPath];
	
	if (tableView == self.sharingTableView) {
		cell.nameField.text = [self.sharingNames objectAtIndex:indexPath.row];
		cell.checkmarkView.hidden = (indexPath.row > 0);
	}
	else if (tableView == self.serversTableView) {
		cell.nameField.text = [self.serverNames objectAtIndex:indexPath.row];
		cell.checkmarkView.hidden = (indexPath.row > 0);
	}
	else if (tableView == self.categoriesTableView) {
		cell.nameField.text = [self.categoryValues objectAtIndex:indexPath.row];
		NSString* category_id = [self.categoryIDs objectAtIndex:indexPath.row];
		NSString* selected_category = [RFSettings externalBlogCategory];
		if (selected_category) {
			cell.checkmarkView.hidden = ![selected_category isEqualToString:category_id];
		}
		else {
			cell.checkmarkView.hidden = YES;
		}
	}
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.sharingTableView) {
		BOOL prefer_plain_urls = (indexPath.row == 1);
		[RFSettings setPrefersPlainSharedURLs:prefer_plain_urls];
	}
	else if (tableView == self.serversTableView) {
		BOOL prefer_external_blog = (indexPath.row == 1);
		[RFSettings setPrefersExternalBlog:prefer_external_blog];
	}
	else if (tableView == self.categoriesTableView) {
		self.selectedCategory = [self.categoryIDs objectAtIndex:indexPath.row];
		[RFSettings setExternalBlogCategory:self.selectedCategory];
	}
}

@end
