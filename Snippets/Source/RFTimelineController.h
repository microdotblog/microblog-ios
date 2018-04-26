//
//  RFTimelineController.h
//  Snippets
//
//  Created by Manton Reece on 6/4/15.
//  Copyright (c) 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RFOptionsController.h"
#import "RFViewController.h"

@interface RFTimelineController : RFViewController <UIWebViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView* webView;

@property (strong, nonatomic) UIRefreshControl* refreshControl;
@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) NSString* timelineTitle;
@property (strong, nonatomic) UIViewController* menuController;
@property (assign, nonatomic) CGFloat lastRefreshWidth;
@property (assign, nonatomic) BOOL isConversation;

- (instancetype) initWithEndpoint:(NSString *)endpoint title:(NSString *)title;
- (instancetype) initWithNibName:(NSString *)nibNameOrNil endPoint:(NSString*)endpoint title:(NSString*)title;

- (void) setupNavigation;

- (void) setSelected:(BOOL)isSelected withPostID:(NSString *)postID;
- (NSArray *) allPostIDs; // NSString
- (CGRect) rectOfPostID:(NSString *)postID;
- (RFOptionsPopoverType) popoverTypeOfPostID:(NSString *)postID;
- (NSString *) usernameOfPostID:(NSString *)postID;
- (NSString *) linkOfPostID:(NSString *)postID;

- (IBAction) promptNewPost:(id)sender;
- (void) refreshTimeline;
- (void) refreshTimelineShowingSpinner:(BOOL)showSpinner;

@end
