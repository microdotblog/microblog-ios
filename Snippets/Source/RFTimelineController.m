//
//  RFTimelineController.m
//  Snippets
//
//  Created by Manton Reece on 6/4/15.
//  Copyright (c) 2015 Riverfold Software. All rights reserved.
//

#import "RFTimelineController.h"

#import "RFPostController.h"
#import "RFWordpressController.h"
#import "RFExternalController.h"
#import "RFCategoriesController.h"
#import "RFClient.h"
#import "RFConstants.h"
#import "RFSettings.h"
#import "UIBarButtonItem+Extras.h"
#import "UIFont+Extras.h"
#import "SSKeychain.h"
#import "RFMacros.h"
#import <SafariServices/SafariServices.h>

@implementation RFTimelineController

- (instancetype) init
{
	self = [super initWithNibName:@"Timeline" bundle:nil];
	if (self) {
		self.endpoint = @"/hybrid/timeline";
		self.timelineTitle = @"Timeline";
	}
	
	return self;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil endPoint:(NSString*)endpoint title:(NSString*)title
{
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    if (self) {
        self.endpoint = endpoint;
        self.timelineTitle = title;
    }
    
    return self;
}

- (instancetype) initWithEndpoint:(NSString *)endpoint title:(NSString *)title
{
	self = [self init];
	if (self) {
		self.endpoint = endpoint;
		self.timelineTitle = title;
		
		if ([self.endpoint containsString:@"/conversation/"]) {
			self.isConversation = YES;
		}
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
	[self setupScrollView];
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	if (self.view.bounds.size.width != self.lastRefreshWidth) {
		self.lastRefreshWidth = self.view.bounds.size.width;
		[self refreshTimeline];
	}
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self setupNavigation];
	[self setupPreventHorizontalScrolling];

	[self.refreshControl endRefreshing];
}

- (void) setupNavigation
{
	self.title = self.timelineTitle;
	
	UIViewController* root_controller = [self.navigationController.viewControllers firstObject];
	if (self.navigationController.topViewController != root_controller) {
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
	}
	
	if (self.isConversation) {
		self.navigationItem.rightBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"reply_button" target:self action:@selector(promptNewReply:)];
	}
	else {
		self.navigationItem.rightBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"new_button" target:self action:@selector(promptNewPost:)];
	}
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadTimelineNotification:) name:kLoadTimelineNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openPostingNotification:) name:kOpenPostingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postWasFavoritedNotification:) name:kPostWasFavoritedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postWasUnfavoritedNotification:) name:kPostWasUnfavoritedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postWasDeletedNotification:) name:kPostWasDeletedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferredContentSize:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void) setupRefresh
{
	self.refreshControl = [[UIRefreshControl alloc] init];
	[self.webView.scrollView addSubview:self.refreshControl];
	self.webView.scrollView.showsHorizontalScrollIndicator = NO;
}

- (void) setupScrollView
{
	self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
	self.webView.scrollView.delegate = self;
}

- (void) setupPreventHorizontalScrolling
{
	[self.webView.scrollView setContentSize:CGSizeMake (self.webView.frame.size.width, self.webView.scrollView.contentSize.height)];
}

- (UIResponder *) nextResponder
{
	if (self.menuController && !RFIsPhone()) {
		return self.menuController;
	}
	else {
		return [super nextResponder];
	}
}

#pragma mark -

