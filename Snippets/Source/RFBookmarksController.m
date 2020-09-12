//
//  RFBookmarksController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFBookmarksController.h"

#import "RFHighlightsController.h"

@implementation RFBookmarksController

- (instancetype) initWithEndpoint:(NSString *)endpoint title:(NSString *)title
{
	self = [super initWithNibName:@"Bookmarks" endPoint:endpoint title:title];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
}

- (IBAction) showHighlights:(id)sender
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Bookmark" bundle:nil];
	RFHighlightsController* controller = [storyboard instantiateViewControllerWithIdentifier:@"Highlights"];
	[self.navigationController pushViewController:controller animated:YES];
}

@end
