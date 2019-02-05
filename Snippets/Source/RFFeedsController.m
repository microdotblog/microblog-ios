//
//  RFFeedsController.m
//  Micro.blog
//
//  Created by Manton Reece on 2/2/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFFeedsController.h"

#import "RFFeedCell.h"
#import "RFCategoryCell.h"
#import "RFFeed.h"
#import "RFClient.h"
#import "RFMicropub.h"
#import "RFConstants.h"
#import "RFSettings.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"

static NSString* const kCategoryCellIdentifier = @"CategoryCell";
static NSString* const kFeedCellIdentifier = @"FeedCell";

@implementation RFFeedsController

- (id) initWithSelectedCategories:(NSSet *)selectedCategories
{
	self = [super initWithNibName:@"Feeds" bundle:nil];
	if (self) {
		self.selectedCategories = selectedCategories;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupTable];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self startProgress];
	[self fetchCategories];
	[self fetchFeeds];
}

- (void) setupNavigation
{
	self.navigationItem.title = @"Categories & Feeds";
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
}

- (void) setupTable
{
	[self.categoriesTable registerNib:[UINib nibWithNibName:@"CategoryCell" bundle:nil] forCellReuseIdentifier:kCategoryCellIdentifier];
	self.categoriesTable.layer.cornerRadius = 5.0;

	[self.feedsTable registerNib:[UINib nibWithNibName:@"FeedCell" bundle:nil] forCellReuseIdentifier:kFeedCellIdentifier];
	self.feedsTable.layer.cornerRadius = 5.0;
}

- (void) startProgress
{
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityView startAnimating];
    activityView.frame = CGRectMake(0, 0, 40, 40);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
}

- (void) fetchCategories
{
	id client = nil;
	NSMutableDictionary* args = [NSMutableDictionary dictionary];
	[args setObject:@"category" forKey:@"q"];

	if ([RFSettings hasSnippetsBlog] && ![RFSettings prefersExternalBlog]) {
		NSString* uid = [RFSettings selectedBlogUid];
		if (uid) {
			[args setObject:uid forKey:@"mp-destination"];
		}
	
		client = [[RFClient alloc] initWithPath:@"/micropub"];
	}
	else if ([RFSettings hasMicropubBlog]) {
		NSString* micropub_endpoint = [RFSettings externalMicropubPostingEndpoint];
		client = [[RFMicropub alloc] initWithURL:micropub_endpoint];
	}
	
	[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
		NSMutableArray* new_categories = [NSMutableArray array];
		NSArray* categories = [response.parsedResponse objectForKey:@"categories"];
		for (NSString* s in categories) {
			[new_categories addObject:s];
		}

		RFDispatchMainAsync (^{
			self.categories = new_categories;
			[self.categoriesTable reloadData];

			for (NSInteger i = 0; i < self.categories.count; i++) {
				NSString* category_name = [self.categories objectAtIndex:i];
				if ([self.selectedCategories containsObject:category_name]) {
					NSIndexPath* index_path = [NSIndexPath indexPathForItem:i inSection:0];
					[self.categoriesTable selectRowAtIndexPath:index_path animated:NO scrollPosition:UITableViewScrollPositionNone];
				}
			}

    		self.navigationItem.rightBarButtonItem = nil;
		});
	}];
}

- (void) fetchFeeds
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/account/info/feeds"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		NSMutableArray* new_feeds = [NSMutableArray array];
		NSArray* feeds = [response.parsedResponse objectForKey:@"rss_feeds"];
		for (NSDictionary* info in feeds) {
			RFFeed* f = [[RFFeed alloc] initWithResponse:info];
			[new_feeds addObject:f];
		}
		
		RFDispatchMainAsync (^{
			self.feeds = new_feeds;
			[self.feedsTable reloadData];
			
			for (NSInteger i = 0; i < self.feeds.count; i++) {
				RFFeed* f = [self.feeds objectAtIndex:i];
				if (f.hasBot && !f.isDisabledCrossposting) {
					NSIndexPath* index_path = [NSIndexPath indexPathForItem:i inSection:0];
					[self.feedsTable selectRowAtIndexPath:index_path animated:NO scrollPosition:UITableViewScrollPositionNone];
				}
			}

    		self.navigationItem.rightBarButtonItem = nil;
		});
	}];
}

- (void) updateFeed:(RFFeed *)feed withDisabledCrossposting:(BOOL)setDisabled
{
	NSDictionary* params = @{
		@"is_disabled_crossposting": [NSNumber numberWithBool:setDisabled]
	};

	RFClient* client = [[RFClient alloc] initWithFormat:@"/account/feeds/%@", feed.feedID];
	[client postWithParams:params completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync (^{
			[self fetchFeeds];
		});
	}];
}

- (IBAction) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.categoriesTable) {
		return self.categories.count;
	}
	else {
		return self.feeds.count;
	}
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.categoriesTable) {
		RFCategoryCell* cell = [tableView dequeueReusableCellWithIdentifier:kCategoryCellIdentifier forIndexPath:indexPath];
		
		NSString* category_name = [self.categories objectAtIndex:indexPath.row];

		cell.nameField.text = category_name;
		cell.checkmarkView.hidden = YES;
		
		return cell;
	}
	else {
		RFFeedCell* cell = [tableView dequeueReusableCellWithIdentifier:kFeedCellIdentifier forIndexPath:indexPath];
		
		RFFeed* feed = [self.feeds objectAtIndex:indexPath.row];

		NSString* url_s = feed.url;
		url_s = [url_s stringByReplacingOccurrencesOfString:@"http://" withString:@""];
		url_s = [url_s stringByReplacingOccurrencesOfString:@"https://" withString:@""];

		cell.urlField.text = url_s;
		cell.usernamesField.text = feed.summary;
		cell.checkmarkView.hidden = !feed.isDisabledCrossposting;
		
		return cell;
	}
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.categoriesTable) {
		return indexPath;
	}
	else {
		RFFeed* feed = [self.feeds objectAtIndex:indexPath.row];
		if (feed.hasBot) {
			return indexPath;
		}
		else {
			return nil;
		}
	}
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.categoriesTable) {
		NSString* category_name = [self.categories objectAtIndex:indexPath.row];
		self.selectedCategories = [self.selectedCategories setByAddingObject:category_name];
	}
	else {
		RFFeed* feed = [self.feeds objectAtIndex:indexPath.row];
		[self updateFeed:feed withDisabledCrossposting:false];
	}
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.categoriesTable) {
		NSString* category_name = [self.categories objectAtIndex:indexPath.row];
		NSMutableSet* new_selected = [self.selectedCategories mutableCopy];
		[new_selected removeObject:category_name];
		self.selectedCategories = new_selected;
	}
	else {
		RFFeed* feed = [self.feeds objectAtIndex:indexPath.row];
		[self updateFeed:feed withDisabledCrossposting:true];
	}
}

@end
