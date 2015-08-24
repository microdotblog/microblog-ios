//
//  RFTimelineController.m
//  Snippets
//
//  Created by Manton Reece on 6/4/15.
//  Copyright (c) 2015 Riverfold Software. All rights reserved.
//

#import "RFTimelineController.h"

#import "RFPostController.h"
#import "RFWebController.h"
#import "UIBarButtonItem+Extras.h"
#import "SSKeychain.h"
#import <SafariServices/SafariServices.h>

@implementation RFTimelineController

- (instancetype) init
{
	self = [super initWithNibName:@"Timeline" bundle:nil];
	if (self) {
		self.endpoint = @"/iphone/timeline";
		self.timelineTitle = @"Timeline";
	}
	
	return self;
}

- (instancetype) initWithEndpoint:(NSString *)endpoint title:(NSString *)title
{
	self = [self init];
	if (self) {
		self.endpoint = endpoint;
		self.timelineTitle = title;
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupNotifications];
	[self setupRefresh];
	[self setupGestures];
	
	[self refreshTimeline];
}

- (void) setupNavigation
{
	self.title = self.timelineTitle;
	
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(promptNewPost:)];
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadTimelineNotification:) name:@"RFLoadTimelineNotification" object:nil];
}

- (void) setupRefresh
{
	self.refreshControl = [[UIRefreshControl alloc] init];
	[self.refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
	[self.webView.scrollView addSubview:self.refreshControl];
}

- (void) setupGestures
{
	UISwipeGestureRecognizer* swipe_left_gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
	swipe_left_gesture.direction = UISwipeGestureRecognizerDirectionLeft;
	[self.view addGestureRecognizer:swipe_left_gesture];

	UISwipeGestureRecognizer* swipe_right_gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
	swipe_right_gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:swipe_right_gesture];
}

#pragma mark -

- (void) swipeLeft:(UIGestureRecognizer *)gesture
{
//	RFTimelineController* conversation_controller = [[RFTimelineController alloc] initWithEndpoint:@"/iphone/conversation" title:@"Conversation"];
//	[self.navigationController pushViewController:conversation_controller animated:YES];
}

- (void) swipeRight:(UIGestureRecognizer *)gesture
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) promptNewPost:(id)sender
{
	RFPostController* post_controller = [[RFPostController alloc] init];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:post_controller];
	[self.navigationController presentViewController:nav_controller animated:YES completion:NULL];
}

- (void) handleRefresh:(UIRefreshControl *)refresh
{
	[self refreshTimeline];
	[refresh endRefreshing];
}

- (void) refreshTimeline
{
	NSString* token = [SSKeychain passwordForService:@"Snippets" account:@"default"];
	if (token) {
		[self loadTimelineForToken:token];
	}
}

- (void) loadTimelineForToken:(NSString *)token
{
	NSString* url;
	if ([self.endpoint isEqual:@"/iphone/replies"]) {
		url = @"http://snippets.today/iphone/replies";
	}
	else if ([self.endpoint isEqual:@"/iphone/favorites"]) {
		url = @"http://snippets.today/iphone/favorites";
	}
	else {
		int width = [UIScreen mainScreen].bounds.size.width;
		url = [NSString stringWithFormat:@"http://snippets.today/iphone/signin?token=%@&width=%d", token, width];
	}
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

- (void) loadTimelineNotification:(NSNotification *)notification
{
	NSString* token = [notification.userInfo objectForKey:@"token"];
	[SSKeychain setPassword:token forService:@"Snippets" account:@"default"];
	[self loadTimelineForToken:token];
}

- (void) showURL:(NSURL *)url
{
	Class safari_class = NSClassFromString (@"SFSafariViewController");
	if (safari_class != nil) {
		id safari_controller = [[safari_class alloc] initWithURL:url];
		[self presentViewController:safari_controller animated:YES completion:NULL];
	}
	else {
		RFWebController* web_controller = [[RFWebController alloc] initWithURL:url];
		UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:web_controller];
		[self presentViewController:nav_controller animated:YES completion:NULL];
	}
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[self showURL:request.URL];
		return NO;
	}
	else {
		return YES;
	}
}

@end
