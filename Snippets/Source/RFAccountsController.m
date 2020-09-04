//
//  RFAccountsController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/4/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFAccountsController.h"

@implementation RFAccountsController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.containerView.layer.cornerRadius = 10;
}

- (IBAction) close:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction) newAccount:(id)sender
{
}

@end
