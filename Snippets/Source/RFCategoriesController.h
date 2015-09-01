//
//  RFCategoriesController.h
//  Snippets
//
//  Created by Manton Reece on 8/31/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFCategoriesController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView* formatsTableView;
@property (strong, nonatomic) IBOutlet UITableView* categoriesTableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;

@property (strong, nonatomic) NSArray* formatValues; // NSString
@property (strong, nonatomic) NSArray* categoryValues; // NSString
@property (strong, nonatomic) NSArray* categoryIDs; // NSNumber
@property (strong, nonatomic) NSString* selectedFormat;
@property (strong, nonatomic) NSString* selectedCategory;

@end
