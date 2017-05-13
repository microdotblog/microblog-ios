//
//  RFSettings.m
//  Micro.blog
//
//  Created by Manton Reece on 5/13/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFSettings.h"

@implementation RFSettings

+ (BOOL) hasSnippetsBlog
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"HasSnippetsBlog"];
}

+ (BOOL) hasExternalBlog
{
	NSString* blog_username = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogUsername"];
	NSString* micropub_me = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubMe"];
	return (blog_username.length > 0) || (micropub_me.length > 0);
}

+ (BOOL) prefersExternalBlog
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"ExternalBlogIsPreferred"];
}

+ (BOOL) needsExternalBlogSetup
{
	return (![self hasSnippetsBlog] && ![self hasExternalBlog]) || ([self prefersExternalBlog] && ![self hasExternalBlog]);
}

@end
