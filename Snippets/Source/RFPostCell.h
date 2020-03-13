//
//  RFPostCell.h
//  Micro.blog
//
//  Created by Manton Reece on 3/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RFPost;

@interface RFPostCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* titleField;
@property (strong, nonatomic) IBOutlet UILabel* textField;
@property (strong, nonatomic) IBOutlet UILabel* dateField;
@property (strong, nonatomic) IBOutlet UILabel* draftField;
@property (strong, nonatomic) IBOutlet UICollectionView* photosCollectionView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* textTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* dateTopConstraint;

@property (strong, nonatomic) NSArray* photos; // RFPhoto

- (void) setupWithPost:(RFPost *)post;

@end

NS_ASSUME_NONNULL_END
