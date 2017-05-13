//
//  RFSettings.h
//  Micro.blog
//
//  Created by Manton Reece on 5/13/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFSettings : NSObject

+ (BOOL) hasSnippetsBlog;
+ (BOOL) hasExternalBlog;
+ (BOOL) prefersExternalBlog;
+ (BOOL) needsExternalBlogSetup;

@end
