//
//  RFSettingChoiceCell.m
//  Snippets
//
//  Created by Manton Reece on 8/31/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFSettingChoiceCell.h"

@implementation RFSettingChoiceCell

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	
	self.checkmarkField.hidden = !selected;
}

@end
