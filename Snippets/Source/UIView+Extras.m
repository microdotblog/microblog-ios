//
//  UIView+Extras.m
//  Micro.blog
//
//  Created by Manton Reece on 12/2/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "UIView+Extras.h"

#import "RFSettings.h"
#import "RFMacros.h"

@implementation UIView (Extras)

- (CGFloat) rf_statusBarHeight
{
	CGFloat result;

//	if (@available(iOS 11, *)) {
//		result = self.safeAreaInsets.top;
//		[RFSettings setLastStatusBarHeight:result];
//		return result;
//	}
	
	UIWindow* win = self.window;
	
	if (win == nil) {
		result = [RFSettings lastStatusBarHeight];
		if (result == 0.0) {
			result = RFStatusBarHeightOld();
		}
	}
	else if (@available(iOS 11.0, *)) {
		result = win.safeAreaInsets.top;
		[RFSettings setLastStatusBarHeight:result];
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

- (CGFloat) rf_bottomSafeArea
{
	CGFloat result = 0;
	
	UIWindow* win = self.window;
	
#ifndef SHARING_EXTENSION
	if (win == nil) {
		win = [[[UIApplication sharedApplication] windows] firstObject];
	}
#endif

	if (@available(iOS 11.0, *)) {
		result = win.safeAreaInsets.bottom;
	}
	
	return result;
}

@end
