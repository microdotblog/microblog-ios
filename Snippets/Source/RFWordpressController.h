//
//  RFWordpressController.h
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFWordpressController : RFViewController <UIScrollViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField* usernameField;
@property (strong, nonatomic) IBOutlet UITextField* passwordField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;
@property (strong, nonatomic) IBOutlet UIButton* onePasswordButton;

@property (strong, nonatomic) NSString* websiteURL;
@property (strong, nonatomic) NSString* rsdURL;

- (instancetype) initWithWebsite:(NSString *)websiteURL rsdURL:(NSString *)rsdURL;

@end
