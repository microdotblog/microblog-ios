//
//  RFAccountCell.h
//  Micro.blog
//
//  Created by Manton Reece on 9/5/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RFAccount;

@interface RFAccountCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView* profileImageView;
@property (strong, nonatomic) IBOutlet UILabel* plusField;
@property (strong, nonatomic) IBOutlet UILabel* usernameField;

- (void) setupWithAccount:(RFAccount *)account;
- (void) setupForNewButton;

@end

NS_ASSUME_NONNULL_END
