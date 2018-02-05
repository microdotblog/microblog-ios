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

	NSLog (@"pt: %f, v: %f", pt.x, v.x);

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
		[self updateDroppedView:current_controller.view forX:pt.x];
	}
	else if (gesture.state == UIGestureRecognizerStateCancelled) {
		[self updateDroppedView:current_controller.view forX:pt.x];
	}
}

- (void) prepareConversation
{
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
				revealed_r.origin.y = RFStatusAndNavigationHeight();
				revealed_r.size.height = revealed_r.size.height - RFStatusAndNavigationHeight();
			}
			[self.view insertSubview:self.revealedView belowSubview:v];
			[self.view sendSubviewToBack:self.revealedView];
			self.revealedView.frame = revealed_r;
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
			revealed_r.origin.y = RFStatusAndNavigationHeight();
			revealed_r.origin.x = v.bounds.size.width;
			[self.view insertSubview:self.revealedView aboveSubview:v];
			[self.view bringSubviewToFront:self.revealedView];
			self.revealedView.frame = revealed_r;
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

- (void) updateDroppedView:(UIView *)v forX:(CGFloat)x
{
	CGRect top_r = v.frame;
	CGRect revealed_r = self.revealedView.frame;
	CGFloat half_width = v.bounds.size.width / 2.0;
	
	if (self.isSwipingBack && (x > half_width)) {
		top_r.origin.x = v.bounds.size.width;
		revealed_r.origin.x = 0;
	}
	else if (self.isSwipingForward && (x < -half_width)) {
		top_r.origin.x = -v.bounds.size.width;
		revealed_r.origin.x = 0;
	}
	else if (self.isSwipingBack) {
		top_r.origin.x = 0;
		revealed_r.origin.x = -v.bounds.size.width;
	}
	else if (self.isSwipingForward) {
		top_r.origin.x = 0;
		revealed_r.origin.x = v.bounds.size.width;
	}

	[UIView animateWithDuration:0.3 animations:^{
		v.frame = top_r;
		self.revealedView.frame = revealed_r;
	} completion:^(BOOL finished) {
		if (self.isSwipingBack && (x > half_width)) {
			[self popViewControllerAnimated:NO];
		}
		else if (self.isSwipingForward && (x < -half_width)) {
			if (self.nextController) {
				[self pushViewController:self.nextController animated:NO];
			}
		}

		[self.revealedView removeFromSuperview];
		self.revealedView = nil;
		self.nextController = nil;
	}];
}

@end
