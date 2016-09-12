//
//  RFAppDelegate.h
//  Snippets
//
//  Created by Manton Reece on 6/4/15.
//  Copyright (c) 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RFSignInController;
@class RFMenuController;
@class RFTimelineController;

@interface RFAppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate>

@property (strong, nonatomic) UIWindow* window;
@property (strong, nonatomic) UISplitViewController* splitViewController;
@property (strong, nonatomic) UINavigationController* navigationController;
@property (strong, nonatomic) UINavigationController* menuNavController;
@property (strong, nonatomic) RFSignInController* signInController;
@property (strong, nonatomic) RFMenuController* menuController;
@property (strong, nonatomic) RFTimelineController* timelineController;

@end

