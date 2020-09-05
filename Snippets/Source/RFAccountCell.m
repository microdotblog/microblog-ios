//
//  RFAccountCell.m
//  Micro.blog
//
//  Created by Manton Reece on 9/5/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFAccountCell.h"

#import "RFAccount.h"

@implementation RFAccountCell

- (void) setupWithAccount:(RFAccount *)account
{
	self.usernameField.text = [NSString stringWithFormat:@"@%@", account.username];
	self.profileImageView.layer.cornerRadius = 20;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
}

@end
