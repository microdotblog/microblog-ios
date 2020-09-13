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
#import "RFReaderController.h"
#import "RFClient.h"
#import "RFConstants.h"
#import "RFSettings.h"
#import "RFAccount.h"
#import "UIBarButtonItem+Extras.h"
#import "UIFont+Extras.h"
#import "UIView+Extras.h"
#import "UITraitCollection+Extras.h"
#import "SSKeychain.h"
#import "RFMacros.h"
#import "RFPopupNotificationViewController.h"
#import "RFNYTPhoto.h"

@import SafariServices;
@import NYTPhotoViewer;
@import AVKit;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface RFTimelineController()<NYTPhotosViewControllerDelegate, NYTPhotoViewerDataSource>
	@property (nonatomic, strong) NYTPhotosViewController* photoViewerController;
	@property (nonatomic, strong) RFNYTPhoto* photoToView;
@end

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
	
	self.webView.allowsInlineMediaPlayback = YES;
	self.webView.mediaPlaybackRequiresUserAction = NO;
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
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_backBarButtonWithTarget:self action:@selector(back:)];
	}
	
	if (self.isConversation) {
		UIImage* reply_img;
		if (@available(iOS 13.0, *)) {
			reply_img = [UIImage systemImageNamed:@"arrowshape.turn.up.left"];
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:reply_img style:UIBarButtonItemStylePlain target:self action:@selector(promptNewReply:)];
		}
		else {
			reply_img = [UIImage imageNamed:@"reply_button"];
			self.navigationItem.rightBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"reply_button" target:self action:@selector(promptNewReply:)];
		}
	}
	else if ([self.title isEqualToString:@"Bookmarks"]) {
		if (@available(iOS 13.0, *)) {
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus"] style:UIBarButtonItemStylePlain target:self action:@selector(promptNewBookmark:)];
		}
		else {
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStylePlain target:self action:@selector(promptNewBookmark:)];
		}
	}
	else {
		if (@available(iOS 13.0, *)) {
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.pencil"] style:UIBarButtonItemStylePlain target:self action:@selector(promptNewPost:)];
		}
		else {
			self.navigationItem.rightBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"new_post_button" target:self action:@selector(promptNewPost:)];
		}
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
	NSString* first_js = [NSString stringWithFormat:@"$('.post').first().attr('id').replace('post_', '');"];
	NSString* first_s = [self.webView stringByEvaluatingJavaScriptFromString:first_js];
	return [first_s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSArray *) allPostIDs
{
	NSString* all_js = @"var post_ids = []; $('.post').each(function() { post_ids.push($(this).attr('id').replace('post_', '')); }); post_ids.toString();";
	NSString* all_s = [self.webView stringByEvaluatingJavaScriptFromString:all_js];
	NSArray* post_ids = [all_s componentsSeparatedByString:@","];
	return post_ids;
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

- (NSString *) photoSrcOfPostID:(NSString *)postID
{
	NSString* js = [NSString stringWithFormat:@"$('#post_%@').find('.post_content').find('img').attr('src');", postID];
	NSString* s = [self.webView stringByEvaluatingJavaScriptFromString:js];
	return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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

- (IBAction) promptNewBookmark:(id)sender
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Bookmark" bundle:nil];
	UIViewController* nav_controller = [storyboard instantiateInitialViewController];
	[self presentViewController:nav_controller animated:YES completion:NULL];
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

	RFAccount* a = [RFAccount defaultAccount];
	if (a) {
		NSString* token = [a password];
		if (token) {
			[self loadTimelineForToken:token];
		}
	}
}

- (void) loadTimelineForToken:(NSString *)token
{
	NSDate* now = [NSDate date];
	long timezone_offset = 0 - [[NSTimeZone systemTimeZone] secondsFromGMTForDate:now] / 60;
	int width = self.view.bounds.size.width;
	CGFloat fontsize = [UIFont rf_preferredTimelineFontSize];
	long darkmode = [UITraitCollection rf_isDarkMode];
	
	RFClient* client;
	if (self.endpoint.length == 0) {
		// don't load anything
	}
	else if ([self.endpoint isEqualToString:@"/hybrid/mentions"]) {
		[self loadTimelineAppendingCommonParams];
	}
	else if ([self.endpoint isEqualToString:@"/hybrid/favorites"]) {
		[self loadTimelineAppendingCommonParams];
	}
	else if ([self.endpoint isEqualToString:@"/hybrid/discover"]) {
		[self loadTimelineAppendingCommonParams];
	}
	else if ([self.endpoint containsString:@"/hybrid/conversation"]) {
		[self loadTimelineAppendingCommonParams];
	}
	else if ([self.endpoint containsString:@"/hybrid/posts/"]) {
		[self loadTimelineAppendingCommonParams];
	}
	else if ([self.endpoint containsString:@"/hybrid/discover/search"]) {
		[self loadTimelineAppendingCommonParams];
	}
	else if ([self.endpoint containsString:@"/hybrid/discover/"]) {
		[self loadTimelineAppendingCommonParams];
	}
	else if ([self.endpoint containsString:@"/hybrid/following/"]) {
		[self loadTimelineAppendingCommonParams];
	}
	else if ([self.endpoint containsString:@"/hybrid/users/discover/"]) {
		[self loadTimelineAppendingCommonParams];
	}
	else {
		client = [[RFClient alloc] initWithFormat:@"/hybrid/signin?token=%@&width=%d&fontsize=%f&minutes=%ld&darkmode=%ld", token, width, fontsize, timezone_offset, darkmode];
		[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:client.url]]];
	}
}

