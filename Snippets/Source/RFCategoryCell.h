//
//  RFCategoryCell.h
//  Micro.blog
//
//  Created by Manton Reece on 2/4/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFCategoryCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* nameField;
@property (strong, nonatomic) IBOutlet UIImageView* checkmarkView;

@end

NS_ASSUME_NONNULL_END
