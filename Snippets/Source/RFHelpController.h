//
//  RFHelpController.h
//  Snippets
//
//  Created by Manton Reece on 8/21/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFHelpController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView* webView;

@property (strong, nonatomic) NSURL* url;

@end
