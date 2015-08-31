//
//  RFWordpressController.m
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFWordpressController.h"

#import "RFXMLRPCRequest.h"
#import "RFPostController.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"
#import "UUAlert.h"
#import "SSKeychain.h"

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

- (NSString *) normalizeURL:(NSString *)url
{
	NSString* s = url;
	if (![s containsString:@"http"]) {
		s = [@"http://" stringByAppendingString:s];
	}
	
	return s;
}

- (void) saveAccountWithEndpointURL:(NSString *)xmlrpcEndpointURL blogID:(NSString *)blogID
{
}

#pragma mark -

- (IBAction) close:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void) finish:(id)sender
{
	[self.view endEditing:NO];
	[self.progressSpinner startAnimating];
	
	RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:[self normalizeURL:self.websiteField.text]];
	[request discoverEndpointWithCompletion:^(NSString* xmlrpcEndpointURL, NSString* blogID) {
		RFDispatchMainAsync (^{
			[self.progressSpinner stopAnimating];
			if (xmlrpcEndpointURL && blogID) {
				[self saveAccountWithEndpointURL:xmlrpcEndpointURL blogID:blogID];
				RFPostController* post_controller = [[RFPostController alloc] init];
				[self.navigationController pushViewController:post_controller animated:YES];
			}
			else {
				[UIAlertView uuShowOneButtonAlert:@"Error Discovering Settings" message:@"Could not find the XML-RPC endpoint for your weblog. Please see help.snippets.today for troubleshooting tips." button:@"OK" completionHandler:NULL];
			}
		});
	}];
}

@end
