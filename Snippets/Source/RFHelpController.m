//
//  RFHelpController.m
//  Snippets
//
//  Created by Manton Reece on 8/21/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFHelpController.h"

#import "UIBarButtonItem+Extras.h"

@implementation RFHelpController

- (instancetype) init
{
	self = [super initWithNibName:@"Help" bundle:nil];
	if (self) {
		self.url = [NSURL URLWithString:@"http://help.micro.blog/"];
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupBrowser];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self setupNavigation];
}

- (void) setupNavigation
{
	self.title = self.url.host;

	UIViewController* root_controller = [self.navigationController.viewControllers firstObject];
	if (self.navigationController.topViewController != root_controller) {
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
	}
}

- (void) setupBrowser
{
	self.webView.delegate = self;
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
	NSString* js = @"$('#snippets_link').remove()";
	[self.webView stringByEvaluatingJavaScriptFromString:js];

}

@end
