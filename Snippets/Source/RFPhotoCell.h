//
//  RFPhotoCell.h
//  Micro.blog
//
//  Created by Manton Reece on 3/22/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@class RFPhoto;

@interface RFPhotoCell : UICollectionViewCell

@property (strong, nonnull) IBOutlet UIImageView* thumbnailView;
@property (strong, nonnull) IBOutlet UILabel* videoDurationLabel;

@property (strong, nonnull) RFPhoto* photo;

- (void) setupWithPhoto:(RFPhoto *_Nonnull)photo;

@end
