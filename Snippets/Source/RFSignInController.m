//
//  RFSignInController.m
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFSignInController.h"

@implementation RFSignInController

- (instancetype) init
{
	self = [super initWithNibName:@"SignIn" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Sign In";
}

@end
