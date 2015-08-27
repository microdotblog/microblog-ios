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
#import "RFConstants.h"
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
	self.navigationItem.rightBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"new_button" target:self action:@selector(promptNewPost:)];
//	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(promptNewPost:)];
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadTimelineNotification:) name:@"RFLoadTimelineNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postWasFavoritedNotification:) name:kPostWasFavoritedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postWasUnfavoritedNotification:) name:kPostWasUnfavoritedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postWasDeletedNotification:) name:kPostWasDeletedNotification object:nil];
}

- (void) setupRefresh
{
	self.refreshControl = [[UIRefreshControl alloc] init];
	[self.refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
	[self.webView.scrollView addSubview:self.refreshControl];
}

- (void) setupGestures
{
	UISwipeGestureRecognizer* swipe_right_gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
	swipe_right_gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:swipe_right_gesture];
}

- (CGRect) rectOfPostID:(NSString *)postID
{
	NSString* left_js = [NSString stringWithFormat:@"$('#post_%@').position().left;", postID];
	NSString* top_js = [NSString stringWithFormat:@"$('#post_%@').position().top;", postID];
	NSString* width_js = [NSString stringWithFormat:@"$('#post_%@').width();", postID];
	NSString* height_js = [NSString stringWithFormat:@"$('#post_%@').height();", postID];
	
	NSString* left_s = [self.webView stringByEvaluatingJavaScriptFromString:left_js];
	NSString* top_s = [self.webView stringByEvaluatingJavaScriptFromString:top_js];
	NSString* width_s = [self.webView stringByEvaluatingJavaScriptFromString:width_js];
	NSString* height_s = [self.webView stringByEvaluatingJavaScriptFromString:height_js];
	
	CGFloat top_f = [top_s floatValue];
	top_f -= self.webView.scrollView.contentOffset.y;
	
	return CGRectMake ([left_s floatValue], top_f, [width_s floatValue], [height_s floatValue]);
}

- (RFOptionsPopoverType) popoverTypeOfPostID:(NSString *)postID
{
	NSString* is_favorite_js = [NSString stringWithFormat:@"$('#post_%@').hasClass('is_favorite');", postID];
	NSString* is_deletable_js = [NSString stringWithFormat:@"$('#post_%@').hasClass('is_deletable');", postID];

	NSString* is_favorite_s = [self.webView stringByEvaluatingJavaScriptFromString:is_favorite_js];
	NSString* is_deletable_s = [self.webView stringByEvaluatingJavaScriptFromString:is_deletable_js];

	if ([is_favorite_s boolValue]) {
		return kOptionsPopoverWithUnfavorite;
	}
	else if ([is_deletable_s boolValue]) {
		return kOptionsPopoverWithDelete;
	}
	else {
		return kOptionsPopoverDefault;
	}
}

- (NSString *) usernameOfPostID:(NSString *)postID
{
	NSString* username_js = [NSString stringWithFormat:@"$('#post_%@').find('.post_username').text();", postID];
	NSString* username_s = [self.webView stringByEvaluatingJavaScriptFromString:username_js];
	return [username_s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark -

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
	if ([self.endpoint isEqualToString:@"/iphone/replies"]) {
		url = @"http://snippets.today/iphone/replies";
	}
	else if ([self.endpoint isEqualToString:@"/iphone/favorites"]) {
		url = @"http://snippets.today/iphone/favorites";
	}
	else if ([self.endpoint containsString:@"/iphone/conversation"]) {
		url = [NSString stringWithFormat:@"http://snippets.today%@", self.endpoint];
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

- (void) postWasFavoritedNotification:(NSNotification *)notification
{
	NSString* post_id = [notification.userInfo objectForKey:kPostNotificationPostIDKey];
	NSString* js = [NSString stringWithFormat:@"$('#post_%@').addClass('is_favorite');", post_id];
	[self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void) postWasUnfavoritedNotification:(NSNotification *)notification
{
	NSString* post_id = [notification.userInfo objectForKey:kPostNotificationPostIDKey];
	NSString* js = [NSString stringWithFormat:@"$('#post_%@').removeClass('is_favorite');", post_id];
	[self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void) postWasDeletedNotification:(NSNotification *)notification
{
	NSString* post_id = [notification.userInfo objectForKey:kPostNotificationPostIDKey];
	NSString* js = [NSString stringWithFormat:@"$('#post_%@').hide(300);", post_id];
	[self.webView stringByEvaluatingJavaScriptFromString:js];
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

- (void) webViewDidStartLoad:(UIWebView *)webView
{
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
}

- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	NSLog (@"Web view error: %@", error);
}

@end
