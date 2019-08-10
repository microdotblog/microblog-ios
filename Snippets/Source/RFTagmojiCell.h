//
//  RFTagmojiCell.h
//  Micro.blog
//
//  Created by Manton Reece on 8/9/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFTagmojiCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel* emojiField;
@property (strong, nonatomic) IBOutlet UILabel* titleField;

@end

NS_ASSUME_NONNULL_END
