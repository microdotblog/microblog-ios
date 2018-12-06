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
#import "RFSettings.h"
#import "UUAlert.h"
#import "UILabel+MarkupExtensions.h"
#import "UIView+Extras.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "SSKeychain.h"
#import "RFAutoCompleteCache.h"

@import UserNotifications;

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
	if (appToken.length > 0) {
		RFDispatchSeconds (0.5, ^{
			self.tokenField.text = appToken;
			[self.view endEditing:NO];
			[self verifyAppToken];
		});
	}
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	[self finish:nil];
	return YES;
}

- (IBAction) finish:(id)sender
{
	if (self.tokenField.text.length > 0) {
		[self.networkSpinner startAnimating];
		
		if ([self.tokenField.text containsString:@"@"]) {
			[self sendSigninEmail];
		}
		else {
			[self verifyAppToken];
		}
	}
}

- (void) showMessage:(NSString *)message
{
	self.messageField.text = message;

//	if ([message containsString:@"Error"]) {
//		self.messageContainer.backgroundColor = [UIColor colorWithWhite:0.972 alpha:1.0];
//	}
//	else {
//		self.messageContainer.backgroundColor = [UIColor colorWithRed:0.875 green:0.941 blue:0.847 alpha:1.0];
//	}
	
	if (self.messageContainer.alpha == 0.0) {
		[UIView animateWithDuration:0.3 animations:^{
			self.messageTopConstraint.constant = 44 + [self.view rf_statusBarHeight];
			self.messageContainer.alpha = 1.0;
			[self.view layoutIfNeeded];
		}];
	}

	[self.networkSpinner stopAnimating];
}

- (void) verifyAppToken
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/account/verify"];
	NSString* token = self.tokenField.text;
	NSDictionary* args = @{
		@"token": token
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		NSString* error = [response.parsedResponse objectForKey:@"error"];
		if (error) {
			RFDispatchMainAsync ((^{
				[Answers logLoginWithMethod:@"Token" success:@NO customAttributes:nil];
				[self showMessage:[NSString stringWithFormat:@"Error signing in: %@", error]];
			}));
		}
		else {
			NSString* full_name = [response.parsedResponse objectForKey:@"full_name"];
			NSString* username = [response.parsedResponse objectForKey:@"username"];
			NSString* email = [response.parsedResponse objectForKey:@"email"];
			NSString* gravatar_url = [response.parsedResponse objectForKey:@"gravatar_url"];
			NSNumber* has_site = [response.parsedResponse objectForKey:@"has_site"];
			NSNumber* is_fullaccess = [response.parsedResponse objectForKey:@"is_fullaccess"];
			NSString* default_site = [response.parsedResponse objectForKey:@"default_site"];
			
			[RFSettings setSnippetsAccountFullName:full_name];
			[RFSettings setSnippetsUsername:username];
			[RFSettings setAccountDefaultSite:default_site];
			[RFSettings setSnippetsAccountEmail:email];
			[RFSettings setSnippetsGravatarURL:gravatar_url];
			[RFSettings setHasSnippetsBlog:[has_site boolValue]];
			[RFSettings setSnippetsFullAccess:[is_fullaccess boolValue]];
			[SSKeychain setPassword:token forService:@"Snippets" account:@"default"];

			[self checkForMultipleBlogs];
		}
	}];
}

- (void) setupFollowerAutoComplete
{
	NSString* username = [RFSettings snippetsUsername];
	if (username == nil) {
		return;
	}
	
	NSString* path = [NSString stringWithFormat:@"/users/following/%@", username];
	RFClient* client = [[RFClient alloc] initWithPath:path];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse *response)
	{
		// We didn't get a valid response...
		if (response.httpResponse.statusCode < 200 || response.httpResponse.statusCode > 299)
		{
			return;
		}
		
		NSArray* array = response.parsedResponse;
		if (array && [array isKindOfClass:[NSArray class]])
		{
 			for (NSDictionary* dictionary in array)
			{
				NSString* username = dictionary[@"username"];
				if (username)
				{
					[RFAutoCompleteCache addAutoCompleteString:username];
				}
			}
		}
	}];
}

- (void) completeLoginProcess
{
	RFDispatchMainAsync (^{
		[Answers logLoginWithMethod:@"Token" success:@YES customAttributes:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kLoadTimelineNotification object:self userInfo:@{
			@"token": self.tokenField.text
		}];
		[self.presentingViewController dismissViewControllerAnimated:YES completion:^{

			// After login, pre-populate the auto-complete cache...
			[self setupFollowerAutoComplete];

			//Now that we're logged in, request push tokens...
			UNAuthorizationOptions options = UNAuthorizationOptionBadge | UNAuthorizationOptionAlert | UNAuthorizationOptionSound;
			[[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error)
			{
				dispatch_async(dispatch_get_main_queue(), ^
				{
					[UIApplication.sharedApplication registerForRemoteNotifications];
				});
			}];
		}];
	});
}

- (void) checkForMultipleBlogs
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub?q=config"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response)
	{
		NSArray* blogs = [response.parsedResponse objectForKey:@"destination"];
		[[NSUserDefaults standardUserDefaults] setObject:blogs forKey:@"Micro.blog list"];

		if (blogs.count > 0)
		{
			if (blogs.count > 1)
			{
				UIViewController* savedParent = self.presentingViewController;
				dispatch_async(dispatch_get_main_queue(), ^
				{
					[Answers logLoginWithMethod:@"Token" success:@YES customAttributes:nil];
					[[NSNotificationCenter defaultCenter] postNotificationName:kLoadTimelineNotification object:self userInfo:@{ @"token": self.tokenField.text }];
					[self.presentingViewController dismissViewControllerAnimated:NO completion:^
					{
						UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Blogs" bundle:nil];
						UIViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"BlogsNavigation"];
						[savedParent presentViewController:controller animated:NO completion:NULL];
					}];
				});
			}
			else
			{
				NSDictionary* blogInfo = blogs.firstObject;
				[RFSettings setSelectedBlogInfo:blogInfo];
				[self completeLoginProcess];
			}
		}
		else
		{
			[self completeLoginProcess];
		}
	}];
}

- (void) sendSigninEmail
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/account/signin"];
	NSDictionary* args = @{
		@"email": self.tokenField.text,
		@"is_mobile": @"1"
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync ((^{
			NSString* error = [response.parsedResponse objectForKey:@"error"];
			if (error) {
				[self showMessage:[NSString stringWithFormat:@"Error signing in: %@", error]];
			}
			else {
				self.tokenField.text = @"";
				[self showMessage:@"Email sent! Check your email on this device and tap the \"Open in Micro.blog on iOS\" button."];
			}
		}));
	}];
}

@end
