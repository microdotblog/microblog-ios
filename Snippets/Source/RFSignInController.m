//
//  RFSignInController.m
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFSignInController.h"

#import "RFClient.h"
#import "RFMacros.h"
#import "UUAlert.h"

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
	
	self.title = @"Welcome";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
}

- (IBAction) finish:(id)sender
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/iphone/verify"];
	NSDictionary* args = @{
		@"token": self.tokenField.text
	};
	[client postWithObject:nil queryArguments:args completion:^(UUHttpResponse* response) {
		NSString* error = [response.parsedResponse objectForKey:@"error"];
		if (error) {
			[UIAlertView uuShowOKCancelAlert:@"Error Signing In" message:error completionHandler:NULL];
		}
		else {
			NSString* username = [response.parsedResponse objectForKey:@"username"];
			NSString* gravatar_url = [response.parsedResponse objectForKey:@"gravatar_url"];
			[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"AccountUsername"];
			[[NSUserDefaults standardUserDefaults] setObject:gravatar_url forKey:@"AccountGravatarURL"];
		
			RFDispatchMainAsync (^{
				[[NSNotificationCenter defaultCenter] postNotificationName:@"RFLoadTimelineNotification" object:self userInfo:@{
					@"token": self.tokenField.text
				}];
				[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
			});
		}
	}];
}

@end
