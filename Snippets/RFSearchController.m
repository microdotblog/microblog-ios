//
//  RFSearchController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/6/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFSearchController.h"

#import "NSString+Extras.h"

@implementation RFSearchController

- (instancetype) init
{
	self = [super initWithNibName:@"Search" bundle:nil];
	if (self) {
		self.endpoint = @"";
		self.timelineTitle = @"Search";
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	
	self.webView.hidden = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.searchBar becomeFirstResponder];
}

- (void) setupNavigation
{
	[super setupNavigation];

	self.title = @"Search";
	self.navigationItem.rightBarButtonItem = nil;
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	self.webView.hidden = NO;
	[searchBar resignFirstResponder];
	
	self.endpoint = [NSString stringWithFormat:@"/hybrid/discover/search?q=%@", [searchBar.text rf_urlEncoded]];
	[self refreshTimeline];
}

@end
