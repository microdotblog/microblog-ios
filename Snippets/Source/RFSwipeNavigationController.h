//
//  RFSwipeNavigationController.h
//  Micro.blog
//
//  Created by Manton Reece on 2/5/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFSwipeNavigationController : UINavigationController

@property (strong, nonatomic) UIPanGestureRecognizer* panGesture;
@property (assign, nonatomic) BOOL isSwipingBack;
@property (assign, nonatomic) BOOL isSwipingForward;
@property (strong, nonatomic) UIView* revealedView;
@property (strong, nonatomic) UIViewController* nextController;

- (id) initWithRootViewController:(UIViewController *)controller;

@end
