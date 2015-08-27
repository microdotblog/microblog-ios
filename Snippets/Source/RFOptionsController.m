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

- (instancetype) initWithPostID:(NSString *)postID popoverType:(RFOptionsPopoverType)popoverType
{
	self = [super initWithNibName:@"Options" bundle:nil];
	if (self) {
		self.postID = postID;
		self.popoverType = popoverType;
		
		self.modalPresentationStyle = UIModalPresentationPopover;
		self.popoverPresentationController.delegate = self;
		self.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	if (self.popoverType == kOptionsPopoverWithUnfavorite) {
		self.view = self.withUnfavoriteView;
	}
	else if (self.popoverType == kOptionsPopoverWithDelete) {
		self.view = self.withDeleteView;
	}

	self.popoverPresentationController.backgroundColor = self.view.backgroundColor;
	self.preferredContentSize = self.view.bounds.size;
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
			[[NSNotificationCenter defaultCenter] postNotificationName:kPostWasFavoritedNotification object:self userInfo:@{ kPostNotificationPostIDKey: self.postID}];
			[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
		});
	}];
}

- (IBAction) unfavorite:(id)sender
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/posts/unfavorite"];
	NSDictionary* args = @{ @"id": self.postID };
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync (^{
			[[NSNotificationCenter defaultCenter] postNotificationName:kPostWasUnfavoritedNotification object:self userInfo:@{ kPostNotificationPostIDKey: self.postID}];
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

- (IBAction) deletePost:(id)sender
{
	RFClient* client = [[RFClient alloc] initWithFormat:@"/posts/%@", self.postID];
	[client deleteWithObject:nil completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync (^{
			[[NSNotificationCenter defaultCenter] postNotificationName:kPostWasDeletedNotification object:self userInfo:@{ kPostNotificationPostIDKey: self.postID}];
			[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
		});
	}];
}

@end
