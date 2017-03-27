//
//  RFFilter.m
//  Micro.blog
//
//  Created by Manton Reece on 3/26/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFFilter.h"

@implementation RFFilter

- (UIImage *) filterImage:(UIImage *)image
{
	CIImage* cg_image = [CIImage imageWithCGImage:image.CGImage];
	CIFilter* filter = [CIFilter filterWithName:self.ciFilter keysAndValues:@"inputImage", cg_image, nil];
	CIImage* filtered_image = [filter outputImage];
	UIImage* img = [UIImage imageWithCIImage:filtered_image];
	return img;
}

@end
