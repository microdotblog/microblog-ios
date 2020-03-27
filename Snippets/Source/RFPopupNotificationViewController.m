//
//  RFPopupNotificationViewController.m
//  Micro.blog
//
//  Created by Jonathan Hays on 5/17/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFPopupNotificationViewController.h"

#import "UUImageView.h"

@interface RFPopupNotificationViewController ()
	@property (nonatomic, strong) NSTimer* dismissTimer ;
@end

@implementation RFPopupNotificationViewController


- (IBAction) onTapped:(id)sender
{
	[self dismiss];

	if (self.completionHandler)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			self.completionHandler();
		});
	}
}

- (void) queueAutoDismissTimer
{
	[self.dismissTimer invalidate];
	self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
}

- (void) dismiss
{
	[self.dismissTimer invalidate];
	self.dismissTimer = nil;
	
	CGRect f = self.view.frame;
	f.origin.y = -f.size.height;
	
	[UIView animateWithDuration:0.5 animations:^
	{
		self.view.frame = f;
	}
	completion:^(BOOL finished)
	{
		[self.view removeFromSuperview];
		[self removeFromParentViewController];
	}];
}

+ (void) show:(NSString*)body fromUsername:(NSString *)username inController:(UIViewController*) controller completionBlock:(void(^)(void))completionBlock
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		RFPopupNotificationViewController* vc = [RFPopupNotificationViewController new];
		CGFloat margin = 6.0;
		CGRect f = vc.view.frame;
		CGFloat offscreen_y = -f.size.height;

		[controller.view addSubview:vc.view];

		NSLayoutConstraint* top_constraint = [NSLayoutConstraint constraintWithItem:vc.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:controller.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:offscreen_y];
		[top_constraint setActive:YES];
		NSLayoutConstraint* left_constraint = [NSLayoutConstraint constraintWithItem:vc.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:controller.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:margin];
		[left_constraint setActive:YES];
		NSLayoutConstraint* right_constraint = [NSLayoutConstraint constraintWithItem:vc.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:controller.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-margin];
		[right_constraint setActive:YES];
		NSLayoutConstraint* height_constraint = [NSLayoutConstraint constraintWithItem:vc.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:68.0];
		[height_constraint setActive:YES];

		[controller.view layoutIfNeeded];

		vc.messageLabel.text = body;
		vc.completionHandler = completionBlock;
		
		vc.view.layer.cornerRadius = 10.0;
		vc.view.layer.borderWidth = 0.5;
		vc.view.layer.masksToBounds = YES;
		
		if (@available(iOS 11.0, *)) {
			vc.view.layer.borderColor = [UIColor colorNamed:@"color_notification_outline"].CGColor;
		}

		if (username.length > 0) {
			NSString* profile_s = [NSString stringWithFormat:@"https://micro.blog/%@/avatar.jpg", username];
			NSURL* profile_url = [NSURL URLWithString:profile_s];
			[vc.profileImageView uuLoadImageFromURL:profile_url defaultImage:nil loadCompleteHandler:^(UIImageView* imageView) {
				imageView.layer.cornerRadius = imageView.bounds.size.width / 2.0;
			}];
		}

		[UIView animateWithDuration:0.3 animations:^
		{
			top_constraint.constant = 44.0;
			[controller.view layoutIfNeeded];
		}
		completion:^(BOOL finished)
		{
			[vc queueAutoDismissTimer];
		}];
	});
}

@end
