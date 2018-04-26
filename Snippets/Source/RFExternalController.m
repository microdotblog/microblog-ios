//
//  RFExternalController.m
//  Micro.blog
//
//  Created by Manton Reece on 2/27/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFExternalController.h"

#import "RFXMLLinkParser.h"
#import "RFWordpressController.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"
#import "UUAlert.h"
#import "RFSettings.h"
#import "UUHttpSession.h"
#import "UUString.h"
#import "NSString+Extras.h"
#import <SafariServices/SafariServices.h>

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

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.progressSpinner stopAnimating];
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
			NSString* rsd_url = [rsd_parser.foundURLs firstObject];
            RFDispatchMainAsync (^{
                RFWordpressController* wordpress_controller = [[RFWordpressController alloc] initWithWebsite:full_url rsdURL:rsd_url];
                [self.navigationController pushViewController:wordpress_controller animated:YES];
            });
		}
		else {
			RFXMLLinkParser* micropub_parser = [RFXMLLinkParser parsedResponseFromData:response.rawResponse withRelValue:@"micropub"];
			if ([micropub_parser.foundURLs count] > 0) {
				RFXMLLinkParser* auth_parser = [RFXMLLinkParser parsedResponseFromData:response.rawResponse withRelValue:@"authorization_endpoint"];
				RFXMLLinkParser* token_parser = [RFXMLLinkParser parsedResponseFromData:response.rawResponse withRelValue:@"token_endpoint"];
				if (([auth_parser.foundURLs count] > 0) && ([token_parser.foundURLs count] > 0)) {
					NSString* auth_endpoint = [auth_parser.foundURLs firstObject];
					NSString* token_endpoint = [token_parser.foundURLs firstObject];
					NSString* micropub_endpoint = [micropub_parser.foundURLs firstObject];
					
					NSString* micropub_state = [[[NSString uuGenerateUUIDString] lowercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@""];

					NSMutableString* auth_with_params = [auth_endpoint mutableCopy];
					if (![auth_with_params containsString:@"?"]) {
						[auth_with_params appendString:@"?"];
					}
					[auth_with_params appendFormat:@"me=%@", [full_url rf_urlEncoded]];
					[auth_with_params appendFormat:@"&redirect_uri=%@", [@"https://micro.blog/micropub/redirect" rf_urlEncoded]];
					[auth_with_params appendFormat:@"&client_id=%@", [@"https://micro.blog/" rf_urlEncoded]];
					[auth_with_params appendFormat:@"&state=%@", micropub_state];
					[auth_with_params appendString:@"&scope=create"];
					[auth_with_params appendString:@"&response_type=code"];

					[RFSettings setExternalMicropubState:micropub_state];
					[RFSettings setExternalMicropubTokenEndpoint:token_endpoint];
					[RFSettings setExternalMicropubPostingEndpoint:micropub_endpoint];

					RFDispatchMainAsync (^{
						SFSafariViewController* safari_controller = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:auth_with_params]];
						[self presentViewController:safari_controller animated:YES completion:NULL];
					});
				}
			}
			else {
				RFDispatchMainAsync (^{
					[self.progressSpinner stopAnimating];
					[UUAlertViewController uuShowTwoButtonAlert:@"Error Discovering Settings" message:@"Could not find the XML-RPC endpoint or Micropub API for your weblog. Please see help.micro.blog for troubleshooting tips." buttonOne:@"Visit Help" buttonTwo:@"OK" completionHandler:^(NSInteger buttonIndex) {
						if (buttonIndex == 0) {
							[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://help.micro.blog/"] options:@{} completionHandler:^(BOOL success)
							{
							}];
						}
					}];
				});
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