- (void) loadTimelineAppendingCommonParams
{
	int width = self.view.bounds.size.width;
	CGFloat fontsize = [UIFont rf_preferredTimelineFontSize];
	long darkmode = [UITraitCollection rf_isDarkMode];

	// if URL already contains ?, don't append it
	NSString* params_separator = @"?";
	if ([self.endpoint containsString:@"?"]) {
		params_separator = @"&";
	}
	
	RFClient* client = [[RFClient alloc] initWithFormat:@"%@%@width=%d&fontsize=%f&darkmode=%ld", self.endpoint, params_separator, width, fontsize, darkmode];
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:client.url]]];
}

- (void) loadTimelineNotification:(NSNotification *)notification
{
	NSString* token = [notification.userInfo objectForKey:@"token"];
	if (token) {
		[RFSettings setSnippetsPassword:token useCurrentUser:YES];
		[self loadTimelineForToken:token];
	}
	else {
		[self refreshTimeline];
	}
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
	NSString* content_size = [UIApplication sharedApplication].preferredContentSizeCategory;
	[RFSettings setPreferredContentSize:content_size];

	[self refreshTimeline];
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
	[super traitCollectionDidChange:previousTraitCollection];

	if (@available(iOS 13.0, *)) {
		BOOL color_changed = [previousTraitCollection hasDifferentColorAppearanceComparedToTraitCollection:self.traitCollection];
		if (color_changed) {
			[self refreshTimeline];
		}
	}
}

#pragma mark -

- (void) showURL:(NSURL *)url
{
	BOOL found_microblog_url = NO;
	
	NSString* hostname = [url host];
	NSString* path = [url path];
	if ([hostname isEqualToString:[RFClient serverHostname]]) {
		NSMutableArray* pieces = [[path componentsSeparatedByString:@"/"] mutableCopy];
		[pieces removeObjectAtIndex:0];
		if ([path containsString:@"/account/"]) {
			// e.g. /account/logs
			found_microblog_url = NO;
		}
		else if ((pieces.count == 2) && [[pieces firstObject] isEqualToString:@"discover"]) {
			// e.g. /discover/books
			found_microblog_url = YES;
			[self showTopicsWithSearch:[pieces lastObject]];
		}
		else if ([[pieces firstObject] isEqualToString:@"about"]) {
			// e.g. /about/api
			found_microblog_url = NO;
		}
		else if ([[pieces firstObject] isEqualToString:@"books"]) {
			// e.g. /books/12345
			found_microblog_url = NO;
		}
		else if ([[pieces firstObject] isEqualToString:@"bookmarks"]) {
			// e.g. /bookmarks/12345
			found_microblog_url = YES;
			[self showReaderWithPath:path];
		}
		else if ([[pieces firstObject] isEqualToString:@"discover"]) {
			// e.g. /discover
			found_microblog_url = NO;
		}
		else if (pieces.count == 2) {
			// e.g. /manton/12345
			found_microblog_url = YES;
			[self showConversationWithPostID:[pieces lastObject]];
		}
		else {
			NSString* username = [path stringByReplacingOccurrencesOfString:@"/" withString:@""];
			if (username.length > 0) {
				// e.g. /manton
				found_microblog_url = YES;
				[self showProfileWithUsername:username];
			}
		}
	}
	
	if (!found_microblog_url) {
		SFSafariViewController* safari_controller = [[SFSafariViewController alloc] initWithURL:url];
		[self presentViewController:safari_controller animated:YES completion:NULL];
	}
}

