//
//  RFOptionsController.m
//  Snippets
//
//  Created by Manton Reece on 8/25/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFOptionsController.h"

#import "RFClient.h"
#import "RFConstants.h"
#import "RFMacros.h"

@implementation RFOptionsController

- (instancetype) initWithPostID:(NSString *)postID
{
	self = [super initWithNibName:@"Options" bundle:nil];
	if (self) {
		self.postID = postID;
		self.modalPresentationStyle = UIModalPresentationPopover;
		self.popoverPresentationController.delegate = self;
		self.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	self.preferredContentSize = self.view.bounds.size;
	self.popoverPresentationController.backgroundColor = self.view.backgroundColor;
}

- (void) attachToView:(UIView *)view atRect:(CGRect)rect
{
	self.popoverPresentationController.sourceView = view;
	self.popoverPresentationController.sourceRect = rect;
}

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
	return UIModalPresentationNone;
}

#pragma mark -

- (IBAction) reply:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
	}];
}

- (IBAction) favorite:(id)sender
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/posts/favorite"];
	NSDictionary* args = @{ @"id": self.postID };
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync (^{
			[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
		});
	}];
}

- (IBAction) conversation:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kShowConversationNotification object:self userInfo:@{ kShowConversationPostKey: self.postID }];
	}];
}

@end
