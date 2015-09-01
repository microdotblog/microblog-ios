//
//  RFXMLElementStack.m
//  Snippets
//
//  Created by Manton Reece on 9/1/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFXMLElementStack.h"

@implementation RFXMLElementStack

- (instancetype) init
{
	self = [super init];
	if (self) {
		self.stackArray = [NSMutableArray array];
	}
	
	return self;
}

- (void) push:(id)obj
{
	[self.stackArray addObject:obj];
}

- (id) pop
{
	id result = [self.stackArray lastObject];
	[self.stackArray removeLastObject];
	return result;
}

- (id) peek
{
	id result = [self.stackArray lastObject];
	return result;
}

@end
