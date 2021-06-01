//
//  RFWordpressController.m
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFWordpressController.h"

#import "RFXMLRPCRequest.h"
#import "RFXMLRPCParser.h"
#import "RFPostController.h"
#import "RFCategoriesController.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"
#import "UUAlert.h"
#import "RFSettings.h"
#import "UITraitCollection+Extras.h"

@implementation RFWordpressController

- (instancetype) initWithWebsite:(NSString *)websiteURL rsdURL:(NSString *)rsdURL
{
	self = [super initWithNibName:@"Wordpress" bundle:nil];
	if (self) {
		self.websiteURL = websiteURL;
		self.rsdURL = rsdURL;
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
	
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_closeBarButtonWithTarget:self action:@selector(close:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
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
	[RFSettings setExternalBlogUsername:self.usernameField.text];
	[RFSettings setExternalBlogEndpoint:xmlrpcEndpointURL];
	[RFSettings setExternalBlogID:blogID];
	[RFSettings setPrefersExternalBlog:YES];
	[RFSettings setExternalBlogPassword:self.passwordField.text];
	
	if ([xmlrpcEndpointURL containsString:@"xmlrpc.php"]) {
		[RFSettings setExternalBlogApp:@"WordPress"];
	}
	else {
		[RFSettings setExternalBlogApp:@"Other"];
	}
}

- (void) verifyUsername:(NSString *)username password:(NSString *)password forEndpoint:(NSString *)xmlrpcEndpoint withCompletion:(void (^)())handler
{
	NSString* method_name = @"blogger.getUserInfo";
	NSString* app_key = @"";
	NSArray* params = @[ app_key, username, password ];
	
	RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:xmlrpcEndpoint];
	[request sendMethod:method_name params:params completion:^(UUHttpResponse* response) {
		RFXMLRPCParser* xmlrpc = [RFXMLRPCParser parsedResponseFromData:response.rawResponse];
		RFDispatchMainAsync ((^{
			if (xmlrpc.responseFault) {
				NSString* s = [NSString stringWithFormat:@"%@ (error: %@)", xmlrpc.responseFault[@"faultString"], xmlrpc.responseFault[@"faultCode"]];
				[UUAlertViewController uuShowOneButtonAlert:@"Error Signing In" message:s button:@"OK" completionHandler:NULL];
				[self.progressSpinner stopAnimating];
			}
			else {
				handler();
			}
		}));
	}];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.usernameField) {
		RFDispatchMainAsync (^{
			[self.passwordField becomeFirstResponder];
		});
	}
	else if (textField == self.passwordField) {
		RFDispatchMainAsync (^{
			[self finish:nil];
		});
	}
	
	return YES;
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
	
	RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:self.rsdURL];
	[request discoverEndpointWithCompletion:^(NSString* xmlrpcEndpointURL, NSString* blogID) {
		RFDispatchMainAsync (^{
			[self.progressSpinner stopAnimating];
			if (xmlrpcEndpointURL && blogID) {
				[self verifyUsername:self.usernameField.text password:self.passwordField.text forEndpoint:xmlrpcEndpointURL withCompletion:^{
					[self saveAccountWithEndpointURL:xmlrpcEndpointURL blogID:blogID];
					if ([RFSettings externalBlogUsesWordPress]) {
						RFCategoriesController* categories_controller = [[RFCategoriesController alloc] init];
						[self.navigationController pushViewController:categories_controller animated:YES];
					}
					else {
						RFPostController* post_controller = [[RFPostController alloc] init];
						[self.navigationController pushViewController:post_controller animated:YES];
					}
				}];
			}
			else {
				[UUAlertViewController uuShowTwoButtonAlert:@"Error Discovering Settings" message:@"Could not find the XML-RPC endpoint for your weblog. Please see help.micro.blog for troubleshooting tips." buttonOne:@"Visit Help" buttonTwo:@"OK" completionHandler:^(NSInteger buttonIndex) {
					if (buttonIndex == 0) {
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://help.micro.blog/"] options:@{} completionHandler:nil];
					}
				}];
			}
		});
	}];
}

@end
