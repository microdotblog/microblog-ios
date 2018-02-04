//
//  RFFeedCell.m
//  Micro.blog
//
//  Created by Manton Reece on 2/2/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFFeedCell.h"

@implementation RFFeedCell

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	
	self.checkmarkView.hidden = !selected;
}

@end
