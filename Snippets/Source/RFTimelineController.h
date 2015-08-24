//
//  RFTimelineController.h
//  Snippets
//
//  Created by Manton Reece on 6/4/15.
//  Copyright (c) 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFTimelineController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView* webView;

@property (strong, nonatomic) UIRefreshControl* refreshControl;
@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) NSString* timelineTitle;

- (instancetype) initWithEndpoint:(NSString *)endpoint title:(NSString *)title;

@end
