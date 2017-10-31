//
//  RFSettings.m
//  Micro.blog
//
//  Created by Manton Reece on 5/13/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFSettings.h"
#import "SSKeychain.h"

#define kSharedGroupDefaults			@"group.blog.micro.ios"

#define ExternalBlogFormat 				@"ExternalBlogFormat"
#define ExternalMicropubTokenEndpoint 	@"ExternalMicropubTokenEndpoint"
#define ExternalMicropubState			@"ExternalMicropubState"
#define ExternalBlogApp					@"ExternalBlogApp"
#define ExternalBlogCategory			@"ExternalBlogCategory"
#define ExternalBlogFormat				@"ExternalBlogFormat"
#define ExternalBlogUsername			@"ExternalBlogUsername"
#define ExternalBlogID					@"ExternalBlogID"
#define ExternalMicropubMediaEndpoint	@"ExternalMicropubMediaEndpoint"
#define ExternalMicropubPostingEndpoint	@"ExternalMicropubPostingEndpoint"
#define ExternalBlogEndpoint			@"ExternalBlogEndpoint"
#define ExternalMicropubMe				@"ExternalMicropubMe"
#define AccountDefaultSite				@"AccountDefaultSite"
#define PlainSharedURLsPreferred		@"PlainSharedURLsPreferred"
#define ExternalBlogIsPreferred			@"ExternalBlogIsPreferred"
#define HasSnippetsBlog					@"HasSnippetsBlog"
#define AccountUsername					@"AccountUsername"
#define AccountEmail					@"AccountEmail"
#define AccountFullName					@"AccountFullName"
#define AccountGravatarURL				@"AccountGravatarURL"
#define IsFullAccess					@"IsFullAccess"
#define LatestDraftTitle				@"LatestDraftTitle"
#define LatestDraftText					@"LatestDraftText"
#define PreferredContentSize			@"PreferredContentSize"

@implementation RFSettings

+ (void) setUserDefault:(NSObject*)object forKey:(NSString*)key
{
	[[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
	NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: kSharedGroupDefaults];
	[sharedDefaults setObject:object forKey:key];
	
	[sharedDefaults synchronize];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*) loadUserDefault:(NSString*)name
{
	NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: kSharedGroupDefaults];
	NSString* value = [sharedDefaults objectForKey:name];
	if (!value)
	{
		value = [[NSUserDefaults standardUserDefaults] objectForKey:name];
		[sharedDefaults setObject:value forKey:name];
		[sharedDefaults synchronize];
	}
	
	return value;
}

+ (BOOL) loadUserDefaultBool:(NSString*)name
{
	NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: kSharedGroupDefaults];
	NSNumber* value = [sharedDefaults objectForKey:name];
	
	if (!value)
	{
		value = [[NSUserDefaults standardUserDefaults] objectForKey:name];
		[sharedDefaults setObject:value forKey:name];
		[sharedDefaults synchronize];
	}
	
	return value.boolValue;
}

+ (void) removeObjectForKey:(NSString*)key
{
	NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: kSharedGroupDefaults];
	[sharedDefaults removeObjectForKey:key];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
	
	[sharedDefaults synchronize];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////


+ (BOOL) hasSnippetsBlog
{
	return [RFSettings loadUserDefaultBool:HasSnippetsBlog];
}

+ (void) setHasSnippetsBlog:(BOOL)value
{
	[RFSettings setUserDefault:@(value) forKey:HasSnippetsBlog];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) hasExternalBlog
{
	NSString* blog_username = [RFSettings externalBlogUsername];
	NSString* micropub_me = [RFSettings externalMicropubMe];
	return (blog_username.length > 0) || (micropub_me.length > 0);
}

+ (BOOL) hasMicropubBlog
{
	return ([RFSettings externalMicropubMe] != nil);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) prefersExternalBlog
{
	return [RFSettings loadUserDefaultBool:ExternalBlogIsPreferred];
}

+ (void) setPrefersExternalBlog:(BOOL)value
{
	[RFSettings setUserDefault:@(value) forKey:ExternalBlogIsPreferred];
}

+ (BOOL) prefersPlainSharedURLs
{
	return [RFSettings loadUserDefaultBool:PlainSharedURLsPreferred];
}

