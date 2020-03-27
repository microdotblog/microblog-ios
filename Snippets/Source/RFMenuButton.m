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
	if (@available(iOS 11, *)) {
		if (self.isHighlighted) {
			self.backgroundColor = [UIColor colorNamed:@"color_menu_button_highlighted"];
		}
		else if (self.isSelected) {
			self.backgroundColor = [UIColor colorNamed:@"color_menu_button_selected"];
		}
		else {
			self.backgroundColor = [UIColor clearColor];
		}
	}
	else {
		self.backgroundColor = [UIColor clearColor];
	}
}

@end
