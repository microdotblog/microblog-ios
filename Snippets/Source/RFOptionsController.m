//
//  RFOptionsController.m
//  Snippets
//
//  Created by Manton Reece on 8/25/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFOptionsController.h"

#import "RFClient.h"
#import "RFPostController.h"
#import "RFConstants.h"
#import "RFMacros.h"

@implementation RFOptionsController

- (instancetype) initWithPostID:(NSString *)postID username:(NSString *)username popoverType:(RFOptionsPopoverType)popoverType
{
	self = [super initWithNibName:@"Options" bundle:nil];
	if (self) {
		self.postID = postID;
		self.username = username;
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

- (void) sendUnselectedNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kPostWasUnselectedNotification object:self userInfo:@{
		kShowReplyPostIDKey: self.postID,
		kShowReplyPostUsernameKey: self.username
	}];
}

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
	return UIModalPresentationNone;
}

- (BOOL) popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)controller
{
	[self sendUnselectedNotification];
	return YES;
}

#pragma mark -

- (IBAction) reply:(id)sender
{
	[self sendUnselectedNotification];
	
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kShowReplyPostNotification object:self userInfo:@{
			kShowReplyPostIDKey: self.postID,
			kShowReplyPostUsernameKey: self.username
		}];
	}];
}

- (IBAction) favorite:(id)sender
{
	[self sendUnselectedNotification];

	RFClient* client = [[RFClient alloc] initWithPath:@"/posts/favorites"];
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
	[self sendUnselectedNotification];

	RFClient* client = [[RFClient alloc] initWithFormat:@"/posts/favorites/%@", self.postID];
	[client deleteWithObject:nil completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync (^{
			[[NSNotificationCenter defaultCenter] postNotificationName:kPostWasUnfavoritedNotification object:self userInfo:@{ kPostNotificationPostIDKey: self.postID}];
			[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
		});
	}];
}

- (IBAction) conversation:(id)sender
{
	[self sendUnselectedNotification];

	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kShowConversationNotification object:self userInfo:@{ kShowConversationPostIDKey: self.postID }];
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

- (IBAction) share:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kSharePostNotification object:self userInfo:@{ kSharePostIDKey: self.postID }];
	}];
}

@end