+ (void) setPrefersPlainSharedURLs:(BOOL)value
{
	[RFSettings setUserDefault:@(value) forKey:PlainSharedURLsPreferred];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) needsExternalBlogSetup
{
	return (![self hasSnippetsBlog] && ![self hasExternalBlog]) || ([self prefersExternalBlog] && ![self hasExternalBlog]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) snippetsPassword
{
	return [SSKeychain passwordForService:@"Snippets" account:@"default"];
}

+ (void) setSnippetsPassword:(NSString*)password
{
	[SSKeychain setPassword:password forService:@"Snippets" account:@"default"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) snippetsUsername
{
	return [RFSettings loadUserDefault:AccountUsername];
}

+ (void) setSnippetsUsername:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:AccountUsername];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) accountDefaultSite
{
	return [RFSettings loadUserDefault:AccountDefaultSite];
}

+ (void) setAccountDefaultSite:(NSString*)endpoint
{
	[RFSettings setUserDefault:endpoint forKey:AccountDefaultSite];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////


+ (NSString*) externalMicropubMe
{
	return [RFSettings loadUserDefault:ExternalMicropubMe];
}

+ (void) setExternalMicropubMe:(NSString*)endpoint
{
	[RFSettings setUserDefault:endpoint forKey:ExternalMicropubMe];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) externalBlogEndpoint
{
	return [RFSettings loadUserDefault:ExternalBlogEndpoint];
}

+ (void) setExternalBlogEndpoint:(NSString*)endpoint
{
	[RFSettings setUserDefault:endpoint forKey:ExternalBlogEndpoint];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) externalMicropubPostingEndpoint
{
	return [RFSettings loadUserDefault:ExternalMicropubPostingEndpoint];
}

+ (void) setExternalMicropubPostingEndpoint:(NSString*)endpoint
{
	[RFSettings setUserDefault:endpoint forKey:ExternalMicropubPostingEndpoint];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) externalMicropubMediaEndpoint
{
	return [RFSettings loadUserDefault:ExternalMicropubMediaEndpoint];
}

+ (void) setExternalMicropubMediaEndpoint:(NSString*)endpoint
{
	[RFSettings setUserDefault:endpoint forKey:ExternalMicropubMediaEndpoint];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) externalBlogID
{
	return [RFSettings loadUserDefault:ExternalBlogID];
}

+ (void) setExternalBlogID:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:ExternalBlogID];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) externalBlogUsername
{
	return [RFSettings loadUserDefault:ExternalBlogUsername];
}

+ (void) setExternalBlogUsername:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:ExternalBlogUsername];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) externalBlogFormat
{
	return [RFSettings loadUserDefault:ExternalBlogFormat];
}

+ (void) setExternalBlogFormat:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:ExternalBlogFormat];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) externalBlogCategory
{
	return [RFSettings loadUserDefault:ExternalBlogCategory];
}

+ (void) setExternalBlogCategory:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:ExternalBlogCategory];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) externalBlogPassword
{
	NSString* password = [SSKeychain passwordForService:@"ExternalBlog" account:@"default"];
	return password;
}

+ (void) setExternalBlogPassword:(NSString *)value
{
	[SSKeychain setPassword:value forService:@"ExternalBlog" account:@"default"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) externalBlogUsesWordPress
{
	return ([[RFSettings loadUserDefault:ExternalBlogApp] isEqualToString:@"WordPress"]);
}

+ (NSString*) externalBlogApp
{
	return [RFSettings loadUserDefault:ExternalBlogApp];
}

+ (void) setExternalBlogApp:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:ExternalBlogApp];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) externalMicropubState
{
	return [RFSettings loadUserDefault:ExternalMicropubState];
}

+ (void) setExternalMicropubState:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:ExternalMicropubState];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) externalMicropubTokenEndpoint
{
	return [RFSettings loadUserDefault:ExternalMicropubTokenEndpoint];
}

+ (void) setExternalMicropubTokenEndpoint:(NSString*)endpoint
{
	[RFSettings setUserDefault:endpoint forKey:ExternalMicropubTokenEndpoint];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) snippetsAccountFullName
{
	return [RFSettings loadUserDefault:AccountFullName];
}

+ (void) setSnippetsAccountFullName:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:AccountFullName];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) snippetsAccountEmail
{
	return [RFSettings loadUserDefault:AccountEmail];
}

+ (void) setSnippetsAccountEmail:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:AccountEmail];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString*) snippetsGravatarURL
{
	return [RFSettings loadUserDefault:AccountGravatarURL];
}

