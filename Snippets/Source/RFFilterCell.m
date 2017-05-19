//
//  RFFilterCell.m
//  Micro.blog
//
//  Created by Manton Reece on 3/26/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFFilterCell.h"

#import "RFPhoto.h"
#import "RFFilter.h"

@implementation RFFilterCell

- (void) setupWithPhoto:(RFPhoto *)photo applyingFilter:(RFFilter *)filter
{
	self.photo = photo;
	self.filter = filter;

	PHImageManager* manager = [PHImageManager defaultManager];
	PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
	options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
	[manager requestImageForAsset:photo.asset targetSize:CGSizeMake (200, 200) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage* result, NSDictionary* info) {
		self.nameField.text = filter.name;
		if (filter.ciFilter) {
			self.previewImageView.image = [filter filterImage:result];
		}
		else {
			self.previewImageView.image = result;
		}
	}];
}

@end
