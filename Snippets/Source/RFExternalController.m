//
//  RFExternalController.m
//  Micro.blog
//
//  Created by Manton Reece on 2/27/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFExternalController.h"

#import "RFXMLLinkParser.h"
#import "RFWordpressController.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"
#import "UUAlert.h"
#import "SSKeychain.h"
#import "UUHttpSession.h"

@implementation RFExternalController

- (instancetype) init
{
	self = [super initWithNibName:@"External" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
}

- (void) setupNavigation
{
	self.title = @"External Blog";
	
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"close_button" target:self action:@selector(close:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.websiteField) {
		RFDispatchMainAsync (^{
			[self finish:nil];
		});
	}
	
	return YES;
}

- (IBAction) close:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void) finish:(id)sender
{
	[self.view endEditing:NO];
	[self.progressSpinner startAnimating];

	NSString* full_url = [self normalizeURL:self.websiteField.text];

	UUHttpRequest* request = [UUHttpRequest getRequest:full_url queryArguments:nil];
	[UUHttpSession executeRequest:request completionHandler:^(UUHttpResponse* response) {
		RFXMLLinkParser* rsd_parser = [RFXMLLinkParser parsedResponseFromData:response.rawResponse withRelValue:@"EditURI"];
		if ([rsd_parser.foundURLs count] > 0) {
			RFWordpressController* wordpress_controller = [[RFWordpressController alloc] initWithWebsite:full_url];
			[self.navigationController pushViewController:wordpress_controller animated:YES];
		}
		else {
			RFXMLLinkParser* micropub_parser = [RFXMLLinkParser parsedResponseFromData:response.rawResponse withRelValue:@"micropub"];
			if ([micropub_parser.foundURLs count] > 0) {
			}
		}
	}];
}

- (NSString *) normalizeURL:(NSString *)url
{
	NSString* s = url;
	if (![s containsString:@"http"]) {
		s = [@"http://" stringByAppendingString:s];
	}
	
	return s;
}

@end
