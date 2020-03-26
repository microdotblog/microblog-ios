//
//  RFSelectBlogViewController.h
//  Micro.blog
//
//  Created by Jonathan Hays on 4/26/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPostToBlogSelectedNotification @"kPostToBlogSelectedNotification"

@interface RFSelectBlogViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITableView* tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;

@property (strong, nonatomic) NSArray* blogs; // NSDictionary (uid, name)
@property (assign, nonatomic) BOOL isCancelable;

@end