- (void) setSelected:(BOOL)isSelected withPostID:(NSString *)postID
{
	NSString* js;
	if (isSelected) {
		js = [NSString stringWithFormat:@"$('#post_%@').addClass('is_selected');", postID];
	}
	else {
		js = [NSString stringWithFormat:@"$('#post_%@').removeClass('is_selected');", postID];
	}
	[self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (CGRect) rectOfPostID:(NSString *)postID
{
//	NSString* left_js = [NSString stringWithFormat:@"$('#post_%@').position().left;", postID];
//	NSString* width_js = [NSString stringWithFormat:@"$('#post_%@').width();", postID];
	NSString* top_js = [NSString stringWithFormat:@"$('#post_%@').position().top;", postID];
	NSString* height_js = [NSString stringWithFormat:@"$('#post_%@').height();", postID];
	
	NSString* top_s = [self.webView stringByEvaluatingJavaScriptFromString:top_js];
	NSString* height_s = [self.webView stringByEvaluatingJavaScriptFromString:height_js];
	
	CGFloat top_f = [top_s floatValue];
	top_f -= self.webView.scrollView.contentOffset.y;
	
	// adjust to full cell width
	CGFloat left_f = 0.0;
	CGFloat width_f = self.view.bounds.size.width;
	
	return CGRectMake (left_f, top_f, width_f, [height_s floatValue]);
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

- (NSString *) firstPostID
{
	NSString* first_js = [NSString stringWithFormat:@"$('.post').first().attr('id').replace('post_', '')"];
	NSString* first_s = [self.webView stringByEvaluatingJavaScriptFromString:first_js];
	return [first_s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *) usernameOfPostID:(NSString *)postID
{
	NSString* username_js = [NSString stringWithFormat:@"$('#post_%@').find('.post_username').text();", postID];
	NSString* username_s = [self.webView stringByEvaluatingJavaScriptFromString:username_js];
	return [username_s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *) linkOfPostID:(NSString *)postID
{
	NSString* username_js = [NSString stringWithFormat:@"$('#post_%@').find('.post_link').text();", postID];
	NSString* username_s = [self.webView stringByEvaluatingJavaScriptFromString:username_js];
	return [username_s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark -

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	[self performSelector:@selector(refreshTimeline) withObject:nil afterDelay:0.5];
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) promptNewPost:(id)sender
{
	if ([RFSettings needsExternalBlogSetup]) {
		RFExternalController* wordpress_controller = [[RFExternalController alloc] init];
		UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:wordpress_controller];
		[self.navigationController presentViewController:nav_controller animated:YES completion:NULL];
	}
	else {
		RFPostController* post_controller = [[RFPostController alloc] init];
		UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:post_controller];
		[self.navigationController presentViewController:nav_controller animated:YES completion:NULL];
	}
}

- (IBAction) promptNewReply:(id)sender
{
	NSString* post_id = [self firstPostID];
	NSString* post_username = [self usernameOfPostID:post_id];
	
	RFPostController* post_controller = [[RFPostController alloc] initWithReplyTo:post_id replyUsername:post_username];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:post_controller];
	[self.navigationController presentViewController:nav_controller animated:YES completion:NULL];
}

- (void) refreshTimeline
{
	[self refreshTimelineShowingSpinner:NO];
}

- (void) refreshTimelineShowingSpinner:(BOOL)showSpinner
{
	if (showSpinner) {
		[self.refreshControl beginRefreshing];
	}
	
	NSString* token = [SSKeychain passwordForService:@"Snippets" account:@"default"];
	if (token) {
		[self loadTimelineForToken:token];
	}
}

- (void) loadTimelineForToken:(NSString *)token
{
	NSDate* now = [NSDate date];
	long timezone_offset = 0 - [[NSTimeZone systemTimeZone] secondsFromGMTForDate:now] / 60;
	int width = self.view.bounds.size.width;
	CGFloat fontsize = [UIFont rf_preferredTimelineFontSize];
	
	RFClient* client;
	if ([self.endpoint isEqualToString:@"/hybrid/mentions"]) {
		client = [[RFClient alloc] initWithFormat:@"%@?width=%d&fontsize=%f", self.endpoint, width, fontsize];
	}
	else if ([self.endpoint isEqualToString:@"/hybrid/favorites"]) {
		client = [[RFClient alloc] initWithFormat:@"%@?width=%d&fontsize=%f", self.endpoint, width, fontsize];
	}
	else if ([self.endpoint isEqualToString:@"/hybrid/discover"]) {
		client = [[RFClient alloc] initWithFormat:@"%@?width=%d&fontsize=%f", self.endpoint, width, fontsize];
	}
	else if ([self.endpoint containsString:@"/hybrid/conversation"]) {
		client = [[RFClient alloc] initWithFormat:@"%@?width=%d&fontsize=%f", self.endpoint, width, fontsize];
	}
	else if ([self.endpoint containsString:@"/hybrid/posts/"]) {
		client = [[RFClient alloc] initWithFormat:@"%@?width=%d&fontsize=%f", self.endpoint, width, fontsize];
	}
	else if ([self.endpoint containsString:@"/hybrid/discover/search"]) {
		client = [[RFClient alloc] initWithFormat:@"%@&width=%d&fontsize=%f", self.endpoint, width, fontsize];
	}
	else if ([self.endpoint containsString:@"/hybrid/following/"])
	{
		client = [[RFClient alloc] initWithPath:self.endpoint];
	}
	else {
		client = [[RFClient alloc] initWithFormat:@"/hybrid/signin?token=%@&width=%d&fontsize=%f&minutes=%ld", token, width, fontsize, timezone_offset];
	}
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:client.url]]];
}

- (void) loadTimelineNotification:(NSNotification *)notification
{
	NSString* token = [notification.userInfo objectForKey:@"token"];
	[SSKeychain setPassword:token forService:@"Snippets" account:@"default"];
	[self loadTimelineForToken:token];
}

- (void) openPostingNotification:(NSNotification *)notification
{
	[self promptNewPost:nil];
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

- (void) didChangePreferredContentSize:(NSNotification *)notification
{
	[self refreshTimeline];
}

#pragma mark -

- (void) showURL:(NSURL *)url
{
	BOOL found_microblog_url = NO;
	
	NSString* hostname = [url host];
	NSString* path = [url path];
	if ([hostname isEqualToString:@"micro.blog"]) {
		NSString* username = [path stringByReplacingOccurrencesOfString:@"/" withString:@""];
		if (username.length > 0) {
			found_microblog_url = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:kShowUserProfileNotification object:self userInfo:@{ kShowUserProfileUsernameKey: username }];
		}
	}
	
	if (!found_microblog_url) {
		SFSafariViewController* safari_controller = [[SFSafariViewController alloc] initWithURL:url];
		[self presentViewController:safari_controller animated:YES completion:NULL];
	}
}

#pragma mark -

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
	[self setupPreventHorizontalScrolling];
    
    [self.refreshControl endRefreshing];
}

- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	NSLog (@"Web view error: %@", error);
    [self.refreshControl endRefreshing];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
	CGFloat offset = scrollView.contentOffset.y;
	if ((offset < -130) && !scrollView.isDecelerating) {
		if (!self.refreshControl.isRefreshing) {
			[self refreshTimelineShowingSpinner:YES];
		}
	}
}

@end
