//
//  RFFeedsController.m
//  Micro.blog
//
//  Created by Manton Reece on 2/2/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFFeedsController.h"

#import "RFFeedCell.h"
#import "RFClient.h"
#import "RFConstants.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"

static NSString* const kFeedCellIdentifier = @"FeedCell";

@implementation RFFeedsController

- (id) init
{
	self = [super initWithNibName:@"Feeds" bundle:nil];
	if (self) {
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

	[self fetchFeeds];
}

- (void) setupNavigation
{
	self.navigationItem.title = @"Feeds";
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
}

- (void) setupTable
{
	[self.feedsTable registerNib:[UINib nibWithNibName:@"FeedCell" bundle:nil] forCellReuseIdentifier:kFeedCellIdentifier];
	self.feedsTable.layer.cornerRadius = 5.0;
}

- (void) fetchFeeds
{
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityView startAnimating];
    activityView.frame = CGRectMake(0, 0, 40, 40);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];

	RFClient* client = [[RFClient alloc] initWithPath:@"/account/info/feeds"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		self.feeds = [response.parsedResponse objectForKey:@"rss_feeds"];
		RFDispatchMainAsync (^{
			[self.feedsTable reloadData];
			
			for (NSInteger i = 0; i < self.feeds.count; i++) {
				NSDictionary* info = [self.feeds objectAtIndex:i];
				if (![info[@"is_disabled_crossposting"] boolValue]) {
					NSIndexPath* index_path = [NSIndexPath indexPathForItem:i inSection:0];
					[self.feedsTable selectRowAtIndexPath:index_path animated:NO scrollPosition:UITableViewScrollPositionNone];
				}
			}

    		self.navigationItem.rightBarButtonItem = nil;
		});
	}];
}

- (void) updateFeed:(NSDictionary *)feed withDisabledCrossposting:(BOOL)setDisabled
{
	NSDictionary* params = @{
		@"is_disabled_crossposting": [NSNumber numberWithBool:setDisabled]
	};

	RFClient* client = [[RFClient alloc] initWithFormat:@"/account/feeds/%@", feed[@"id"]];
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
	return self.feeds.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFFeedCell* cell = [tableView dequeueReusableCellWithIdentifier:kFeedCellIdentifier forIndexPath:indexPath];
	
	NSDictionary* info = [self.feeds objectAtIndex:indexPath.row];

	NSString* url_s = info[@"url"];
	NSString* twitter_s = info[@"twitter_username"];
	NSString* facebook_s = info[@"facebook_name"];
	NSString* usernames_s = @"";
	if ((twitter_s.length > 0) && (facebook_s.length > 0)) {
		usernames_s = [NSString stringWithFormat:@"Twitter: %@, Facebook: %@", twitter_s, facebook_s];
	}
	else if (twitter_s.length > 0) {
		usernames_s = [NSString stringWithFormat:@"Twitter: %@", twitter_s];
	}
	else if (facebook_s.length > 0) {
		usernames_s = [NSString stringWithFormat:@"Facebook: %@", facebook_s];
	}
	else {
		usernames_s = @"Cross-posting has not been added.";
	}
	
	url_s = [url_s stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	url_s = [url_s stringByReplacingOccurrencesOfString:@"https://" withString:@""];

	cell.urlField.text = url_s;
	cell.usernamesField.text = usernames_s;
	cell.checkmarkView.hidden = ![info[@"is_disabled_crossposting"] boolValue];
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary* info = [self.feeds objectAtIndex:indexPath.row];
	[self updateFeed:info withDisabledCrossposting:false];
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary* info = [self.feeds objectAtIndex:indexPath.row];
	[self updateFeed:info withDisabledCrossposting:true];
}

@end
