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
	UIImageView* v = [[UIImageView alloc] initWithFrame:CGRectMake (0, 0, img.size.width, img.size.height)];
	v.image = img;
	
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
