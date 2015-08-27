//
//  RFPostController.m
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFPostController.h"

#import "RFClient.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"
#import "NSString+Extras.h"
#import "UILabel+MarkupExtensions.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@implementation RFPostController

- (instancetype) init
{
	self = [super initWithNibName:@"Post" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (instancetype) initWithReplyTo:(NSString *)postID replyUsername:(NSString *)username
{
	self = [self init];
	if (self) {
		self.isReply = YES;
		self.replyPostID = postID;
		self.replyUsername = username;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupText];
	[self setupNotifications];
}

- (void) viewDidAppear:(BOOL)animated
{
	[self.textView becomeFirstResponder];
}

- (void) setupNavigation
{
	if (self.isReply) {
		self.title = @"New Reply";
	}
	else {
		self.title = @"New Post";
	}

	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"close_button" target:self action:@selector(close:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStylePlain target:self action:@selector(sendPost:)];
}

- (void) setupText
{
	if (self.replyUsername) {
		self.textView.text = [NSString stringWithFormat:@"@%@ ", self.replyUsername];
	}
	
	[self updateRemainingChars];
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) updateRemainingChars
{
	NSInteger max_chars = 280;
	NSInteger num_chars = self.textView.text.length;
	NSInteger num_remaining = max_chars - num_chars;
	if (num_chars <= 140) {
		[self.remainingField setMarkup:[NSString stringWithFormat:@"<font color=\"#428BCA\">%ld</font>/%ld", (long)num_chars, (long)max_chars]];
	}
	else if (num_remaining < 0) {
		[self.remainingField setMarkup:[NSString stringWithFormat:@"<font color=\"#FF6057\">%ld</font>/%ld", (long)num_chars, (long)max_chars]];
	}
	else {
		self.remainingField.text = [NSString stringWithFormat:@"%ld/%ld", (long)num_chars, (long)max_chars];
	}
}

- (void) keyboardWasShown:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    CGSize kb_size = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

	self.bottomConstraint.constant = kb_size.height;
	[self.view layoutIfNeeded];
}
 
- (void) keyboardWillBeHidden:(NSNotification*)aNotification
{
	self.bottomConstraint.constant = 0;
	[self.view layoutIfNeeded];
}

- (void) textViewDidChange:(UITextView *)textView
{
	[self updateRemainingChars];
}

- (IBAction) sendPost:(id)sender
{
	if (self.isReply) {
		RFClient* client = [[RFClient alloc] initWithPath:@"/posts/reply"];
		NSDictionary* args = @{
			@"id": self.replyPostID,
			@"text": self.textView.text
		};
		[client postWithParams:args completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				[Answers logCustomEventWithName:@"Sent Reply" customAttributes:nil];
				[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
			});
		}];
	}
	else {
		RFClient* client = [[RFClient alloc] initWithPath:@"/pages/create"];
		NSDictionary* args = @{
			@"text": self.textView.text
		};
		[client postWithParams:args completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				[Answers logCustomEventWithName:@"Sent Post" customAttributes:nil];
				[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
			});
		}];
	}
}

- (IBAction) close:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
