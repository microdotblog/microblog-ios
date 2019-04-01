//
//  RFUpgradeController.m
//  Micro.blog
//
//  Created by Manton Reece on 4/1/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import "RFUpgradeController.h"

#import "RFClient.h"
#import "RFSettings.h"

@implementation RFUpgradeController

- (id) init
{
	self = [super initWithNibName:@"Upgrade" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.containerView.layer.cornerRadius = 15.0;
	self.blogField.text = [NSString stringWithFormat:@"Blog: %@", [RFSettings accountDefaultSite]];
}

- (IBAction) cancel:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction) upgrade:(id)sender
{
	[self.progressSpinner startAnimating];

	NSString* uid = [RFSettings accountDefaultSite];
	NSString* sitename = [uid stringByReplacingOccurrencesOfString:@".micro.blog" withString:@""];

	sitename = [sitename stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	sitename = [sitename stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	sitename = [sitename stringByReplacingOccurrencesOfString:@"/" withString:@""];

	NSDictionary* params = @{
		@"sitename": sitename,
		@"theme": @"default",
		@"plan": @"site10"
	};

	RFClient* client = [[RFClient alloc] initWithPath:@"/account/charge/site"];
	[client postWithParams:params completion:^(UUHttpResponse* response) {
		dispatch_async (dispatch_get_main_queue(), ^{
			if (response.httpError) {
				[self showError:[response.httpError localizedDescription]];
			}
			else {
				if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
					NSString* error = [response.parsedResponse objectForKey:@"error"];
					if (error) {
						[self showError:error];
					}
					else {
						self.canUpload = YES;
						[self cancel:nil];
					}
				}
				else {
					[self showError:@"Unknown error upgrading microblog."];
				}
			}
		});
	}];
}

- (void) showError:(NSString *)error
{
}

@end
