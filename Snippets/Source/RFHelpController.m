//
//  RFHelpController.m
//  Snippets
//
//  Created by Manton Reece on 8/21/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFHelpController.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"

@implementation RFHelpController

- (instancetype) init
{
	self = [super initWithNibName:@"Help" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self setupNavigation];
}

- (void) setupNavigation
{
	self.title = @"Help";

	UIViewController* root_controller = [self.navigationController.viewControllers firstObject];
	if (self.navigationController.topViewController != root_controller) {
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_backBarButtonWithTarget:self action:@selector(back:)];
	}
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) sendEmail:(id)sender
{
	NSString* subject = @"Micro.blog iOS (1.2.3, @username)";
}

- (IBAction) openHelpCenter:(id)sender
{
}

@end
