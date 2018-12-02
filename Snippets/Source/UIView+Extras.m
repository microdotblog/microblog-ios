//
//  UIView+Extras.m
//  Micro.blog
//
//  Created by Manton Reece on 12/2/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "UIView+Extras.h"

#import "RFMacros.h"

static NSString* const kLastStatusBarHeightPrefKey = @"LastStatusBarHeight";

@implementation UIView (Extras)

- (CGFloat) rf_statusBarHeight
{
	CGFloat result;
	UIWindow* win = self.window;
	
	if (win == nil) {
		result = [[NSUserDefaults standardUserDefaults] floatForKey:kLastStatusBarHeightPrefKey];
		if (result == 0.0) {
			result = RFStatusBarHeightOld();
		}
	}
	else if ([win respondsToSelector:@selector(safeAreaInsets)]) {
		result = win.safeAreaInsets.top;
		[[NSUserDefaults standardUserDefaults] setFloat:result forKey:kLastStatusBarHeightPrefKey];
	}
	else {
		result = RFStatusBarHeightOld();
	}
	
	return result;
}

- (CGFloat) rf_statusBarAndNavigationHeight
{
	return [self rf_statusBarHeight] + 44.0;
}

@end
