//
//  RFDraftOrPublishCell.h
//  Micro.blog
//
//  Created by Manton Reece on 4/18/21.
//  Copyright © 2021 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFDraftOrPublishCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* nameField;
@property (strong, nonatomic) IBOutlet UIImageView* checkmarkView;

@end

NS_ASSUME_NONNULL_END
