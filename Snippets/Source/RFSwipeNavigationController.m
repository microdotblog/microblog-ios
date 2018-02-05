//
//  RFSwipeNavigationController.m
//  Micro.blog
//
//  Created by Manton Reece on 2/5/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFSwipeNavigationController.h"

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
			self.isSwipingForward = YES;
		}
	}
	else if (gesture.state == UIGestureRecognizerStateChanged) {
		[self updateDraggedView:current_controller.view forX:pt.x];
	}
	else if (gesture.state == UIGestureRecognizerStateEnded) {
		[self updateDroppedView:current_controller.view];
	}
	else if (gesture.state == UIGestureRecognizerStateCancelled) {
		[self updateDroppedView:current_controller.view];
	}
}

- (void) updateDraggedView:(UIView *)v forX:(CGFloat)x
{
	CGRect top_r = v.frame;
	if (self.isSwipingBack) {
		if (x >= 0) {
			top_r.origin.x = x;
			v.frame = top_r;
		}
	}
	else if (self.isSwipingForward) {
		if (x <= 0) {
			top_r.origin.x = x;
			v.frame = top_r;
		}
	}
}

- (void) updateDroppedView:(UIView *)v
{
	CGRect top_r = v.frame;
	top_r.origin.x = 0;
	[UIView animateWithDuration:0.3 animations:^{
		v.frame = top_r;
	}];
}

@end
