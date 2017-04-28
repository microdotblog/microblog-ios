//
//  RFDiscoverController.m
//  Micro.blog
//
//  Created by Manton Reece on 4/28/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFDiscoverController.h"

#import "RFMacros.h"

@implementation RFDiscoverController

- (void) viewDidLoad
{
	[super viewDidLoad];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search:)];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
		
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search:)];
}

- (void) search:(id)sender
{
	NSString* fadein_js = @"$('.discover_search').show();";
//	NSString* focus_js = @"$('#search_input').focus();";

	[self.webView stringByEvaluatingJavaScriptFromString:fadein_js];
	
//	RFDispatchSeconds (1.0, ^{
//		[self.webView stringByEvaluatingJavaScriptFromString:focus_js];
//	});
}

@end
