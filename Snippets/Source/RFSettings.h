//
//  RFSettings.h
//  Micro.blog
//
//  Created by Manton Reece on 5/13/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFSettings : NSObject

+ (void) clearAllSettings; //BE VERY CAREFUL WITH THIS!!!

+ (BOOL) hasExternalBlog;
+ (BOOL) hasMicropubBlog;
+ (BOOL) needsExternalBlogSetup;

+ (BOOL) 		prefersPlainSharedURLs;
+ (BOOL) 		prefersExternalBlog;
+ (void) 		setPrefersPlainSharedURLs:(BOOL)value;
+ (void) 		setPrefersExternalBlog:(BOOL)value;
+ (NSString*) 	accountDefaultSite;

//Snippets specific settings
+ (BOOL) 		hasSnippetsBlog;
+ (NSString*) 	snippetsUsername;
+ (NSString*) 	snippetsPassword;
+ (NSString*) 	snippetsAccountEmail;
+ (NSString*) 	snippetsAccountFullName;
+ (NSString*) 	snippetsGravatarURL;
+ (BOOL) 		isSnippetsFullAccess;
+ (void) 		setHasSnippetsBlog:(BOOL)value;
+ (void)		setSnippetsUsername:(NSString*)username;
+ (void) 		setSnippetsPassword:(NSString*)password;
+ (void) 		setAccountDefaultSite:(NSString*)value;
+ (void) 		setSnippetsAccountEmail:(NSString*)value;
+ (void) 		setSnippetsAccountFullName:(NSString*)value;
+ (void) 		setSnippetsGravatarURL:(NSString*)value;
+ (void) 		setSnippetsFullAccess:(BOOL)fullAccess;

//External Blog settings
+ (NSString*) 	externalBlogEndpoint;
+ (NSString*) 	externalBlogID;
+ (NSString*) 	externalBlogUsername;
+ (NSString*) 	externalBlogPassword;
+ (NSString*) 	externalBlogCategory;
+ (NSString*) 	externalBlogFormat;
+ (NSString*) 	externalBlogApp;
+ (BOOL) 		externalBlogUsesWordPress;

+ (void) 		setExternalBlogEndpoint:(NSString*)value;
+ (void) 		setExternalBlogID:(NSString*)value;
+ (void) 		setExternalBlogUsername:(NSString*)value;
+ (void) 		setExternalBlogPassword:(NSString*)value;
+ (void) 		setExternalBlogCategory:(NSString*)value;
+ (void) 		setExternalBlogFormat:(NSString*)value;
+ (void) 		setExternalBlogApp:(NSString*)value;

//Micropub specific settings
+ (NSString*) 	externalMicropubMe;
+ (NSString*) 	externalMicropubPostingEndpoint;
+ (NSString*) 	externalMicropubMediaEndpoint;
+ (NSString*) 	externalMicropubState;
+ (NSString*) 	externalMicropubTokenEndpoint;
+ (void) 		setExternalMicropubMe:(NSString*)value;
+ (void) 		setExternalMicropubPostingEndpoint:(NSString*)value;
+ (void) 		setExternalMicropubMediaEndpoint:(NSString*)value;
+ (void) 		setExternalMicropubState:(NSString*)value;
+ (void) 		setExternalMicropubTokenEndpoint:(NSString*)value;

//Drafts
+ (NSString *)	draftTitle;
+ (NSString *)	draftText;
+ (void)		setDraftTitle:(NSString *)value;
+ (void)		setDraftText:(NSString *)value;

+ (NSString *)  preferredContentSize;
+ (void)  		setPreferredContentSize:(NSString *)value;

+ (void) migrateAllKeys;

@end
