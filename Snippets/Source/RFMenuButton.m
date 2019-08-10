//
//  RFMenuButton.m
//  Micro.blog
//
//  Created by Manton Reece on 4/28/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFMenuButton.h"

#import "UITraitCollection+Extras.h"

@implementation RFMenuButton

- (void) setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];

	if (highlighted) {
		if ([UITraitCollection rf_isDarkMode]) {
			self.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
		}
		else {
			self.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
		}
	}
	else {
		self.backgroundColor = [UIColor clearColor];
	}
}

@end
