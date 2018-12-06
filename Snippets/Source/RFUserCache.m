//
//  RFUserCache.m
//  Micro.blog
//
//  Created by Jonathan Hays on 12/1/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFUserCache.h"
#import "RFAutoCompleteCache.h"
#import "UUHttpSession.h"
#import "UUDataCache.h"

@implementation RFUserCache


+ (dispatch_queue_t) imageProcessingQueue
{
	static id theImageProcessingQueue = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once (&onceToken, ^
	{
		theImageProcessingQueue = dispatch_queue_create("blog.micro.imagequeue", 0);
	});
	
	return theImageProcessingQueue;

}

+ (NSCache*) systemImageCache
{
	static id theSharedObject = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once (&onceToken, ^
				   {
					   theSharedObject = [[NSCache alloc] init];
				   });
	
	return theSharedObject;
}


+ (UIImage*) avatar:(NSURL*)url completionHandler:(void(^)(UIImage* image)) completionHandler
{
	UIImage* image = [[RFUserCache systemImageCache] objectForKey:url.absoluteString];
	if (image)
	{
		return image;
	}
	
	dispatch_async([RFUserCache imageProcessingQueue], ^{
    	NSData* cachedData = [UUDataCache uuDataForURL:url];
    	UIImage* image = [UIImage imageWithData:cachedData];
    	if (image)
    	{
			[[RFUserCache systemImageCache] setObject:image forKey:url.absoluteString];

    		dispatch_async(dispatch_get_main_queue(), ^{
				completionHandler(image);
			});
    		return;
		}

		[UUHttpSession get:url.absoluteString queryArguments:nil completionHandler:^(UUHttpResponse *response)
		{
			if ([response.parsedResponse isKindOfClass:[UIImage class]])
			{
				UIImage* image = response.parsedResponse;
				NSData* data = UIImagePNGRepresentation(image);
				[UUDataCache uuCacheData:data forURL:url];
				[[RFUserCache systemImageCache] setObject:image forKey:url.absoluteString];
				
    			dispatch_async(dispatch_get_main_queue(), ^{
					completionHandler(image);
				});
			}
		}];

	});

	return  nil;
}

+ (void) cacheAvatar:(UIImage*)image forURL:(NSURL*)url
{
	[[RFUserCache systemImageCache] setObject:image forKey:url.absoluteString];
	
	dispatch_async([RFUserCache imageProcessingQueue], ^{
    	NSData* data = UIImagePNGRepresentation(image);
    	[UUDataCache uuCacheData:data forURL:url];
	});
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
