//
//  RFMenuController.h
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RFViewController.h"

@interface RFMenuController : RFViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UILabel* fullNameField;
@property (strong, nonatomic) IBOutlet UILabel* usernameField;
@property (strong, nonatomic) IBOutlet UIImageView* profileImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* bottomConstraint;
@property (strong, nonatomic) IBOutlet UITableView* tableView;

@property (strong, nonatomic) NSMutableArray* menuItems;

@end
