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
		[UUAlertViewController uuShowTwoButtonAlert:nil message:@"You need to setup your Micro.blog account first. Would you like to do that now?" buttonOne:@"Cancel" buttonTwo:@"Setup" completionHandler:^(NSInteger buttonIndex)
		{
			if (buttonIndex > 0)
			{
				[self.extensionContext openURL:[NSURL URLWithString:@"microblog"] completionHandler:^(BOOL success)
				{
				}];
			}
			else
			{
				[self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
			}
		}];
	}
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}

@end
