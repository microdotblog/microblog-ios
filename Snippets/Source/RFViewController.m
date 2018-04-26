//
//  RFViewController.m
//  Micro.blog
//
//  Created by Jonathan Hays on 4/26/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFConstants.h"

@interface RFViewController ()

@end

@implementation RFViewController

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(microblogConfigured:) name:kMicroblogSelectNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kMicroblogSelectNotification object:nil];
}

- (void) microblogConfigured:(NSNotification*)notification
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Blogs" bundle:nil];
	UIViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"BlogsNavigation"];
	[self presentViewController:controller animated:YES completion:NULL];
}

@end
