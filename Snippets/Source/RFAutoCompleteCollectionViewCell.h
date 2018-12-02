//
//  RFAutoCompleteCollectionViewCell.h
//  Micro.blog
//
//  Created by Jonathan Hays on 12/1/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFAutoCompleteCollectionViewCell : UICollectionViewCell

@property(nonatomic, strong) IBOutlet UIImageView* userImageView;
@property(nonatomic, strong) IBOutlet UILabel* userNameLabel;

@end

NS_ASSUME_NONNULL_END
