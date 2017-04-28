//
//  RFDiscoverController.m
//  Micro.blog
//
//  Created by Manton Reece on 4/28/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFDiscoverController.h"

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
	NSString* js = @"$('.discover_search').show()";
	[self.webView stringByEvaluatingJavaScriptFromString:js];
}

@end
