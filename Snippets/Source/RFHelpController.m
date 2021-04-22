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
#import "RFSettings.h"

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
	[self setupButtons];
}

- (void) setupNavigation
{
	self.title = @"Help";

	UIViewController* root_controller = [self.navigationController.viewControllers firstObject];
	if (self.navigationController.topViewController != root_controller) {
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_backBarButtonWithTarget:self action:@selector(back:)];
	}
}

- (void) setupButtons
{
	self.emailButton.layer.cornerRadius = 5;
	self.helpButton.layer.cornerRadius = 5;
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) sendEmail:(id)sender
{
	if (![MFMailComposeViewController canSendMail]) {
		return;
	}

	NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
	NSString* version = [info objectForKey:@"CFBundleShortVersionString"];
	NSString* username = [RFSettings snippetsUsername];
	
	NSString* subject = [NSString stringWithFormat:@"Micro.blog iOS (%@, @%@)", version, username];

	MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
	controller.mailComposeDelegate = self;
	 
	[controller setToRecipients:@[@"help@micro.blog"]];
	[controller setSubject:subject];
	 
	[self presentViewController:controller animated:YES completion:NULL];
}

- (IBAction) openHelpCenter:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://help.micro.blog/"] options:@{} completionHandler:NULL];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end
