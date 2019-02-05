//
//  RFSwipeNavigationController.m
//  Micro.blog
//
//  Created by Manton Reece on 2/5/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFSwipeNavigationController.h"

#import "RFTimelineController.h"
#import "RFMenuController.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "UIBarButtonItem+Extras.h"
#import "UIView+Extras.h"

static CGFloat const kSwipeDropAnimationDuration = 0.3;

@implementation RFSwipeNavigationController

- (id) initWithRootViewController:(UIViewController *)controller
{
	self = [super initWithRootViewController:controller];
	if (self) {
		[self setupGesture];
	}
	
	return self;
}

- (void) setupGesture
{
	self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
	[self.view addGestureRecognizer:self.panGesture];
}

- (void) panGesture:(UIPanGestureRecognizer *)gesture
{
	CGPoint pt = [gesture translationInView:self.view];
	CGPoint v = [gesture velocityInView:self.view];
	UIViewController* current_controller = [self.viewControllers lastObject];

//	NSLog (@"pt: %f, v: %f", pt.x, v.x);

	if (gesture.state == UIGestureRecognizerStateBegan) {
		if (v.x > 0.0) {
			if (self.viewControllers.count > 1) {
				self.isSwipingBack = YES;
				self.isSwipingForward = NO;
			}
			else {
				self.isSwipingBack = NO;
				self.isSwipingForward = NO;
			}
		}
		else {
			self.isSwipingBack = NO;
			self.isSwipingForward = NO;

			if ([current_controller isKindOfClass:[RFTimelineController class]]) {
				[self prepareConversation];
				if (self.nextController) {
					self.isSwipingForward = YES;
				}
			}
		}
	}
	else if (gesture.state == UIGestureRecognizerStateChanged) {
		[self updateDraggedView:current_controller.view forX:pt.x];
	}
	else if (gesture.state == UIGestureRecognizerStateEnded) {
		[self updateDroppedView:current_controller.view forX:pt.x withVelocity:v.x];
	}
	else if (gesture.state == UIGestureRecognizerStateCancelled) {
		[self updateDroppedView:current_controller.view forX:pt.x withVelocity:v.x];
	}
}

- (void) prepareConversation
{
	if ([self.panGesture numberOfTouches] > 0) {
		NSMutableArray* new_controllers = [NSMutableArray array];
		CGPoint pt = [self.panGesture locationOfTouch:0 inView:self.view];
		NSDictionary* info = @{
			kPrepareConversationPointKey: @(pt.y),
			kPrepareConversationControllersKey: new_controllers,
			kPrepareConversationTimelineKey: [self.viewControllers lastObject]

		};
		[[NSNotificationCenter defaultCenter] postNotificationName:kPrepareConversationNotification object:self userInfo:info];
		if (new_controllers.count > 0) {
			self.nextController = [new_controllers firstObject];
		}
	}
}

- (void) updateDraggedView:(UIView *)v forX:(CGFloat)x
{
	CGRect top_r = v.frame;
	CGRect revealed_r = v.frame;

	if (self.isSwipingBack) {
		if (self.revealedView == nil) {
			UIViewController* controller = [self.viewControllers objectAtIndex:self.viewControllers.count - 2];
			self.revealedView = controller.view;
			revealed_r.origin.x = 0;
			if ([controller isKindOfClass:[RFMenuController class]]) {
				revealed_r.origin.y = [self.view.window rf_statusBarAndNavigationHeight];
				revealed_r.size.height = revealed_r.size.height - [self.view.window rf_statusBarAndNavigationHeight];
			}
			[self.view insertSubview:self.revealedView belowSubview:v];
			[self.view sendSubviewToBack:self.revealedView];
			self.revealedView.frame = revealed_r;

			v.layer.shadowColor = [UIColor lightGrayColor].CGColor;
			v.layer.shadowOpacity = 0.3;
			v.layer.shadowOffset = CGSizeMake (-1.5, 1.5);
		}
		else {
			revealed_r = self.revealedView.frame;
		}
	
		if (x >= 0) {
			top_r.origin.x = x;
			v.frame = top_r;
			
			revealed_r.origin.x = -v.bounds.size.width + x;
			if (revealed_r.origin.x > 0) {
				revealed_r.origin.x = 0;
			}
			self.revealedView.frame = revealed_r;
		}
	}
	else if (self.isSwipingForward) {
		if (self.revealedView == nil) {
			self.revealedView = self.nextController.view;
			revealed_r.origin.y = [self.view.window rf_statusBarAndNavigationHeight];
			revealed_r.origin.x = v.bounds.size.width;
			[self.view insertSubview:self.revealedView aboveSubview:v];
			[self.view bringSubviewToFront:self.revealedView];
			self.revealedView.frame = revealed_r;
			
			self.revealedView.layer.shadowColor = [UIColor lightGrayColor].CGColor;
			self.revealedView.layer.shadowOpacity = 0.3;
			self.revealedView.layer.shadowOffset = CGSizeMake (-1.5, 1.5);

			CGRect line_r = self.nextController.view.frame;
			line_r.origin.x = 0;
			line_r.size.height = 0.5;
			self.revealedLine = [[UIView alloc] initWithFrame:line_r];
			self.revealedLine.layer.backgroundColor = [UIColor lightGrayColor].CGColor;
			self.revealedLine.layer.opaque = YES;
			[self.view insertSubview:self.revealedLine aboveSubview:self.revealedView];
			[self.view bringSubviewToFront:self.revealedLine];
			
			CGRect background_r = self.view.frame;
			self.revealedBackground = [[UIView alloc] initWithFrame:background_r];
			self.revealedBackground.layer.backgroundColor = [UIColor whiteColor].CGColor;
			self.revealedBackground.layer.opaque = YES;
			[self.view insertSubview:self.revealedBackground belowSubview:self.revealedView];
			[self.view sendSubviewToBack:self.revealedBackground];
		}
		else {
			revealed_r = self.revealedView.frame;
		}

		if (x <= 0) {
			top_r.origin.x = x;
			v.frame = top_r;

			revealed_r.origin.x = v.bounds.size.width + x;
			if (revealed_r.origin.x < 0) {
				revealed_r.origin.x = 0;
			}
			self.revealedView.frame = revealed_r;
		}
	}
}

