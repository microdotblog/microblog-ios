//
//  RFMenuCell.m
//  Micro.blog
//
//  Created by Manton Reece on 8/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFMenuCell.h"

@implementation RFMenuCell

- (void) awakeFromNib
{
	[super awakeFromNib];

	[self setupSelectionBackground];
}

- (void) setupWithTitle:(NSString *)title icon:(NSString *)iconName
{
	self.titleField.text = title;
	
	if (@available(iOS 13.0, *)) {
		self.leftConstraint.constant = 40;
		self.iconView.image = [UIImage systemImageNamed:iconName];
	}
	else {
		self.leftConstraint.constant = 12;
	}
}

- (void) setupSelectionBackground
{
	UIView* selected_view = [[UIView alloc] initWithFrame:self.bounds];
	selected_view.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.1];
	self.selectedBackgroundView = selected_view;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
}

@end
