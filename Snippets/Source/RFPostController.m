//
//  RFPostController.m
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFPostController.h"

@implementation RFPostController

- (instancetype) init
{
	self = [super initWithNibName:@"Post" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"New Post";
}

@end
