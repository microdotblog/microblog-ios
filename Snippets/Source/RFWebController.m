//
//  RFWebController.m
//  Snippets
//
//  Created by Manton Reece on 8/21/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFWebController.h"

@implementation RFWebController

- (instancetype) initWithURL:(NSURL *)url
{
	self = [super initWithNibName:@"Web" bundle:nil];
	if (self) {
		self.url = url;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = self.url.host;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(done:)];
	
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void) done:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
