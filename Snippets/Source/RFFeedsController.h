//
//  RFFeedsController.h
//  Micro.blog
//
//  Created by Manton Reece on 2/2/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFFeedsController : RFViewController

@property (strong, nonatomic) IBOutlet UITableView* categoriesTable;
@property (strong, nonatomic) IBOutlet UITableView* feedsTable;

@property (strong, nonatomic) NSArray* categories; // NSString
@property (strong, nonatomic) NSSet* selectedCategories; // NSString
@property (strong, nonatomic) NSArray* feeds; // NSDictionary

- (id) initWithSelectedCategories:(NSSet *)selectedCategories;

@end
