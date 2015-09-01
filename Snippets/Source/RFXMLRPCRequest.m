//
//  RFXMLRPCRequest.m
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFXMLRPCRequest.h"

#import "RFXMLRSDParser.h"

@implementation RFBoolean

- (instancetype) initWithBool:(BOOL)value
{
	self = [super init];
	if (self) {
		self.boolValue = value;
	}
	
	return self;
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"%d", self.boolValue];
}

@end

#pragma mark -

@implementation RFXMLRPCRequest

- (instancetype) initWithURL:(NSString *)url
{
	self = [super init];
	if (self) {
		self.url = url;
	}
	
	return self;
}

- (UUHttpRequest *) getPath:(NSString *)path completion:(void (^)(UUHttpResponse* response))handler
{
	NSString* full_url = [self.url stringByAppendingPathComponent:path];

	UUHttpRequest* request = [UUHttpRequest getRequest:full_url queryArguments:nil];
	return [UUHttpSession executeRequest:request completionHandler:handler];
}

- (void) appendParam:(id)param toString:(NSMutableString *)requestString
{
	if ([param isKindOfClass:[RFBoolean class]]) {
		[requestString appendFormat:@"<boolean>%@</boolean>", param];
	}
	else if ([param isKindOfClass:[NSNumber class]]) {
		[requestString appendFormat:@"<int>%@</int>", param];
	}
	else if ([param isKindOfClass:[NSString class]]) {
		[requestString appendFormat:@"<string>%@</string>", param];
	}
	else if ([param isKindOfClass:[NSDictionary class]]) {
		[requestString appendString:@"<struct>"];
		NSArray* keys = [param allKeys];
		for (NSString* k in keys) {
			id val = [param objectForKey:k];
			[requestString appendString:@"<member>"];
			[requestString appendFormat:@"<name>%@</name>", k];
			[requestString appendString:@"<value>"];
			[self appendParam:val toString:requestString];
			[requestString appendString:@"</value>"];
			[requestString appendString:@"</member>"];
		}
		[requestString appendString:@"</struct>"];
	}
	else if ([param isKindOfClass:[NSArray class]]) {
		[requestString appendString:@"<array><data>"];
		for (id val in param) {
			[requestString appendString:@"<value>"];
			[self appendParam:val toString:requestString];
			[requestString appendString:@"</value>"];
		}
		[requestString appendString:@"</data></array>"];
	}
}

- (UUHttpRequest *) sendMethod:(NSString *)method params:(NSArray *)params completion:(void (^)(UUHttpResponse* response))handler
{
	NSMutableString* s = [[NSMutableString alloc] init];
	[s appendString:@"<?xml version=\"1.0\"?>"];
	[s appendFormat:@"<methodCall><methodName>%@</methodName>", method];
	[s appendString:@"<params>"];

	for (id param in params) {
		[s appendString:@"<param>"];
		[self appendParam:param toString:s];
		[s appendString:@"</param>"];
	}

	[s appendString:@"</params>"];
	[s appendString:@"</methodCall>"];

	NSData* d = [s dataUsingEncoding:NSUTF8StringEncoding];
	UUHttpRequest* request = [UUHttpRequest postRequest:self.url queryArguments:nil body:d contentType:@"text/xml"];
	return [UUHttpSession executeRequest:request completionHandler:handler];
}

- (void) processRSD:(NSArray *)dictionaryEndpoints withCompletion:(void (^)(NSString* xmlrpcEndpointURL, NSString* blogID))handler
{
	NSString* best_endpoint_url = nil;
	NSString* blog_id = nil;
	
	for (NSDictionary* api in dictionaryEndpoints) {
		if ([api[@"name"] isEqualToString:@"Blogger"]) {
			blog_id = api[@"blogID"];
			best_endpoint_url = api[@"apiLink"];
			break;
		}
	}
	
	handler (best_endpoint_url, blog_id);
}

- (RFXMLRSDParser *) parsedResponseFromData:(NSData *)data
{
	NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
	RFXMLRSDParser* rsd = [[RFXMLRSDParser alloc] init];
	parser.delegate = rsd;
	[parser parse];
	return rsd;
}

- (void) discoverEndpointWithCompletion:(void (^)(NSString* xmlrpcEndpointURL, NSString* blogID))handler
{
	[self getPath:@"/xmlrpc.php?rsd" completion:^(UUHttpResponse* response) {
		RFXMLRSDParser* rsd = [self parsedResponseFromData:response.rawResponse];
		if ([rsd.foundEndpoints count] > 0) {
			[self processRSD:rsd.foundEndpoints withCompletion:handler];
		}
		else {
			[self getPath:@"/rsd.xml" completion:^(UUHttpResponse* response) {
				RFXMLRSDParser* rsd = [self parsedResponseFromData:response.rawResponse];
				[self processRSD:rsd.foundEndpoints withCompletion:handler];
			}];
		}
	}];
}

@end
