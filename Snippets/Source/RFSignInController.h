//
//  RFSignInController.h
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFSignInController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField* tokenField;
@property (strong, nonatomic) IBOutlet UILabel* instructionsField;
@property (strong, nonatomic) IBOutlet UILabel* messageField;
@property (strong, nonatomic) IBOutlet UIView* messageContainer;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* messageTopConstraint;

- (void) updateToken:(NSString *)appToken;

@end
