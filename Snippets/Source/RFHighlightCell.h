//
//  RFHighlightCell.h
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFHighlightCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* selectionField;
@property (strong, nonatomic) IBOutlet UILabel* titleField;

@end

NS_ASSUME_NONNULL_END
