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
	return [self.accounts count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFAccountCell* cell = [tableView dequeueReusableCellWithIdentifier:kAccountCellIdentifier forIndexPath:indexPath];
	
	RFAccount* a = [self.accounts objectAtIndex:indexPath.row];
	[cell setupWithAccount:a];
	
	return cell;
}

@end
