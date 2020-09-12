//
//  RFReaderController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFReaderController.h"

#import "RFAccount.h"

@implementation RFReaderController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	NSString* url = @"http://localhost:3000/bookmarks/123";
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	
	RFAccount* a = [RFAccount defaultAccount];
	if (a) {
		NSString* token = [a password];
		if (token) {
			token = @"A408F6AB53A3F59F12E4"; // testing localhost
			NSString* auth = [NSString stringWithFormat:@"Bearer %@", token];
			[request addValue:auth forHTTPHeaderField:@"Authorization"];
		}
	}
	
	[self.webView loadRequest:request];
}

@end
