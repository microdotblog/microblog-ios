//
//  RFAccount.m
//  Micro.blog
//
//  Created by Manton Reece on 9/5/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFAccount.h"

#import "RFSettings.h"
#import "SSKeychain.h"

@implementation RFAccount

+ (NSArray *) allAccounts
{
	NSMutableArray* accounts = [NSMutableArray array];
	NSArray* usernames = [RFSettings accountsUsernames];
	if (usernames == nil) {
		NSString* username = [RFSettings snippetsUsername];
		if (username) {
			RFAccount* a = [[RFAccount alloc] init];
			a.username = username;
			[accounts addObject:a];
		}
	}
	else {
		for (NSString* username in usernames) {
			RFAccount* a = [[RFAccount alloc] init];
			a.username = username;
			[accounts addObject:a];
		}
	}
	
	return accounts;
}

+ (instancetype) defaultAccount
{
	NSString* username = [RFSettings snippetsUsername];
	NSArray* accounts = [self allAccounts];
	RFAccount* found_account = nil;
	if (username) {
		for (RFAccount* a in accounts) {
			if ([a.username isEqualToString:username]) {
				found_account = a;
				break;
			}
		}
	}
	
	if (found_account) {
		return found_account;
	}
	else {
		return [accounts firstObject];
	}
}

- (NSString *) password
{
	return [SSKeychain passwordForService:@"Snippets" account:self.username];
}

- (NSString *) profileURL
{
	return [NSString stringWithFormat:@"https://micro.blog/%@/avatar.jpg", self.username];
}

- (void) setDefault
{
	[RFSettings setSnippetsUsername:self.username];
}

@end
