//
//  UITraitCollection+Extras.m
//  Micro.blog
//
//  Created by Manton Reece on 8/8/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import "UITraitCollection+Extras.h"

@implementation UITraitCollection (Extras)

+ (BOOL) rf_isDarkMode
{
	BOOL darkmode = NO;

	if (@available(iOS 13.0, *)) {
		darkmode = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
	}
	
	return darkmode;
}

@end
