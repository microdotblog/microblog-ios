//
//  RFFilterCell.h
//  Micro.blog
//
//  Created by Manton Reece on 3/26/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RFPhoto;
@class RFFilter;

@interface RFFilterCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel* nameField;
@property (strong, nonatomic) IBOutlet UIImageView* previewImageView;

@property (strong, nonatomic) RFPhoto* photo;
@property (strong, nonatomic) RFFilter* filter;

- (void) setupWithPhoto:(RFPhoto *)photo applyingFilter:(RFFilter *)filter;

@end
