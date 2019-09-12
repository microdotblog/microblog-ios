//
//  RFShareController.m
//  Micro.blog Sharing
//
//  Created by Manton Reece on 9/11/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import "RFShareController.h"

#import "RFPostController.h"

@implementation RFShareController

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	RFPostController* post_controller = [[RFPostController alloc] init];
	[self pushViewController:post_controller animated:NO];
}

@end