- (void) updateDroppedView:(UIView *)v forX:(CGFloat)x withVelocity:(CGFloat)velocity
{
	CGRect top_r = v.frame;
	CGRect revealed_r = self.revealedView.frame;
	CGFloat half_width = v.bounds.size.width / 2.0;
	UIViewController* current_controller = [self.viewControllers lastObject];
	NSString* preserved_title = current_controller.title;
	UIImage* preserved_right_img = [current_controller.navigationItem.rightBarButtonItem rf_customImage];
	UIBarButtonItem* hide_bar_item = nil;

	BOOL is_threshold_back = ((x > half_width) || (velocity > 500));
	BOOL is_threshold_forward = ((x < -half_width) || (velocity < -500));
	CGFloat animation_seconds = kSwipeDropAnimationDuration;

//	if ((velocity > 700) || (velocity < -700)) {
//		animation_seconds = 0.2;
//	}

	if (self.isSwipingBack && is_threshold_back) {
		top_r.origin.x = v.bounds.size.width;
		revealed_r.origin.x = 0;

		UIViewController* previous_controller = [self.viewControllers objectAtIndex:self.viewControllers.count - 2];
		[self updateTitle:previous_controller.title withController:current_controller];
		if (self.viewControllers.count == 2) {
			hide_bar_item = current_controller.navigationItem.leftBarButtonItem;
		}
	}
	else if (self.isSwipingForward && is_threshold_forward) {
		top_r.origin.x = -v.bounds.size.width;
		revealed_r.origin.x = 0;

		if (self.nextController) {
			[self updateTitle:self.nextController.title withController:current_controller];
			[self updateRightImage:[UIImage imageNamed:@"reply_button"] withController:current_controller];
		}
	}
	else if (self.isSwipingBack) {
		top_r.origin.x = 0;
		revealed_r.origin.x = -v.bounds.size.width;
	}
	else if (self.isSwipingForward) {
		top_r.origin.x = 0;
		revealed_r.origin.x = v.bounds.size.width;
	}

	[UIView animateWithDuration:animation_seconds animations:^{
		v.frame = top_r;
		self.revealedView.frame = revealed_r;
		
		if (hide_bar_item) {
			hide_bar_item.customView.alpha = 0.0;
		}
	} completion:^(BOOL finished) {
		if (self.isSwipingBack && is_threshold_back) {
			[self popViewControllerAnimated:NO];
		}
		else if (self.isSwipingForward && is_threshold_forward) {
			if (self.nextController) {
				[self pushViewController:self.nextController animated:NO];
				current_controller.navigationItem.title = preserved_title;
			}
		}

		if (preserved_right_img) {
			[current_controller.navigationItem.rightBarButtonItem rf_setCustomImage:preserved_right_img];
		}

		[self.revealedView removeFromSuperview];
		[self.revealedLine removeFromSuperview];
		[self.revealedBackground removeFromSuperview];

		v.layer.shadowColor = nil;
		v.layer.shadowOpacity = 0;

		self.revealedView = nil;
		self.revealedLine = nil;
		self.revealedBackground = nil;
		self.nextController = nil;
	}];
}

- (void) updateTitle:(NSString *)title withController:(UIViewController *)controller
{
	CATransition* fade_animation = [CATransition animation];
	fade_animation.duration = kSwipeDropAnimationDuration;
	fade_animation.type = kCATransitionFade;

	[self.navigationBar.layer addAnimation:fade_animation forKey:@"fadeText"];
	controller.navigationItem.title = title;
}

- (void) updateRightImage:(UIImage *)img withController:(UIViewController *)controller
{
	CATransition* fade_animation = [CATransition animation];
	fade_animation.duration = kSwipeDropAnimationDuration;
	fade_animation.type = kCATransitionFade;

	UIImageView* v = controller.navigationItem.rightBarButtonItem.customView;
	[v.layer addAnimation:fade_animation forKey:@"fadeImage"];
	v.image = img;
}

@end