+ (void) setSnippetsGravatarURL:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:AccountGravatarURL];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) isSnippetsFullAccess
{
	return [RFSettings loadUserDefaultBool:IsFullAccess];
}

+ (void) setSnippetsFullAccess:(BOOL)fullAccess
{
	[RFSettings setUserDefault:@(fullAccess) forKey:IsFullAccess];
}


+ (void) clearAllSettings
{
	[RFSettings removeObjectForKey:AccountUsername];
	[RFSettings removeObjectForKey:AccountGravatarURL];
	[RFSettings removeObjectForKey:AccountDefaultSite];

	[RFSettings removeObjectForKey:HasSnippetsBlog];
	[RFSettings removeObjectForKey:PlainSharedURLsPreferred];

	[RFSettings removeObjectForKey:ExternalBlogUsername];
	[RFSettings removeObjectForKey:ExternalBlogApp];
	[RFSettings removeObjectForKey:ExternalBlogEndpoint];
	[RFSettings removeObjectForKey:ExternalBlogID];
	[RFSettings removeObjectForKey:ExternalBlogIsPreferred];

	[RFSettings removeObjectForKey:ExternalMicropubMe];
	[RFSettings removeObjectForKey:ExternalMicropubTokenEndpoint];
	[RFSettings removeObjectForKey:ExternalMicropubPostingEndpoint];
	[RFSettings removeObjectForKey:ExternalMicropubMediaEndpoint];
	[RFSettings removeObjectForKey:ExternalMicropubState];

	[SSKeychain deletePasswordForService:@"Snippets" account:@"default"];
	[SSKeychain deletePasswordForService:@"ExternalBlog" account:@"default"];
	[SSKeychain deletePasswordForService:@"MicropubBlog" account:@"default"];
}

+ (void) migrateAllKeys
{
	[RFSettings migrateValueForKey:ExternalBlogFormat];
	[RFSettings migrateValueForKey:ExternalMicropubTokenEndpoint];
	[RFSettings migrateValueForKey:ExternalMicropubState];
	[RFSettings migrateValueForKey:ExternalBlogApp];
	[RFSettings migrateValueForKey:ExternalBlogCategory];
	[RFSettings migrateValueForKey:ExternalBlogFormat];
	[RFSettings migrateValueForKey:ExternalBlogUsername];
	[RFSettings migrateValueForKey:ExternalBlogID];
	[RFSettings migrateValueForKey:ExternalMicropubMediaEndpoint];
	[RFSettings migrateValueForKey:ExternalMicropubPostingEndpoint];
	[RFSettings migrateValueForKey:ExternalBlogEndpoint];
	[RFSettings migrateValueForKey:ExternalMicropubMe];
	[RFSettings migrateValueForKey:AccountDefaultSite];
	[RFSettings migrateValueForKey:ExternalBlogIsPreferred];
	[RFSettings migrateValueForKey:HasSnippetsBlog];
	[RFSettings migrateValueForKey:AccountUsername];
	[RFSettings migrateValueForKey:AccountEmail];
	[RFSettings migrateValueForKey:AccountFullName];
	[RFSettings migrateValueForKey:AccountGravatarURL];
	[RFSettings migrateValueForKey:IsFullAccess];
}

+ (void) migrateValueForKey:(NSString*)key
{
	NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: kSharedGroupDefaults];
	NSObject* object = [[NSUserDefaults standardUserDefaults] objectForKey:key];
	[sharedDefaults setObject:object forKey:key];
	[sharedDefaults synchronize];
}

+ (NSString *) draftTitle
{
	NSString* s = [RFSettings loadUserDefault:LatestDraftTitle];
	if (s == nil) {
		s = @"";
	}
	
	return s;
}

+ (NSString *) draftText
{
	NSString* s = [RFSettings loadUserDefault:LatestDraftText];
	if (s == nil) {
		s = @"";
	}
	
	return s;
}

+ (void) setDraftTitle:(NSString *)value
{
	[RFSettings setUserDefault:value forKey:LatestDraftTitle];
}

+ (void) setDraftText:(NSString *)value
{
	[RFSettings setUserDefault:value forKey:LatestDraftText];
}

+ (NSString *) preferredContentSize
{
	return [RFSettings loadUserDefault:PreferredContentSize];
}

+ (void) setPreferredContentSize:(NSString *)value
{
	[RFSettings setUserDefault:value forKey:PreferredContentSize];
}

@end
