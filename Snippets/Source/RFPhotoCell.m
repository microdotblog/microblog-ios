//
//  RFPhotoCell.m
//  Micro.blog
//
//  Created by Manton Reece on 3/22/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFPhotoCell.h"

#import "RFPhoto.h"
#import "RFMacros.h"

@implementation RFPhotoCell

- (void) setupWithPhoto:(RFPhoto *)photo
{
	self.photo = photo;
	self.videoDurationLabel.hidden = YES;
	self.videoDurationLabel.layer.cornerRadius = 8.0;
	self.videoDurationLabel.clipsToBounds = YES;
	
	if (photo.asset)
	{
		if (photo.asset.mediaType == PHAssetMediaTypeVideo)
		{
			self.videoDurationLabel.hidden = NO;
			NSTimeInterval duration = photo.asset.duration;
			int minutes = duration / 60;
			int seconds = ((int)duration) % 60;
			NSString* durationString = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
			self.videoDurationLabel.text = durationString;
		}
	}
	
	if (photo.thumbnailImage) {
		self.thumbnailView.image = photo.thumbnailImage;
	}
	else {
		PHImageManager* manager = [PHImageManager defaultManager];
		PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
		options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
		[manager requestImageForAsset:photo.asset targetSize:CGSizeMake (150, 150) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage* result, NSDictionary* info) {
			self.thumbnailView.image = result;
		}];
	}
}

@end
