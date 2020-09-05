//
//  RFBookmarkController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/5/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFBookmarkController.h"

#import "RFClient.h"
#import "UIBarButtonItem+Extras.h"

@implementation RFBookmarkController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.urlField becomeFirstResponder];
}

- (void) setupNavigation
{
	self.title = @"";
	
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"close_button" target:self action:@selector(cancel:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save Bookmark" style:UIBarButtonItemStylePlain target:self action:@selector(saveBookmark:)];
}

- (IBAction) saveBookmark:(id)sender
{
	[self.progressSpinner startAnimating];
	
	// save bookmark
	// ...
	
	[self dismissViewControllerAnimated:YES completion:^{
		// notify bookmarks to update
		// ...
	}];
}

- (IBAction) cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end
