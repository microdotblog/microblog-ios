//
//  RFAutoCompleteCache.m
//  Micro.blog
//
//  Created by Jonathan Hays on 11/30/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFAutoCompleteCache.h"
#import "UUString.h"

@implementation RFAutoCompleteCache

+ (NSArray*) allAutoCompleteStrings
{
	NSArray* strings = [[NSUserDefaults standardUserDefaults] objectForKey:@"RFAutoCompleteCache"];
	return strings;
}

+ (void) setAutoCompleteStrings:(NSArray*)array
{
	[[NSUserDefaults standardUserDefaults] setObject:array forKey:@"RFAutoCompleteCache"];
}

+ (void) addAutoCompleteString:(NSString*)inString
{
	NSString* string = [inString stringByReplacingOccurrencesOfString:@"@" withString:@""];
	NSMutableArray* newStrings = [NSMutableArray array];
	NSArray* oldStrings = [RFAutoCompleteCache allAutoCompleteStrings];
	if (oldStrings)
	{
		newStrings = [NSMutableArray arrayWithArray:oldStrings];
	}
	
	if (![newStrings containsObject:string])
	{
		[newStrings addObject:string];
		[RFAutoCompleteCache setAutoCompleteStrings:newStrings];
	}
}

+ (void) findAutoCompleteFor:(NSString*)inString completion:(void (^)(NSArray* results))completion
{
	NSString* string = [inString stringByReplacingOccurrencesOfString:@"@" withString:@""];
	NSMutableArray* foundStrings = [NSMutableArray array];
	NSArray* autoCompleteStrings = [RFAutoCompleteCache allAutoCompleteStrings];
	for (NSString* autoCompleteString in autoCompleteStrings)
	{
		if ([autoCompleteString.lowercaseString uuStartsWithSubstring:string.lowercaseString])
		{
			if (![autoCompleteString.lowercaseString isEqualToString:string.lowercaseString])
			{
				[foundStrings addObject:autoCompleteString];
			}
		}
	}
	
	completion(foundStrings);
}


@end
