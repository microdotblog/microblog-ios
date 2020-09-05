//
//  RFSettings.m
//  Micro.blog
//
//  Created by Manton Reece on 5/13/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFSettings.h"
#import "SSKeychain.h"
#import "RFConstants.h"

// external settings are global regardless of current account
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
#define ExternalBlogIsPreferred			@"ExternalBlogIsPreferred"

// more global prefs
#define LatestDraftTitle				@"LatestDraftTitle"
#define LatestDraftText					@"LatestDraftText"
#define PreferredContentSize			@"PreferredContentSize"
#define PlainSharedURLsPreferred		@"PlainSharedURLsPreferred"
#define kLastStatusBarHeightPrefKey		@"LastStatusBarHeight"

// this is the current account
#define AccountUsername					@"AccountUsername"

// all configured accounts
#define AccountUsernames				@"AccountUsernames"

// updated based on current account (and have _username variants)
#define AccountFullName					@"AccountFullName"
#define AccountDefaultSite				@"AccountDefaultSite"
#define HasSnippetsBlog					@"HasSnippetsBlog"
#define SelectedBlogInfo				@"Microblog::SelectedBlog"
#define BlogList						@"Micro.blog list"

@implementation RFSettings

+ (void) setUserDefault:(NSObject*)object forKey:(NSString*)key
{
	[[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
	NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: kSharedGroupDefaults];
	[sharedDefaults setObject:object forKey:key];
	
	[sharedDefaults synchronize];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void) setUserDefault:(NSObject*)object forKey:(NSString*)key useCurrentUser:(BOOL)useCurrentUser
{
	NSString* s = [self makeKey:key useCurrentUser:useCurrentUser];
	[self setUserDefault:object forKey:s];
}

+ (NSString *) makeKey:(NSString *)key useCurrentUser:(BOOL)useCurrentUser
{
	NSString* s = key;
	if (useCurrentUser) {
		NSString* username = [self snippetsUsername];
		if (username) {
			s = [NSString stringWithFormat:@"%@_%@", key, username];
		}
	}
	
	return s;
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

+ (NSString*) loadUserDefault:(NSString*)name useCurrentUser:(BOOL)useCurrentUser
{
	NSString* s = [self makeKey:name useCurrentUser:useCurrentUser];
	return [self loadUserDefault:s];
}

+ (NSArray*) loadUserDefaultArray:(NSString*)name
{
	NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: kSharedGroupDefaults];
	NSArray* value = [sharedDefaults objectForKey:name];
	if (!value)
	{
		value = [[NSUserDefaults standardUserDefaults] objectForKey:name];
		[sharedDefaults setObject:value forKey:name];
		[sharedDefaults synchronize];
	}
	
	return value;
}

+ (NSArray*) loadUserDefaultArray:(NSString*)name useCurrentUser:(BOOL)useCurrentUser
{
	NSString* s = [self makeKey:name useCurrentUser:useCurrentUser];
	return [self loadUserDefaultArray:s];
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

+ (NSDictionary*) loadUserDefaultDictionary:(NSString*)name
{
	NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: kSharedGroupDefaults];
	NSDictionary* dictionary = [sharedDefaults objectForKey:name];
	return dictionary;
}

+ (void) removeObjectForKey:(NSString*)key
{
	NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: kSharedGroupDefaults];
	[sharedDefaults removeObjectForKey:key];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
	
	[sharedDefaults synchronize];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void) removeObjectForKey:(NSString*)key username:(NSString *)username
{
	NSString* s = [NSString stringWithFormat:@"%@_%@", key, username];
	[self removeObjectForKey:s];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////


+ (BOOL) hasSnippetsBlog
{
	return [RFSettings loadUserDefaultBool:HasSnippetsBlog];
}

+ (void) setHasSnippetsBlog:(BOOL)value
{
	[RFSettings setUserDefault:@(value) forKey:HasSnippetsBlog useCurrentUser:YES];
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
	return [self snippetsPasswordForCurrentUser:YES];
}

+ (NSString*) snippetsPasswordForCurrentUser:(BOOL)useCurrentUser
{
	NSString* s = @"default";
	if (useCurrentUser) {
		NSString* username = [self snippetsUsername];
		if (username) {
			s = username;
		}
	}

	return [SSKeychain passwordForService:@"Snippets" account:s];
}

+ (void) setSnippetsPassword:(NSString*)password
{
	[self setSnippetsPassword:password useCurrentUser:NO];
}

+ (void) setSnippetsPassword:(NSString*)password useCurrentUser:(BOOL)useCurrentUser
{
	NSString* s = @"default";
	if (useCurrentUser) {
		NSString* username = [self snippetsUsername];
		if (username) {
			s = username;
		}
	}
	
	[SSKeychain setPassword:password forService:@"Snippets" account:s];
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
	[RFSettings setUserDefault:endpoint forKey:AccountDefaultSite useCurrentUser:YES];
}

+ (NSArray *) accountsUsernames
{
	return [self loadUserDefaultArray:AccountUsernames];
}

+ (void) setAccountUsernames:(NSArray *)usernames
{
	[self setUserDefault:usernames forKey:AccountUsernames];
}

+ (void) addAccountUsername:(NSString *)username
{
	NSMutableArray* new_usernames;
	NSArray* usernames = [self accountsUsernames];
	if ([usernames count] == 0) {
		new_usernames = [NSMutableArray array];
		NSString* current_username = [self snippetsUsername];
		if (current_username) {
			[new_usernames addObject:current_username];
		}
		[new_usernames addObject:username];
	}
	else if (![usernames containsObject:username]) {
		new_usernames = [usernames mutableCopy];
		[new_usernames addObject:username];
	}

	[self setAccountUsernames:new_usernames];
}

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

+ (void) setSelectedBlogInfo:(NSDictionary*)blogInfo
{
	[RFSettings setUserDefault:blogInfo forKey:SelectedBlogInfo useCurrentUser:YES];
}

+ (NSDictionary*) selectedBlogInfo
{
	return [RFSettings loadUserDefaultDictionary:SelectedBlogInfo];
}

+ (NSString*) selectedBlogUid
{
	NSDictionary* blogInfo = [RFSettings selectedBlogInfo];
	NSString* uid = nil;
	if (blogInfo)
	{
		uid = [blogInfo objectForKey:@"uid"];
		//NSString* name = [blogInfo objectForKey:@"name"];
	}
	
	return uid;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSArray*) blogList
{
	return [RFSettings loadUserDefaultArray:BlogList useCurrentUser:YES];
}

+ (void) setBlogList:(NSArray*)blogList
{
	[RFSettings setUserDefault:blogList forKey:BlogList useCurrentUser:YES];
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
	return [RFSettings loadUserDefault:AccountFullName useCurrentUser:YES];
}

+ (void) setSnippetsAccountFullName:(NSString*)value
{
	[RFSettings setUserDefault:value forKey:AccountFullName useCurrentUser:YES];
}

+ (void) clearAllSettings
{
	NSArray* usernames = [self accountsUsernames];
	for (NSString* username in usernames) {
		[self removeObjectForKey:AccountFullName username:username];
		[self removeObjectForKey:AccountDefaultSite username:username];
		[self removeObjectForKey:HasSnippetsBlog username:username];
		[self removeObjectForKey:SelectedBlogInfo username:username];
		[self removeObjectForKey:BlogList username:username];
		[SSKeychain deletePasswordForService:@"Snippets" account:username];
	}
	
	[RFSettings removeObjectForKey:AccountUsername];
	[RFSettings removeObjectForKey:AccountUsernames];
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

	[RFSettings removeObjectForKey:BlogList];
	[RFSettings removeObjectForKey:SelectedBlogInfo];
	[RFSettings removeObjectForKey:@"RFAutoCompleteCache"];

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
	[RFSettings migrateValueForKey:AccountFullName];
	[RFSettings migrateValueForKey:BlogList];
}

+ (void) migrateValueForKey:(NSString*)key
{
	NSUserDefaults* sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: kSharedGroupDefaults];
	NSObject* object = [[NSUserDefaults standardUserDefaults] objectForKey:key];
	[sharedDefaults setObject:object forKey:key];
	[sharedDefaults synchronize];
}

