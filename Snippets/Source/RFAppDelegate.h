//
//  RFAppDelegate.h
//  Snippets
//
//  Created by Manton Reece on 6/4/15.
//  Copyright (c) 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RFTimelineController;

@interface RFAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow* window;
@property (strong, nonatomic) RFTimelineController* timelineController;

@end

