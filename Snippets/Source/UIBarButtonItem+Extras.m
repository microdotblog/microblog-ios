//
//  UIBarButtonItem+Extras.m
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "UIBarButtonItem+Extras.h"

@implementation UIBarButtonItem (Extras)

+ (UIBarButtonItem *) rf_barButtonWithImageNamed:(NSString *)imageName target:(id)target action:(SEL)action
{
	UIImage* img = [UIImage imageNamed:imageName];
	CGFloat extra_tapping_space = 8;
	CGFloat w = img.size.width + extra_tapping_space;
	UIImageView* v = [[UIImageView alloc] initWithFrame:CGRectMake (0, 0, w, img.size.height)];
	v.image = img;
	v.isAccessibilityElement = YES;
	v.accessibilityLabel = [imageName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
	v.contentMode = UIViewContentModeCenter;
	
	UIGestureRecognizer* gesture = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
	[v addGestureRecognizer:gesture];
	
	UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithCustomView:v];
	return item;
}

- (UIImage *) rf_customImage
{
	UIImageView* v = self.customView;
	return v.image;
}

- (void) rf_setCustomImage:(UIImage *)img
{
	UIImageView* v = self.customView;
	v.image = img;
}

@end
