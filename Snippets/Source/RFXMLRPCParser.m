//
//  RFXMLRPCParser.m
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFXMLRPCParser.h"

@implementation RFXMLRPCParser

- (instancetype) initWithResponseData:(NSData *)data
{
	self = [super init];
	if (self) {
		self.responseData = data;
	}
	
	return self;
}

@end
