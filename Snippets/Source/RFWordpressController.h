//
//  RFWordpressController.h
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFWordpressController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView* scrollView;
@property (strong, nonatomic) IBOutlet UIView* containerView;
@property (strong, nonatomic) IBOutlet UITextField* websiteField;
@property (strong, nonatomic) IBOutlet UITextField* usernameField;
@property (strong, nonatomic) IBOutlet UITextField* passwordField;

@end
