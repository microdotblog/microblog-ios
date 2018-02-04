//
//  RFFeed.m
//  Micro.blog
//
//  Created by Manton Reece on 2/4/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFFeed.h"

@implementation RFFeed

- (id) initWithResponse:(NSDictionary *)info
{
	self = [super init];
	if (self) {
		self.feedID = info[@"id"];
		self.url = info[@"url"];
		self.twitterUsername = info[@"twitter_username"];
		self.facebookName = info[@"facebook_name"];
		self.hasBot = [info[@"has_bot"] boolValue];
		self.isDisabledCrossposting = [info[@"is_disabled_crossposting"] boolValue];
	}
	
	return self;
}

- (NSString *) summary
{
	NSString* twitter_s = self.twitterUsername;
	NSString* facebook_s = self.facebookName;
	NSString* usernames_s = @"";
	if ((twitter_s.length > 0) && (facebook_s.length > 0)) {
		usernames_s = [NSString stringWithFormat:@"Twitter: %@, Facebook: %@", twitter_s, facebook_s];
	}
	else if (twitter_s.length > 0) {
		usernames_s = [NSString stringWithFormat:@"Twitter: %@", twitter_s];
	}
	else if (facebook_s.length > 0) {
		usernames_s = [NSString stringWithFormat:@"Facebook: %@", facebook_s];
	}
	else {
		usernames_s = @"Cross-posting has not been added.";
	}
	
	return usernames_s;
}

@end