+ (void) migrateCurrentUserKeys
{
	id full_name = [self loadUserDefault:AccountFullName];
	if (full_name) {
		[self setSnippetsAccountFullName:full_name];
	}

	id default_site = [self loadUserDefault:AccountDefaultSite];
	if (default_site) {
		[self setAccountDefaultSite:default_site];
	}

	BOOL has_snippets_blog = [self loadUserDefaultBool:HasSnippetsBlog];
	[self setHasSnippetsBlog:has_snippets_blog];

	id selected_blog_info = [self loadUserDefaultDictionary:SelectedBlogInfo];
	if (selected_blog_info) {
		[self setSelectedBlogInfo:selected_blog_info];
	}

	id blog_list = [self loadUserDefaultArray:BlogList];
	if (blog_list) {
		[self setBlogList:blog_list];
	}
	
	NSString* password = [self snippetsPassword];
	if ([password length] > 0) {
		[self setSnippetsPassword:password useCurrentUser:YES];
	}
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

+ (float) lastStatusBarHeight
{
	NSString* s = [RFSettings loadUserDefault:kLastStatusBarHeightPrefKey];
	return [s floatValue];
}

+ (void) setLastStatusBarHeight:(float)value
{
	[RFSettings setUserDefault:[NSNumber numberWithFloat:value] forKey:kLastStatusBarHeightPrefKey];
}

@end
