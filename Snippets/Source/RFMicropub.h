//
//  RFMicropub.h
//  Micro.blog
//
//  Created by Manton Reece on 4/12/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UUHttpSession.h"

@interface RFMicropub : NSObject

@property (strong, nonatomic) NSString* url;

- (instancetype) initWithURL:(NSString *)url;

- (UUHttpRequest *) getWithQueryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler;

- (UUHttpRequest *) postWithParams:(NSDictionary *)params completion:(void (^)(UUHttpResponse* response))handler;
- (UUHttpRequest *) postWithObject:(id)object completion:(void (^)(UUHttpResponse* response))handler;
- (UUHttpRequest *) postWithObject:(id)object queryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler;

@end
