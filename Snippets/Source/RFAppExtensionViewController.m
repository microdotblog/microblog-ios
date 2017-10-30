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
	@property (nonatomic, strong) UINavigationController* postNavigationController;
@end

@implementation RFAppExtensionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	RFPostController* postController = [[RFPostController alloc] initWithAppExtensionContext:self.extensionContext];
	self.postNavigationController = [[UINavigationController alloc] initWithRootViewController:postController];
}

- (void) viewWillAppear:(BOOL)animated
{
	if (![RFSettings needsExternalBlogSetup] || [RFSettings hasSnippetsBlog])
	{
		[self presentViewController:self.postNavigationController animated:NO completion:^
		 {
		 }];
	}
	else
	{
		[UUAlertViewController setActiveViewController:self];

		[UUAlertViewController uuShowOneButtonAlert:nil message:@"You need to configure your weblog settings first. Please launch Micro.blog and sign in to your account." button:@"OK" completionHandler:^(NSInteger buttonIndex)
		 {
			 [UUAlertViewController setActiveViewController:nil];

			 [self.extensionContext completeRequestReturningItems:nil completionHandler:^(BOOL expired)
			  {
			  }];
		 }];
	}
}

@end
