//
//  RFUsernameController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/9/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import "RFUsernameController.h"

@implementation RFUsernameController

- (instancetype) init
{
	self = [super initWithNibName:@"Username" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Username";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Register" style:UIBarButtonItemStylePlain target:self action:@selector(register:)];
}

- (void) register:(id)sender
{
	[self.networkSpinner startAnimating];
}

@end
