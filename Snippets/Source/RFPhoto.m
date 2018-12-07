//
//  RFPhoto.m
//  Micro.blog
//
//  Created by Manton Reece on 3/22/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFPhoto.h"
#import "UUImage.h"

@implementation RFPhoto

- (id) initWithAsset:(PHAsset *)asset
{
	self = [super init];
	if (self) {
		self.asset = asset;
		self.altText = @"";
	}
	
	return self;
}

- (id) initWithThumbnail:(UIImage *)image
{
	self = [super init];
	if (self) {
        self.thumbnailImage = [RFPhoto sanitizeImage:image];
        
		self.altText = @"";
	}
	
	return self;
}

+ (UIImage*) sanitizeImage:(UIImage*)image
{
    UIImage* sanitizedImage = image;
    if (sanitizedImage.size.width > 1800.0)
    {
        sanitizedImage = [sanitizedImage uuScaleToWidth:1800.0];
    }
    
    sanitizedImage = [sanitizedImage uuRemoveOrientation];
    return sanitizedImage;
}


@end
