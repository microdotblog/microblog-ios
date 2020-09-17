//
//  RFAccountCell.m
//  Micro.blog
//
//  Created by Manton Reece on 9/5/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFAccountCell.h"

#import "RFAccount.h"
#import "UUImageView.h"

@implementation RFAccountCell

- (void) awakeFromNib
{
	[super awakeFromNib];

	[self setupSelectionBackground];
}

- (void) setupSelectionBackground
{
	UIView* selected_view = [[UIView alloc] initWithFrame:self.bounds];
	selected_view.backgroundColor = [UIColor clearColor];
	self.selectedBackgroundView = selected_view;
}


- (void) setupWithAccount:(RFAccount *)account
{
	self.usernameField.text = [NSString stringWithFormat:@"@%@", account.username];
	self.profileImageView.layer.cornerRadius = 20;
	self.plusField.hidden = YES;
	self.plusImageField.hidden = YES;

	NSString* avatar_url = [account profileURL];
	[self.profileImageView uuLoadImageFromURL:[NSURL URLWithString:avatar_url] defaultImage:nil loadCompleteHandler:NULL];
}

- (void) setupForNewButton
{
	self.usernameField.text = @"";
	self.profileImageView.backgroundColor = [UIColor colorNamed:@"color_plus_background"];
	self.profileImageView.layer.cornerRadius = 20;
	
	if (@available(iOS 13.0, *)) {
		self.plusField.hidden = YES;
		self.plusImageField.hidden = NO;
	}
	else {
		self.plusField.hidden = NO;
		self.plusImageField.hidden = YES;
	}
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
}

@end
