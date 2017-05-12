//
//  RFSettingsController.h
//  Snippets
//
//  Created by Manton Reece on 9/1/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFSettingsController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView* serversTableView;
@property (strong, nonatomic) IBOutlet UILabel* categoriesIntroField;
@property (strong, nonatomic) IBOutlet UITableView* categoriesTableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* categoriesProgressSpinner;

@property (strong, nonatomic) NSArray* serverNames; // NSString
@property (strong, nonatomic) NSArray* categoryValues; // NSString
@property (strong, nonatomic) NSArray* categoryIDs; // NSNumber
@property (strong, nonatomic) NSString* selectedCategory;

@end
