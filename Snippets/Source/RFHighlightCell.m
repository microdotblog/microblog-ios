//
//  RFHighlightCell.m
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFHighlightCell.h"

@implementation RFHighlightCell

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[self setupSelectionBackground];
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
