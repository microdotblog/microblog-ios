//
//  RFReaderController.h
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFReaderController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView* webView;

@property (strong, nonatomic) NSString* path; // e.g. /bookmarks/123

@end

NS_ASSUME_NONNULL_END
