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

- (IBAction) newAccount:(id)sender
{
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
