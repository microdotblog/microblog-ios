//
//  RFDraftOrPublishCell.m
//  Micro.blog
//
//  Created by Manton Reece on 4/18/21.
//  Copyright © 2021 Riverfold Software. All rights reserved.
//

#import "RFDraftOrPublishCell.h"

@implementation RFDraftOrPublishCell

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];

	self.checkmarkView.hidden = !selected;
}

@end
