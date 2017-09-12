//
//  RFBrowserActivity.m
//  Micro.blog
//
//  Created by Manton Reece on 9/11/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFBrowserActivity.h"

#import "RFConstants.h"

@implementation RFBrowserActivity

- (NSString *) activityType
{
	return @"blog.micro.ios.activity.browser";
}

- (NSString *) activityTitle
{
	return @"Browser";
}

- (UIImage *) activityImage
{  
	return [UIImage imageNamed:@"browser_activity.png"];
}

- (BOOL) canPerformWithActivityItems:(NSArray *)activityItems
{
	return YES;
}

- (void) prepareWithActivityItems:(NSArray *)activityItems
{
	self.activityURL = [activityItems firstObject];
}

- (void) performActivity
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kOpenURLNotification object:self userInfo:@{ kOpenURLKey: self.activityURL }];
	[self activityDidFinish:YES];
}

@end
