//
//  RFClient.m
//  Snippets
//
//  Created by Manton Reece on 8/21/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UUHttpSession.h"

@interface RFClient : NSObject

@property (strong, nonatomic) NSString* path;
@property (strong, nonatomic) NSString* url;

- (instancetype) initWithPath:(NSString *)path;
- (instancetype) initWithFormat:(NSString *)path, ...;

- (UUHttpRequest *) getWithQueryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler;

- (UUHttpRequest *) postWithObject:(id)object completion:(void (^)(UUHttpResponse* response))handler;
- (UUHttpRequest *) postWithObject:(id)object queryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler;

- (UUHttpRequest *) putWithObject:(id)object completion:(void (^)(UUHttpResponse* response))handler;

- (UUHttpRequest *) deleteWithObject:(id)object completion:(void (^)(UUHttpResponse* response))handler;
- (UUHttpRequest *) deleteWithObject:(id)object queryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler;

@end
