//
//  RFUserController.m
//  Snippets
//
//  Created by Manton Reece on 11/15/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFUserController.h"

#import "RFClient.h"
#import "RFMacros.h"

@implementation RFUserController

- (instancetype) initWithEndpoint:(NSString *)endpoint username:(NSString *)username
{
	self = [super initWithEndpoint:endpoint title:username];
	if (self) {
		self.username = username;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	self.navigationItem.rightBarButtonItem = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	self.navigationItem.rightBarButtonItem = nil;
	[self checkFollowing];
}

- (void) setupNavigation
{
	[super setupNavigation];

	self.title = self.timelineTitle;
}

- (void) checkFollowing
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/users/is_following"];
	NSDictionary* args = @{
		@"username": self.username
	};
	[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
		if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			BOOL is_following = [[response.parsedResponse objectForKey:@"is_following"] boolValue];
			BOOL is_you = [[response.parsedResponse objectForKey:@"is_you"] boolValue];
			RFDispatchMain (^{
				if (is_you) {
					self.navigationItem.rightBarButtonItem = nil;
				}
				else {
					[self setupFollowing:is_following];
				}
			});
		}
	}];
}

- (void) setupFollowing:(BOOL)isFollowing
{
	if (isFollowing) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Unfollow" style:UIBarButtonItemStylePlain target:self action:@selector(unfollow:)];
	}
	else {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Follow" style:UIBarButtonItemStylePlain target:self action:@selector(follow:)];
	}
}

- (void) follow:(id)sender
{
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityView startAnimating];
    activityView.frame = CGRectMake(0, 0, 60, 40);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    
	RFClient* client = [[RFClient alloc] initWithPath:@"/users/follow"];
	NSDictionary* args = @{
		@"username": self.username
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMain (^{
			[self setupFollowing:YES];
		});
	}];
}

- (void) unfollow:(id)sender
{
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    [activityView startAnimating];
    activityView.frame = CGRectMake(0, 0, 60, 40);

	RFClient* client = [[RFClient alloc] initWithPath:@"/users/unfollow"];
	NSDictionary* args = @{
		@"username": self.username
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMain (^{
			[self setupFollowing:NO];
		});
	}];
}

@end
