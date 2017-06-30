//
//  RFSettingsController.m
//  Snippets
//
//  Created by Manton Reece on 9/1/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFSettingsController.h"

#import "RFSettingChoiceCell.h"
#import "RFConstants.h"
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
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupNavigation];
	[self setupServers];
	[self setupCategories];
//	[self setupGestures];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	NSIndexPath* index_path;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ExternalBlogIsPreferred"]) {
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
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
	}
}

- (void) setupServers
{
	self.serverNames = @[ @"Micro.blog hosted weblog", @"WordPress or compatible weblog" ];

	[self.serversTableView registerNib:[UINib nibWithNibName:@"SettingChoiceCell" bundle:nil] forCellReuseIdentifier:kServerCellIdentifier];
	self.serversTableView.layer.cornerRadius = 5.0;
}

- (void) setupCategories
{
	self.categoryValues = @[ ];
	self.selectedCategory = @"";

	NSString* xmlrpc_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogEndpoint"];
	NSString* blog_s = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogID"];
	NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogUsername"];
	NSString* password = [SSKeychain passwordForService:@"ExternalBlog" account:@"default"];

	if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogApp"] isEqualToString:@"WordPress"]) {
		self.categoriesIntroField.hidden = YES;
		self.categoriesTableView.hidden = YES;
		return;
	}

	[self.categoriesTableView registerNib:[UINib nibWithNibName:@"SettingChoiceCell" bundle:nil] forCellReuseIdentifier:kServerCellIdentifier];
	self.categoriesTableView.layer.cornerRadius = 5.0;
	
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

- (void) setupGestures
{
	UISwipeGestureRecognizer* swipe_right_gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
	swipe_right_gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:swipe_right_gesture];
}

- (void) setupSelectedCategory
{
	NSString* selected_category = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogCategory"];
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
	if (tableView == self.serversTableView) {
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
	
	if (tableView == self.serversTableView) {
		cell.nameField.text = [self.serverNames objectAtIndex:indexPath.row];
		cell.checkmarkView.hidden = (indexPath.row > 0);
	}
	else if (tableView == self.categoriesTableView) {
		cell.nameField.text = [self.categoryValues objectAtIndex:indexPath.row];
		NSString* category_id = [self.categoryIDs objectAtIndex:indexPath.row];
		NSString* selected_category = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogCategory"];
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
	if (tableView == self.serversTableView) {
		BOOL prefer_external_blog = (indexPath.row == 1);
		[[NSUserDefaults standardUserDefaults] setBool:prefer_external_blog forKey:@"ExternalBlogIsPreferred"];
	}
	else if (tableView == self.categoriesTableView) {
		self.selectedCategory = [self.categoryIDs objectAtIndex:indexPath.row];
		[[NSUserDefaults standardUserDefaults] setObject:self.selectedCategory forKey:@"ExternalBlogCategory"];
	}
}

@end
