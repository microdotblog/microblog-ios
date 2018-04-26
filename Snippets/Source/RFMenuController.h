//
//  RFMenuController.h
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RFViewController.h"

@interface RFMenuController : RFViewController

@property (strong, nonatomic) IBOutlet UILabel* fullNameField;
@property (strong, nonatomic) IBOutlet UILabel* usernameField;
@property (strong, nonatomic) IBOutlet UIImageView* profileImageView;
@property (strong, nonatomic) IBOutlet UILabel* discoverField;
@property (strong, nonatomic) IBOutlet UIButton* discoverButton;
@property (strong, nonatomic) IBOutlet UIView* discoverLine;

@property (strong, nonatomic) IBOutlet UIView* switchAccountLine;
@property (strong, nonatomic) IBOutlet UIButton* switchAccountButton;
@property (strong, nonatomic) IBOutlet UILabel* switchAccountLabel;

@end
