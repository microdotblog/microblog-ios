//
//  RFConstants.h
//  Snippets
//
//  Created by Manton Reece on 8/25/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

static NSString* const kLoadTimelineNotification = @"RFLoadTimeline";
static NSString* const kOpenPostingNotification = @"RFOpenPosting";
static NSString* const kClosePostingNotification = @"RFClosePosting";

static NSString* const kSelectTagmojiNotification = @"SelectTagmojiNotification";
static NSString* const kSelectTagmojiInfoKey = @"info";

#define kShowConversationNotification @"RFShowConversationNotification"
#define kShowConversationPostIDKey @"post_id"

#define kPrepareConversationNotification @"RFPrepareConversationNotification"
#define kPrepareConversationPointKey @"point" // CGFloat y
#define kPrepareConversationControllersKey @"controllers" // NSMutableArray of UIViewController
#define kPrepareConversationTimelineKey @"timeline" // RFTimelineController

#define kShowUserProfileNotification @"RFShowUserProfileNotification"
#define kShowUserProfileUsernameKey @"username"

#define kUpdateSigninTokenNotification @"RFUpdateSigninTokenNotification"
#define kUpdateSigninTokenKey @"token"

#define kShowUserFollowingNotification @"RFShowUserFollowingNotification"
#define kShowUserFollowingUsernameKey @"username"

#define kShowUserDiscoverNotification @"RFShowUserDiscoverNotification"
#define kShowUserDiscoverUsernameKey @"username"

#define kShowTopicNotification @"RFShowTopicNotification"
#define kShowTopicKey @"topic"

#define kShowNewPostNotification @"RFShowNewPostNotification"
#define kShowNewPostText @"text"

#define kShowReplyPostNotification @"RFShowReplyPostNotification"
#define kShowReplyPostIDKey @"post_id"
#define kShowReplyPostUsernameKey @"username"

#define kShowSigninNotification @"RFShowSigninNotification"

#define kRefreshUserNotification @"RFRefreshUserNotification"
#define kRefreshUserGoToTimelineKey @"go_timeline"

#define kRefreshMenuNotification @"RFRefreshMenuNotification"

#define kTimelineDidStopScrollingNotification @"RFTimelineDidStopScrollingNotification"

#define kPostWasFavoritedNotification @"RFPostWasFavoritedNotification"
#define kPostWasUnfavoritedNotification @"RFPostWasUnfavoritedNotification"
#define kPostWasDeletedNotification @"RFPostWasDeletedNotification"
#define kPostWasUnselectedNotification @"RFPostWasUnselectedNotification"
#define kPostNotificationPostIDKey @"post_id"

#define kMicroblogSelectNotification @"kMicroblogSelectNotification"

#define kPushNotificationReceived @"kPushNotificationReceived"

#define kSharePostNotification @"RFSharePostNotification"
#define kSharePostIDKey @"post_id"

#define kOpenURLNotification @"RFOpenURLNotification"
#define kOpenURLKey @"url"

#define kRFFoundUserAutoCompleteNotification @"RFFoundUserAutoCompleteNotification"

#define kSharedGroupDefaults @"group.blog.micro.ios"

static NSString* const kResetDetailNotification = @"RFResetDetail";
static NSString* const kResetDetailControllerKey = @"controller";

static NSString* const kShortcutActionNewPost = @"com.riverfold.snippets.shortcut.post";

static NSString* const kDidJustUpdatePostPrefKey = @"DidJustUpdatePost";

#define kEditPostNotification @"RFEditPostNotification"
#define kEditPostIDKey @"post_id"

#define kDeletePostNotification @"RFDeletePostNotification"
#define kDeletePostIDKey @"post_id"

#define kPublishPostNotification @"RFPublishPostNotification"
#define kPublishPostIDKey @"post_id"

#define kOpenUploadNotification @"RFOpenUploadNotification"
#define kCopyUploadNotification @"RFCopyUploadNotification"
#define kDeleteUploadNotification @"RFDeleteUploadNotification"

#define kNewPostFromHighlightNotification @"RFNewPostFromHighlight"
#define kCopyHighlightNotification @"RFCopyHighlightNotification"
#define kDeleteHighlightNotification @"RFDeleteHighlightNotification"

#define APPSTORE 1
