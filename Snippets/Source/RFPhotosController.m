//
//  RFPhotosController.m
//  Micro.blog
//
//  Created by Manton Reece on 3/22/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFPhotosController.h"

@implementation RFPhotosController

- (id) init
{
	self = [super initWithNibName:@"Photos" bundle:nil];
	if (self) {
		self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
}

- (IBAction) closePhotos:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
