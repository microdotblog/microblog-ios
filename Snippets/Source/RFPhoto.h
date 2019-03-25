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

static NSString* const kAttachVideoNotification = @"RFAttachVideoNotification";
static NSString* const kAttachPhotoNotification = @"RFAttachPhotoNotification";
static NSString* const kAttachPhotoKey = @"photo";
static NSString* const kAttachVideoKey = @"video";
static NSString* const kAttachVideoThumbnailKey = @"thumbnail";

@interface RFPhoto : NSObject

@property (strong) PHAsset* asset;
@property (strong) UIImage* thumbnailImage;
@property (strong) NSString* publishedURL;
@property (strong) NSString* altText;
@property (strong) NSURL* videoURL;

- (id) initWithAsset:(PHAsset *)asset;
- (id) initWithThumbnail:(UIImage *)image;
- (id) initWithVideo:(NSURL*)url thumbnail:(UIImage*)thumbnail;

+ (UIImage*) sanitizeImage:(UIImage*)image;
	
- (void) generateVideoThumbnail:(void(^)(UIImage* thumbnail))completionBlock;
- (void) generateVideoURL:(void(^)(NSURL* url))completionBlock;

@end
