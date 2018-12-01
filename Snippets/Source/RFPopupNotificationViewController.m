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

+ (void) show:(NSString*)body fromUsername:(NSString *)username inController:(UIViewController*) controller completionBlock:(void(^)())completionBlock
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		RFPopupNotificationViewController* vc = [RFPopupNotificationViewController new];
		CGFloat margin = 4.0;
		CGRect f = vc.view.frame;
		f.origin.y = -f.size.height;
		f.origin.x = margin;
		f.size.width = controller.view.bounds.size.width - (margin * 2);
		
		vc.view.frame = f;
		[controller.view addSubview:vc.view];
		[controller addChildViewController:vc];
		
		vc.messageLabel.text = body;
		vc.completionHandler = completionBlock;
		
		vc.view.layer.cornerRadius = 10.0;
		vc.view.layer.borderWidth = 0.5;
		vc.view.layer.masksToBounds = YES;
		vc.view.layer.borderColor = UIColor.lightGrayColor.CGColor;

		if (username.length > 0) {
			NSString* profile_s = [NSString stringWithFormat:@"https://micro.blog/%@/avatar.jpg", username];
			NSURL* profile_url = [NSURL URLWithString:profile_s];
			[vc.profileImageView uuLoadImageFromURL:profile_url defaultImage:nil loadCompleteHandler:^(UIImageView* imageView) {
				imageView.layer.cornerRadius = imageView.bounds.size.width / 2.0;
			}];
		}

		f.origin.y = 44;
		[UIView animateWithDuration:0.5 animations:^
		{
			vc.view.frame = f;
		}
		completion:^(BOOL finished)
		{
			[vc queueAutoDismissTimer];
		}];
	});
}

@end
