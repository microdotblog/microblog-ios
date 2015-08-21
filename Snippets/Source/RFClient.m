//
//  RFClient.m
//  Snippets
//
//  Created by Manton Reece on 8/21/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFClient.h"

static NSString* const kServerSchemeAndHostname = @"http://snippets.today";

@implementation RFClient

- (instancetype) initWithPath:(NSString *)path
{
	self = [super init];
	if (self) {
		self.path = path;
		self.url = [NSString stringWithFormat:@"%@%@", kServerSchemeAndHostname, self.path];
	}
	
	return self;
}

- (instancetype) initWithFormat:(NSString *)path, ...
{
	self = [super init];
	if (self) {
		va_list args;
		va_start (args, path);
		self.path = [[NSString alloc] initWithFormat:path arguments:args];
		self.url = [NSString stringWithFormat:@"%@%@", kServerSchemeAndHostname, self.path];
	}
	
	return self;
}

- (void) setupRequest:(UUHttpRequest *)request
{
	NSMutableDictionary* headers = [request.headerFields mutableCopy];
	if (headers == nil) {
		headers = [NSMutableDictionary dictionary];
	}
	
//	[headers setObject:authToken forKey:@"X-Snippets-Token"];
	request.headerFields = headers;
}

#pragma mark -

- (UUHttpRequest *) getWithQueryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler
{
	UUHttpRequest* request = [UUHttpRequest getRequest:self.url queryArguments:args];
	[self setupRequest:request];
	
	return [UUHttpSession executeRequest:request completionHandler:handler];
}

#pragma mark -

- (UUHttpRequest *) postWithObject:(id)object completion:(void (^)(UUHttpResponse* response))handler
{
	return [self postWithObject:object queryArguments:nil completion:handler];
}

- (UUHttpRequest *) postWithObject:(id)object queryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler
{
	NSData* d;
	if (object) {
		d = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
	}
	else {
		d = [NSData data];
	}

	UUHttpRequest* request = [UUHttpRequest postRequest:self.url queryArguments:args body:d contentType:@"application/json"];
	[self setupRequest:request];

	return [UUHttpSession executeRequest:request completionHandler:handler];
}

- (UUHttpRequest *) putWithObject:(id)object completion:(void (^)(UUHttpResponse* response))handler
{
	NSData* d;
	if (object) {
		d = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
	}
	else {
		d = [NSData data];
	}

	UUHttpRequest* request = [UUHttpRequest putRequest:self.url queryArguments:nil body:d contentType:@"application/json"];
	[self setupRequest:request];

	return [UUHttpSession executeRequest:request completionHandler:handler];
}

- (UUHttpRequest *) deleteWithObject:(id)object completion:(void (^)(UUHttpResponse* response))handler
{
	return [self deleteWithObject:object queryArguments:nil completion:handler];
}

- (UUHttpRequest *) deleteWithObject:(id)object queryArguments:(NSDictionary *)args completion:(void (^)(UUHttpResponse* response))handler
{
	NSData* d;
	if (object) {
		d = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
	}
	else {
		d = [NSData data];
	}

	UUHttpRequest* request = [UUHttpRequest deleteRequest:self.url queryArguments:args body:d contentType:@"application/json"];
	[self setupRequest:request];

	return [UUHttpSession executeRequest:request completionHandler:handler];
}

@end
