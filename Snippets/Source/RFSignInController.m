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
#import "RFConstants.h"
#import "UUAlert.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

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

- (void) updateToken:(NSString *)appToken
{
	self.tokenField.text = appToken;
	if (appToken.length > 0) {
		[self.view endEditing:NO];
	}
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	[self finish:nil];
	return YES;
}

- (IBAction) finish:(id)sender
{
	if ([self.tokenField.text containsString:@"@"]) {
		[self sendSigninEmail];
	}
	else if (self.tokenField.text.length > 0) {
		[self verifyAppToken];
	}
}

- (void) verifyAppToken
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/iphone/verify"];
	NSDictionary* args = @{
		@"token": self.tokenField.text
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		NSString* error = [response.parsedResponse objectForKey:@"error"];
		if (error) {
			RFDispatchMainAsync (^{
				[Answers logLoginWithMethod:@"Token" success:@NO customAttributes:nil];
				[UIAlertView uuShowOneButtonAlert:@"Error Signing In" message:error button:@"OK" completionHandler:NULL];
			});
		}
		else {
			NSString* full_name = [response.parsedResponse objectForKey:@"full_name"];
			NSString* username = [response.parsedResponse objectForKey:@"username"];
			NSString* email = [response.parsedResponse objectForKey:@"email"];
			NSString* gravatar_url = [response.parsedResponse objectForKey:@"gravatar_url"];
			NSNumber* has_site = [response.parsedResponse objectForKey:@"has_site"];
			NSNumber* default_site = [response.parsedResponse objectForKey:@"default_site"];
			
			[[NSUserDefaults standardUserDefaults] setObject:full_name forKey:@"AccountFullName"];
			[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"AccountUsername"];
			[[NSUserDefaults standardUserDefaults] setObject:default_site forKey:@"AccountDefaultSite"];
			[[NSUserDefaults standardUserDefaults] setObject:email forKey:@"AccountEmail"];
			[[NSUserDefaults standardUserDefaults] setObject:gravatar_url forKey:@"AccountGravatarURL"];
			[[NSUserDefaults standardUserDefaults] setBool:[has_site boolValue] forKey:@"HasSnippetsBlog"];
		
			RFDispatchMainAsync (^{
				[Answers logLoginWithMethod:@"Token" success:@YES customAttributes:nil];
				[[NSNotificationCenter defaultCenter] postNotificationName:kLoadTimelineNotification object:self userInfo:@{
					@"token": self.tokenField.text
				}];
				[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
			});
		}
	}];
}

- (void) sendSigninEmail
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/account/signin"];
	NSDictionary* args = @{
		@"email": self.tokenField.text
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync ((^{
			NSString* error = [response.parsedResponse objectForKey:@"error"];
			if (error) {
				self.instructionsField.text = [NSString stringWithFormat:@"Error: %@", error];
			}
			else {
				self.tokenField.text = @"";
				self.instructionsField.text = @"Email sent! Check your email on this device. Look for the special link that starts with microblog://.";
			}
		}));
	}];
}

@end
