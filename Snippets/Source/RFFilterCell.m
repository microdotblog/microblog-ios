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
	[manager requestImageForAsset:photo.asset targetSize:CGSizeMake (200, 200) contentMode:PHImageContentModeAspectFill options:0 resultHandler:^(UIImage* result, NSDictionary* info) {
		self.nameField.text = filter.name;
		if (filter.ciFilter.length > 0) {
			self.previewImageView.image = [filter filterImage:result];
		}
		else {
			self.previewImageView.image = result;
		}
	}];
}

@end
