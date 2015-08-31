//
//  RFWordpressController.m
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFWordpressController.h"

#import "RFXMLRPCRequest.h"
#import "UIBarButtonItem+Extras.h"

@implementation RFWordpressController

- (instancetype) init
{
	self = [super initWithNibName:@"Wordpress" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupNavigation];
	[self setupScrollView];
}

- (void) setupNavigation
{
	self.title = @"External Blog";
	
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"close_button" target:self action:@selector(close:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
}

- (void) setupScrollView
{
	self.scrollView.contentSize = self.containerView.bounds.size;
	[self.scrollView addSubview:self.containerView];
	self.scrollView.delegate = self;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self.view endEditing:NO];
}

#pragma mark -

- (IBAction) close:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void) finish:(id)sender
{
	RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:@"http://www.manton.org/"];
	[request discoverEndpointWithCompletion:^(NSString* xmlrpcEndpointURL, NSString* blogID) {
		NSLog (@"endpoint: %@", xmlrpcEndpointURL);
	}];
//	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
