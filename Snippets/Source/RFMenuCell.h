//
//  RFMenuCell.h
//  Micro.blog
//
//  Created by Manton Reece on 8/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFMenuCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView* iconView;
@property (strong, nonatomic) IBOutlet UILabel* titleField;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* leftConstraint;

- (void) setupWithTitle:(NSString *)title icon:(NSString *)iconName;

@end

NS_ASSUME_NONNULL_END
