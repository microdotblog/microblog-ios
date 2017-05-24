//
//  RFFeaturedPhotoCell.m
//  Micro.blog
//
//  Created by Manton Reece on 5/23/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFFeaturedPhotoCell.h"

#import "UUImageView.h"

@implementation RFFeaturedPhotoCell

- (void) setupWithPhoto:(RFFeaturedPhoto *)photo
{
	self.usernameField.text = [NSString stringWithFormat:@"@%@", photo.username];
	[self.imageView uuLoadImageFromURL:[NSURL URLWithString:photo.imageURL] defaultImage:nil loadCompleteHandler:NULL];
}

@end
