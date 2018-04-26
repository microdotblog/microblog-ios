//
//  RFExternalController.h
//  Micro.blog
//
//  Created by Manton Reece on 2/27/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFExternalController : RFViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField* websiteField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;

@end
