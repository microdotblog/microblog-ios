//
//  RFUserCache.h
//  Micro.blog
//
//  Created by Jonathan Hays on 12/1/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFUserCache : NSObject

    + (NSDictionary*) user:(NSString*)user;
    + (void) setCache:(NSDictionary*)userInfo forUser:(NSString*)user;

	+ (UIImage*) avatar:(NSURL*)url completionHandler:(void(^)(UIImage* image)) completionHandler;
    + (void) cacheAvatar:(UIImage*)image forURL:(NSURL*)url;

@end


NS_ASSUME_NONNULL_END
