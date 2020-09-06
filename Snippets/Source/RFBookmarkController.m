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
#import "RFConstants.h"
#import "RFMacros.h"

@implementation RFBookmarkController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupClipboard];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
		
	[self.urlField becomeFirstResponder];
}

- (void) setupNavigation
{
	self.title = @"";
	
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_closeBarButtonWithTarget:self action:@selector(cancel:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save Bookmark" style:UIBarButtonItemStylePlain target:self action:@selector(saveBookmark:)];
}

- (void) setupClipboard
{
	NSString* url = [UIPasteboard generalPasteboard].string;
	if (url && [url containsString:@"http"]) {
		self.urlField.text = url;
	}
}

- (IBAction) saveBookmark:(id)sender
{
	[self.progressSpinner startAnimating];
	
	NSString* url = self.urlField.text;
	
	// save bookmark
	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub"];
	NSDictionary* args = @{
		@"h": @"entry",
		@"content": @"",
		@"bookmark-of": url
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync (^{
			[self dismissViewControllerAnimated:YES completion:^{
				// notify bookmarks to update
				[[NSNotificationCenter defaultCenter] postNotificationName:kLoadTimelineNotification object:self];
			}];
		});
	}];
}

- (IBAction) cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end
