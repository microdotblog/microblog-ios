//
//  RFPhoto.h
//  Micro.blog
//
//  Created by Manton Reece on 3/22/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@interface RFPhoto : NSObject

@property (strong) PHAsset* asset;
@property (strong) UIImage* thumbnailImage;

- (id) initWithAsset:(PHAsset *)asset;
- (id) initWithThumbnail:(UIImage *)image;

@end
