//
//  RFAppExtensionViewController.m
//  Micro.blog
//
//  Created by Jonathan Hays on 10/19/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFAppExtensionViewController.h"
#import "RFPostController.h"
#import "RFSettings.h"
#import "UUAlert.h"

@interface RFAppExtensionViewController ()

@end

@implementation RFAppExtensionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[UUAlertViewController setActiveViewController:self];
	
	if (![RFSettings needsExternalBlogSetup] || [RFSettings hasSnippetsBlog])
	{
		RFPostController* postController = [[RFPostController alloc] initWithAppExtensionContext:self.extensionContext];
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:postController];
		[self presentViewController:navigationController animated:NO completion:^
		{
		}];
	}
	else
	{
		[UUAlertViewController uuShowOneButtonAlert:nil message:@"You need to configure your weblog settings first. Please launch Micro.blog and sign in to your account." button:@"OK" completionHandler:^(NSInteger buttonIndex)
		{
			[self.extensionContext completeRequestReturningItems:nil completionHandler:^(BOOL expired)
			{
			}];
		}];
	}
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}

@end
