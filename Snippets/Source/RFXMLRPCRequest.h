//
//  RFXMLRPCRequest.h
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UUHttpSession.h"

@interface RFXMLRPCRequest : NSObject

@property (strong, nonatomic) NSString* url;

- (instancetype) initWithURL:(NSString *)url;

- (UUHttpRequest *) getPath:(NSString *)path completion:(void (^)(UUHttpResponse* response))handler;
- (UUHttpRequest *) sendMethod:(NSString *)method completion:(void (^)(UUHttpResponse* response))handler;
- (void) discoverEndpointWithCompletion:(void (^)(NSString* xmlrpcEndpointURL, NSString* blogID))handler;

@end
