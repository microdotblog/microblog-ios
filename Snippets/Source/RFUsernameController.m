//
//  RFUsernameController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/9/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import "RFUsernameController.h"

#import "RFClient.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"
#import "UUAlert.h"
#import "RFConstants.h"
#import "UITraitCollection+Extras.h"

@implementation RFUsernameController

- (instancetype) initWithUserID:(NSString *)userID identityToken:(NSString *)identityToken
{
	self = [super initWithNibName:@"Username" bundle:nil];
	if (self) {
		self.appleUserID = userID;
		self.appleIdentityToken = identityToken;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	if (@available(iOS 13.0, *)) {
		self.modalInPresentation = YES;
	}

	[self setupNavigation];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.usernameField becomeFirstResponder];
}

- (void) setupNavigation
{
	self.title = @"Username";

	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_backBarButtonWithTarget:self action:@selector(back:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Register" style:UIBarButtonItemStylePlain target:self action:@selector(checkUsername:)];
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) checkUsername:(id)sender
{
	NSString* username = self.usernameField.text;
	if (username.length > 0) {
		[self.networkSpinner startAnimating];

		NSDictionary* params = @{
			@"username": username
		};

		RFClient* client = [[RFClient alloc] initWithPath:@"/account/check"];
		[client postWithParams:params completion:^(UUHttpResponse* response) {
			RFDispatchMain (^{
				NSString* error = [response.parsedResponse objectForKey:@"error"];
				if (error) {
					[UUAlertViewController uuShowAlertWithTitle:@"Error" message:error buttonTitle:@"OK" completionHandler:NULL];
				}
				else {
					[self register:nil];
				}
			});
		}];
	}
}

- (void) register:(id)sender
{
	NSDictionary* params = @{
		@"user_id": self.appleUserID,
		@"identity_token": self.appleIdentityToken,
		@"username": self.usernameField.text
	};
	
	RFClient* client = [[RFClient alloc] initWithPath:@"/account/apple"];
	[client postWithParams:params completion:^(UUHttpResponse* response) {
		RFDispatchMain (^{
			NSString* token = [response.parsedResponse objectForKey:@"token"];
			NSString* error = [response.parsedResponse objectForKey:@"error"];
			if (error) {
				[UUAlertViewController uuShowAlertWithTitle:@"Error" message:error buttonTitle:@"OK" completionHandler:NULL];
			}
			else {
				// sign user in
				[[NSNotificationCenter defaultCenter] postNotificationName:kUpdateSigninTokenNotification object:self userInfo:@{ kUpdateSigninTokenKey: token }];
			}
		});
	}];
}

@end
