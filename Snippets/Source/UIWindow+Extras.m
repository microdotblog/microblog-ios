//
//  UIWindow+Extras.m
//  Micro.blog
//
//  Created by Manton Reece on 12/2/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "UIWindow+Extras.h"

#import "RFMacros.h"

@implementation UIWindow (Extras)

- (CGFloat) rf_statusBarHeight
{
	CGFloat result;
	
	if ([self respondsToSelector:@selector(safeAreaInsets)]) {
		return self.safeAreaInsets.top;
	}
	else {
		return RFStatusBarHeightOld();
	}
	
	return result;
}

- (CGFloat) rf_statusBarAndNavigationHeight
{
	return [self rf_statusBarHeight] + 44.0;
}

@end
