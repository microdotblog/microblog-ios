//
//  UIFont+Extras.m
//  Micro.blog
//
//  Created by Manton Reece on 7/5/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "UIFont+Extras.h"

@implementation UIFont (Extras)

+ (CGFloat) rf_preferredTimelineFontSize
{
    NSString* content_size = @"";//[UIApplication sharedApplication].preferredContentSizeCategory;

	NSDictionary* body_sizes = @{
		UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @21,
		UIContentSizeCategoryAccessibilityExtraExtraLarge: @20,
		UIContentSizeCategoryAccessibilityExtraLarge: @19,
		UIContentSizeCategoryAccessibilityLarge: @19,
		UIContentSizeCategoryAccessibilityMedium: @18,
		UIContentSizeCategoryExtraExtraExtraLarge: @18,
		UIContentSizeCategoryExtraExtraLarge: @17,
		UIContentSizeCategoryExtraLarge: @16,
		UIContentSizeCategoryLarge: @15,
		UIContentSizeCategoryMedium: @14,
		UIContentSizeCategorySmall: @13,
		UIContentSizeCategoryExtraSmall: @12
	};
	
	CGFloat result = [[body_sizes objectForKey:content_size] floatValue];
	if (result == 0.0) {
		result = 15.0;
	}
	
	return result;
}

+ (CGFloat) rf_preferredPostingFontSize
{
	CGFloat scale = 1.1;
	CGFloat fontsize = [self rf_preferredTimelineFontSize] * scale;
	return fontsize;
}

@end
