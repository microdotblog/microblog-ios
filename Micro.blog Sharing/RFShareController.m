//
//  RFShareController.m
//  Micro.blog Sharing
//
//  Created by Manton Reece on 9/11/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import "RFShareController.h"

#import "RFPostController.h"
#import "RFSettings.h"
#import "RFBookmarkController.h"

@implementation RFShareController

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	if ([RFSettings prefersBookmarkSharedURLs]) {
		UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Bookmark" bundle:nil];
		RFBookmarkController* bookmark_controller = [storyboard instantiateViewControllerWithIdentifier:@"NewBookmark"];
		[self pushViewController:bookmark_controller animated:NO];
	}
	else {
		RFPostController* post_controller = [[RFPostController alloc] init];
		[self pushViewController:post_controller animated:NO];
	}
}

@end
