//
//  RFCategoriesController.m
//  Snippets
//
//  Created by Manton Reece on 8/31/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFCategoriesController.h"

#import "RFXMLRPCRequest.h"
#import "RFPostController.h"
#import "RFSettingChoiceCell.h"
#import "RFConstants.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"
#import "SSKeychain.h"

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
	
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"nav_back" target:self action:@selector(back:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
}

- (void) setupFormats
{
	self.formatValues = @[ @"None", @"Standard", @"Aside", @"Link", @"Quote", @"Status" ];
	self.selectedFormat = @"None";

	[self.formatsTableView registerNib:[UINib nibWithNibName:@"SettingChoiceCell" bundle:nil] forCellReuseIdentifier:kFormatCellIdentifier];
}

- (void) setupCategories
{
	self.categoryValues = @[ ];
	self.selectedCategory = @"";

	[self.categoriesTableView registerNib:[UINib nibWithNibName:@"SettingChoiceCell" bundle:nil] forCellReuseIdentifier:kCategoryCellIdentifier];
	
	[self.progressSpinner startAnimating];

	NSString* xmlrpc_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogEndpoint"];
	NSString* blog_s = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogID"];
	NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogUsername"];
	NSString* password = [SSKeychain passwordForService:@"ExternalBlog" account:@"default"];
	
	NSNumber* blog_id = [NSNumber numberWithInteger:[blog_s integerValue]];
	NSString* taxonomy = @"category";
	
	NSArray* params = @[ blog_id, username, password, taxonomy ];
	
	RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:xmlrpc_endpoint];
	[request sendMethod:@"wp.getTerms" params:params completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync (^{
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
		cell.checkmarkField.hidden = (indexPath.row > 0);
	}
	else if (tableView == self.categoriesTableView) {
		cell = [tableView dequeueReusableCellWithIdentifier:kCategoryCellIdentifier forIndexPath:indexPath];
		
		cell.nameField.text = [self.categoryValues objectAtIndex:indexPath.row];
		cell.checkmarkField.hidden = (indexPath.row > 0);
	}
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.formatsTableView) {
		self.selectedFormat = [self.formatValues objectAtIndex:indexPath.row];
	}
	else if (tableView == self.categoriesTableView) {
		self.selectedCategory = [self.categoryValues objectAtIndex:indexPath.row];
	}
}

@end
