//
//  RFMenuController.m
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFMenuController.h"

#import "RFTimelineController.h"

@implementation RFMenuController

- (instancetype) init
{
	self = [super initWithNibName:@"Menu" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Menu";
}

- (IBAction) showTimeline:(id)sender
{
	RFTimelineController* timeline_controller = [[RFTimelineController alloc] init];
	[self.navigationController pushViewController:timeline_controller animated:YES];
}

- (IBAction) showReplies:(id)sender
{
}

@end
