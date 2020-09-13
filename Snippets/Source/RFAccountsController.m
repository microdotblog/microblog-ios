//
//  RFAccountsController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/4/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFAccountsController.h"

#import "RFAccount.h"
#import "RFAccountCell.h"
#import "RFConstants.h"
#import "RFSettings.h"
#import "UUAlert.h"

static NSString* const kAccountCellIdentifier = @"AccountCell";

@implementation RFAccountsController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.containerView.layer.cornerRadius = 10;
	self.accounts = [RFAccount allAccounts];
}

- (IBAction) close:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction) signOut:(id)sender
{
	[UUAlertViewController uuShowTwoButtonAlert:@"Sign out of Micro.blog?" message:@"Signing out will reset your settings and let you sign in with a new account or different microblog." buttonOne:@"Cancel" buttonTwo:@"Sign Out" completionHandler:^(NSInteger buttonIndex) {
		if (buttonIndex == 1) {
			[RFSettings clearAllSettings];
			[[NSNotificationCenter defaultCenter] postNotificationName:kShowSigninNotification object:self];
		}
	}];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.accounts count] + 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFAccountCell* cell = [tableView dequeueReusableCellWithIdentifier:kAccountCellIdentifier forIndexPath:indexPath];
	
	if (indexPath.row < [self.accounts count]) {
		RFAccount* a = [self.accounts objectAtIndex:indexPath.row];
		[cell setupWithAccount:a];
	}
	else {
		[cell setupForNewButton];
	}
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < [self.accounts count]) {
		// switch account
		RFAccount* a = [self.accounts objectAtIndex:indexPath.row];
		[a setDefault];
		[self dismissViewControllerAnimated:YES completion:^{
			[[NSNotificationCenter defaultCenter] postNotificationName:kRefreshUserNotification object:self];
		}];
	}
	else {
		// prompt to sign in to new account
		[self dismissViewControllerAnimated:YES completion:^{
			[[NSNotificationCenter defaultCenter] postNotificationName:kShowSigninNotification object:self];
		}];
	}
}

@end
