//
//  RFCategoriesController.m
//  Snippets
//
//  Created by Manton Reece on 8/31/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFCategoriesController.h"

#import "RFXMLRPCRequest.h"
#import "RFXMLRPCParser.h"
#import "RFPostController.h"
#import "RFSettingChoiceCell.h"
#import "RFConstants.h"
#import "RFSettings.h"
#import "RFMacros.h"
#import "UITraitCollection+Extras.h"
#import "UIBarButtonItem+Extras.h"

static NSString* const kFormatCellIdentifier = @"FormatCell";
static NSString* const kCategoryCellIdentifier = @"CategoryCell";

@implementation RFCategoriesController

- (instancetype) init
{
	self = [super initWithNibName:@"Categories" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupNavigation];
	[self setupFormats];
	[self setupCategories];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.formatsTableView flashScrollIndicators];
}

- (void) setupNavigation
{
	self.title = @"Blog Categories";
	
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
	if ([UITraitCollection rf_isDarkMode]) {
		self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
	}
}

- (void) setupFormats
{
	self.formatValues = @[ @"Standard", @"Status", @"Aside", @"Link", @"Quote", @"Audio" ];
	self.selectedFormat = @"";

	[self.formatsTableView registerNib:[UINib nibWithNibName:@"SettingChoiceCell" bundle:nil] forCellReuseIdentifier:kFormatCellIdentifier];
}

- (void) setupCategories
{
	self.categoryValues = @[ ];
	self.selectedCategory = @"";

	[self.categoriesTableView registerNib:[UINib nibWithNibName:@"SettingChoiceCell" bundle:nil] forCellReuseIdentifier:kCategoryCellIdentifier];
	
	[self.progressSpinner startAnimating];

	NSString* xmlrpc_endpoint = [RFSettings externalBlogEndpoint];
	NSString* blog_s = [RFSettings externalBlogID];
	NSString* username = [RFSettings externalBlogUsername];
	NSString* password = [RFSettings externalBlogPassword];
	
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
			[self.progressSpinner stopAnimating];
		});
	}];
}

- (IBAction) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) finish:(id)sender
{
	[RFSettings setExternalBlogFormat:self.selectedFormat];
	[RFSettings setExternalBlogCategory:self.selectedCategory];
	
	RFPostController* post_controller = [[RFPostController alloc] init];
	[self.navigationController pushViewController:post_controller animated:YES];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.formatsTableView) {
		return self.formatValues.count;
	}
	else {
		return self.categoryValues.count;
	}
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFSettingChoiceCell* cell = nil;
	
	if (tableView == self.formatsTableView) {
		cell = [tableView dequeueReusableCellWithIdentifier:kFormatCellIdentifier forIndexPath:indexPath];
		
		cell.nameField.text = [self.formatValues objectAtIndex:indexPath.row];
		cell.checkmarkView.hidden = (indexPath.row > 0);
	}
	else if (tableView == self.categoriesTableView) {
		cell = [tableView dequeueReusableCellWithIdentifier:kCategoryCellIdentifier forIndexPath:indexPath];
		
		cell.nameField.text = [self.categoryValues objectAtIndex:indexPath.row];
		cell.checkmarkView.hidden = (indexPath.row > 0);
	}
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.formatsTableView) {
		self.selectedFormat = [self.formatValues objectAtIndex:indexPath.row];
	}
	else if (tableView == self.categoriesTableView) {
		self.selectedCategory = [self.categoryIDs objectAtIndex:indexPath.row];
	}
}

@end
