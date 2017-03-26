//
//  RFFilterCell.m
//  Micro.blog
//
//  Created by Manton Reece on 3/26/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFFilterCell.h"

#import "RFPhoto.h"
#import "RFFilter.h"

@implementation RFFilterCell

- (void) setupWithPhoto:(RFPhoto *)photo applyingFilter:(RFFilter *)filter
{
	self.photo = photo;
	self.filter = filter;
	
	self.nameField.text = filter.name;
}

@end
