//
//  AllRepliesController.h
//  Micro.blog
//
//  Created by Manton Reece on 4/22/21.
//  Copyright © 2021 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RFPost;

@interface RFAllRepliesController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;
@property (strong, nonatomic) IBOutlet UILabel* headerField;
@property (strong, nonatomic) IBOutlet UITableView* tableView;

@property (strong, nonatomic) NSArray* allPosts; // RFPost
@property (strong, nonatomic) RFPost* selectedPost;

@end

NS_ASSUME_NONNULL_END
