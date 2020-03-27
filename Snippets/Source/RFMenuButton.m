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

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[self setImage:nil forState:UIControlStateHighlighted];
	[self setImage:nil forState:UIControlStateSelected];
}

- (void) setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];

	[self updateStateBackground];
}

- (void) setSelected:(BOOL)selected
{
	[super setSelected:selected];

	[self updateStateBackground];
}

- (void) updateStateBackground
{
	if (self.isHighlighted || self.isSelected) {
		if ([UITraitCollection rf_isDarkMode]) {
			self.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
		}
		else {
			self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		}
	}
	else {
		self.backgroundColor = [UIColor clearColor];
	}
}

@end
