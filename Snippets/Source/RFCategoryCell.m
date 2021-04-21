//
//  RFCategoryCell.m
//  Micro.blog
//
//  Created by Manton Reece on 2/4/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import "RFCategoryCell.h"

@implementation RFCategoryCell

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];

	self.checkmarkView.hidden = !selected;

	if (selected) {
		self.nameField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
	}
	else {
		self.nameField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
	}
}

@end
