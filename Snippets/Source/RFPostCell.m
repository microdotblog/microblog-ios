//
//  RFPostCell.m
//  Micro.blog
//
//  Created by Manton Reece on 3/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFPostCell.h"

#import "RFPost.h"
#import "UUDate.h"

@implementation RFPostCell

- (void) awakeFromNib
{
	[super awakeFromNib];
}

- (void) setupWithPost:(RFPost *)post
{
	self.titleField.text = post.title;
	self.textField.text = [post summary];
	self.dateField.text = [post.postedAt uuIso8601DateString];
	self.draftField.hidden = !post.isDraft;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
}

@end
