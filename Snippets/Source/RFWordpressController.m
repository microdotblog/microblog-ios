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
#import "RFCategoriesController.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"
#import "UUAlert.h"
#import "SSKeychain.h"

@implementation RFWordpressController

- (instancetype) initWithWebsite:(NSString *)websiteURL
{
	self = [super initWithNibName:@"Wordpress" bundle:nil];
	if (self) {
		self.websiteURL = websiteURL;
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
	[[NSUserDefaults standardUserDefaults] setObject:self.usernameField.text forKey:@"ExternalBlogUsername"];
	[[NSUserDefaults standardUserDefaults] setObject:xmlrpcEndpointURL forKey:@"ExternalBlogEndpoint"];
	[[NSUserDefaults standardUserDefaults] setObject:blogID forKey:@"ExternalBlogID"];
	[SSKeychain setPassword:self.passwordField.text forService:@"ExternalBlog" account:@"default"];
	
	if ([xmlrpcEndpointURL containsString:@"xmlrpc.php"]) {
		[[NSUserDefaults standardUserDefaults] setObject:@"WordPress" forKey:@"ExternalBlogApp"];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:@"Other" forKey:@"ExternalBlogApp"];
	}
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
	
	RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:[self normalizeURL:self.websiteURL]];
	[request discoverEndpointWithCompletion:^(NSString* xmlrpcEndpointURL, NSString* blogID) {
		RFDispatchMainAsync (^{
			[self.progressSpinner stopAnimating];
			if (xmlrpcEndpointURL && blogID) {
				[self saveAccountWithEndpointURL:xmlrpcEndpointURL blogID:blogID];
				if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogApp"] isEqualToString:@"WordPress"]) {
					RFCategoriesController* categories_controller = [[RFCategoriesController alloc] init];
					[self.navigationController pushViewController:categories_controller animated:YES];
				}
				else {
					RFPostController* post_controller = [[RFPostController alloc] init];
					[self.navigationController pushViewController:post_controller animated:YES];
				}
			}
			else {
				[UIAlertView uuShowTwoButtonAlert:@"Error Discovering Settings" message:@"Could not find the XML-RPC endpoint for your weblog. Please see help.micro.blog for troubleshooting tips." buttonOne:@"Visit Help" buttonTwo:@"OK" completionHandler:^(NSInteger buttonIndex) {
					if (buttonIndex == 0) {
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://help.micro.blog/"]];
					}
				}];
			}
		});
	}];
}

@end