- (void) showTopicsWithSearch:(NSString *)term
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowTopicNotification object:self userInfo:@{ kShowTopicKey: term }];
}

- (void) showProfileWithUsername:(NSString *)username
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowUserProfileNotification object:self userInfo:@{ kShowUserProfileUsernameKey: username }];
}

- (void) showConversationWithPostID:(NSString *)postID
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowConversationNotification object:self userInfo:@{ kShowConversationPostIDKey: postID }];
}

- (void) showReaderWithPath:(NSString *)path
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Bookmark" bundle:nil];
	RFReaderController* reader_controller = [storyboard instantiateViewControllerWithIdentifier:@"Reader"];
	reader_controller.path = path;
	[self.navigationController pushViewController:reader_controller animated:YES];
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
	CGFloat threshold = [self.view rf_statusBarHeight] + 110;
	if ((offset < -threshold) && !scrollView.isDecelerating) {
		if (!self.refreshControl.isRefreshing) {
			[self refreshTimelineShowingSpinner:YES];
		}
	}
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NYTPhotosViewControllerDelegate
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//- (UIView * _Nullable)photosViewController:(NYTPhotosViewController *)photosViewController captionViewForPhoto:(id <NYTPhoto>)photo
//{
	//if (!self.captionViewController)
	//{
	//	self.captionViewController = [SLPhotoViewerCaptionViewController new];
	//}

	//self.captionViewController.photoViewController = photosViewController;

	//[self.captionViewController setPhotoInfo:self.dictionary];
	
	//return self.captionViewController.view;
//}

- (NSNumber*) numberOfPhotos
{
	return @(0);
}

- (NSInteger)indexOfPhoto:(id <NYTPhoto>)photo
{
	return 0;
}

- (nullable id <NYTPhoto>)photoAtIndex:(NSInteger)photoIndex
{
	return self.photoToView;
}

- (UIView * _Nullable)photosViewController:(NYTPhotosViewController *)photosViewController loadingViewForPhoto:(id <NYTPhoto>)photo
{
	UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	[activityIndicator startAnimating];
	
	return activityIndicator;
}

- (void) openImageViewer:(NSString*)url
{
	self.photoToView = [[RFNYTPhoto alloc] init];
	self.photoToView.image = nil;

	self.photoViewerController = [[NYTPhotosViewController alloc] initWithDataSource:self initialPhoto:self.photoToView delegate:self];
	self.photoViewerController.rightBarButtonItems = @[];
	
	[self presentViewController:self.photoViewerController animated:YES completion:^
	{
	}];


	[UUHttpSession get:url queryArguments:nil completionHandler:^(UUHttpResponse *response) {
		UIImage* image = response.parsedResponse;
		if (image && [image isKindOfClass:[UIImage class]])
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				self.photoToView.image = image;
				[self.photoViewerController updatePhoto:self.photoToView];
				self.photoViewerController.pageViewController.dataSource = nil;
			});
		}
	}];
}

- (void) openVideoViewer:(NSString*)url
{
	AVPlayer* player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:url]];
	AVPlayerViewController* viewController = [[AVPlayerViewController alloc] init];
	viewController.player = player;
	
	[self presentViewController:viewController animated:YES completion:^
	 {
	 }];
	
}

@end


