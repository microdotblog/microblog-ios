//
//  RFTimelineController.m
//  Snippets
//
//  Created by Manton Reece on 6/4/15.
//  Copyright (c) 2015 Riverfold Software. All rights reserved.
//

#import "RFTimelineController.h"

@implementation RFTimelineController

- (instancetype) init
{
	self = [super initWithNibName:@"Timeline" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Timeline";
}

@end
