//
//  RFHighlightsController.h
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RFHighlight;

@interface RFHighlightsController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView* tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;

@property (strong, nonatomic) NSArray* highlights; // RFHighlight
@property (strong, nonatomic) RFHighlight* selectedHighlight;

@end

NS_ASSUME_NONNULL_END
