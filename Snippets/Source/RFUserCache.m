//
//  RFUserCache.m
//  Micro.blog
//
//  Created by Jonathan Hays on 12/1/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFUserCache.h"
#import "RFAutoCompleteCache.h"
#import "UUDataCache.h"

@implementation RFUserCache

+ (UIImage*) avatar:(NSURL*)url
{
    NSData* cachedData = [UUDataCache uuDataForURL:url];
    UIImage* image = [UIImage imageWithData:cachedData];
    return image;
}

+ (void) cacheAvatar:(UIImage*)image forURL:(NSURL*)url
{
    NSData* data = UIImagePNGRepresentation(image);
    [UUDataCache uuCacheData:data forURL:url];
}

+ (NSDictionary*) user:(NSString*)user
{
    NSDictionary* dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:user];
    return dictionary;
}

+ (void) setCache:(NSDictionary*)userInfo forUser:(NSString*)user
{
    [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:user];
	
    [RFAutoCompleteCache addAutoCompleteString:user];
}

@end
