//
//  RFOptionsController.m
//  Snippets
//
//  Created by Manton Reece on 8/25/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFOptionsController.h"

#import "RFClient.h"
#import "RFPostController.h"
#import "RFConstants.h"
#import "RFMacros.h"
#import "UUAlert.h"
#import "UITraitCollection+Extras.h"

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
	else if (self.popoverType == kOptionsPopoverEditPost) {
		self.view = self.editPostView;
	}
	else if (self.popoverType == kOptionsPopoverEditWithPublish) {
		self.view = self.editWithPublishView;
	}
	else if (self.popoverType == kOptionsPopoverEditDeleteOnly) {
		self.view = self.editDeleteOnlyView;
	}
	else if (self.popoverType == kOptionsPopoverUpload) {
		self.view = self.uploadView;
	}
	else if (self.popoverType == kOptionsPopoverHighlight) {
		self.view = self.highlightView;
	}

	if ([UITraitCollection rf_isDarkMode]) {
		self.view.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
	}

	self.popoverPresentationController.backgroundColor = self.view.backgroundColor;
	self.preferredContentSize = self.view.bounds.size;
}

- (void) attachToView:(UIView *)view atRect:(CGRect)rect
{
	CGRect r = rect;
	
	if (r.origin.y < 0) {
		r.origin.y = 0;
	}
	
	self.popoverPresentationController.sourceView = view;
	self.popoverPresentationController.sourceRect = r;
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

- (IBAction) removePost:(id)sender
{
	[UUAlertViewController uuShowTwoButtonAlert:@"Remove this post?" message:@"If you are using an external blog such as WordPress, you should also remove the post from that blog." buttonOne:@"Cancel" buttonTwo:@"Remove" completionHandler:^(NSInteger buttonIndex) {
		if (buttonIndex == 1) {
			RFClient* client = [[RFClient alloc] initWithFormat:@"/posts/%@", self.postID];
			[client deleteWithObject:nil completion:^(UUHttpResponse* response) {
				RFDispatchMainAsync (^{
					[[NSNotificationCenter defaultCenter] postNotificationName:kPostWasDeletedNotification object:self userInfo:@{ kPostNotificationPostIDKey: self.postID}];
					[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
				});
			}];
		}
	}];
}

- (IBAction) share:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kSharePostNotification object:self userInfo:@{ kSharePostIDKey: self.postID }];
	}];
}

- (IBAction) editPost:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kEditPostNotification object:self userInfo:@{ kEditPostIDKey: self.postID }];
	}];
}

- (IBAction) deletePost:(id)sender
{
	[UUAlertViewController uuShowTwoButtonAlert:@"Delete this post?" message:@"This post will be deleted from your blog and removed from the timeline." buttonOne:@"Cancel" buttonTwo:@"Delete" completionHandler:^(NSInteger buttonIndex) {
		if (buttonIndex == 1) {
			[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
				[[NSNotificationCenter defaultCenter] postNotificationName:kDeletePostNotification object:self userInfo:@{ kDeletePostIDKey: self.postID }];
			}];
		}
	}];
}

- (IBAction) publishPost:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kPublishPostNotification object:self userInfo:@{ kPublishPostIDKey: self.postID }];
	}];
}

- (IBAction) openUpload:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kOpenUploadNotification object:self userInfo:@{ kPublishPostIDKey: self.postID }];
	}];
}

- (IBAction) copyUpload:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kCopyUploadNotification object:self userInfo:@{ kPublishPostIDKey: self.postID }];
	}];
}

- (IBAction) deleteUpload:(id)sender
{
	[UUAlertViewController uuShowTwoButtonAlert:@"Delete this upload?" message:@"This upload will be deleted from your blog." buttonOne:@"Cancel" buttonTwo:@"Delete" completionHandler:^(NSInteger buttonIndex) {
		if (buttonIndex == 1) {
			[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
				[[NSNotificationCenter defaultCenter] postNotificationName:kDeleteUploadNotification object:self userInfo:@{ kPublishPostIDKey: self.postID }];
			}];
		}
	}];
}

- (IBAction) newPostFromHighlight:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kNewPostFromHighlightNotification object:self];
	}];
}

- (IBAction) copyHighlight:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kCopyHighlightNotification object:self];
	}];
}

- (IBAction) deleteHighlight:(id)sender
{
	[UUAlertViewController uuShowTwoButtonAlert:@"Delete this highlight?" message:@"This highlight will be deleted from the bookmark." buttonOne:@"Cancel" buttonTwo:@"Delete" completionHandler:^(NSInteger buttonIndex) {
		if (buttonIndex == 1) {
			[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
				[[NSNotificationCenter defaultCenter] postNotificationName:kDeleteHighlightNotification object:self];
			}];
		}
	}];
}

@end
