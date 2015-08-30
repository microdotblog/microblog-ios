//
//  RFWordpressController.m
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFWordpressController.h"

#import "RFXMLRPCRequest.h"

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
	
	self.title = @"External Blog";
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
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
