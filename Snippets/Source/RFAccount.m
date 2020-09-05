//
//  RFAccount.m
//  Micro.blog
//
//  Created by Manton Reece on 9/5/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFAccount.h"

#import "RFSettings.h"

@implementation RFAccount

+ (NSArray *) allAccounts
{
	NSMutableArray* accounts = [NSMutableArray array];
	NSArray* usernames = [[NSUserDefaults standardUserDefaults] arrayForKey:@"AccountUsernames"];
	if (usernames == nil) {
		NSString* username = [RFSettings snippetsUsername];
		if (username) {
			RFAccount* a = [[RFAccount alloc] init];
			a.username = username;
			[accounts addObject:a];
		}
	}
	
	return accounts;
}

@end
