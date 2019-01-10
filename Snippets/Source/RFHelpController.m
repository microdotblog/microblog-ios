//
//  RFHelpController.m
//  Snippets
//
//  Created by Manton Reece on 8/21/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFHelpController.h"
#import "RFMacros.h"
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

- (void) webViewDidStartLoad:(UIWebView *)webView
{
	// hide until we're done loading
	self.webView.alpha = 0.0;
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
	// hide the header and background image and move the content up
	NSString* js = @"\
		document.getElementsByClassName('banner')[0].style.display = 'none';\
		document.getElementsByClassName('main')[0].style.paddingTop = '0px';\
		document.getElementsByTagName('body')[0].style.background = '#fff';\
	";
	[self.webView stringByEvaluatingJavaScriptFromString:js];
	
	// fade back in
	RFDispatchSeconds(0.1, ^{
		[UIView animateWithDuration:0.3 animations:^{
			self.webView.alpha = 1.0;
		}];
	});
}

@end
