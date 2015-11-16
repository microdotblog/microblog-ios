//
//  RFUserController.m
//  Snippets
//
//  Created by Manton Reece on 11/15/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFUserController.h"

@implementation RFUserController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
}

- (void) setupNavigation
{
	[super setupNavigation];

	self.title = self.timelineTitle;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Unfollow" style:UIBarButtonItemStylePlain target:self action:@selector(unfollow:)];
}

- (void) unfollow:(id)sender
{
}

@end
