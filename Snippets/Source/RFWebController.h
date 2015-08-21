//
//  RFWebController.h
//  Snippets
//
//  Created by Manton Reece on 8/21/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFWebController : UIViewController

@property (strong, nonatomic) IBOutlet UIWebView* webView;

@property (strong, nonatomic) NSURL* url;

- (instancetype) initWithURL:(NSURL *)url;

@end
