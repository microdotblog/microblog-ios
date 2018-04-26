//
//  RFFeedsController.h
//  Micro.blog
//
//  Created by Manton Reece on 2/2/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFFeedsController : RFViewController

@property (strong, nonatomic) IBOutlet UITableView* feedsTable;

@property (strong, nonatomic) NSArray* feeds; // NSDictionary

@end
