//
//  RFPostController.m
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//


#import "RFViewController.h"
#import "RFPostController.h"
#import "RFSettings.h"
#import "RFFeedsController.h"
#import "RFPhotosController.h"
#import "RFPhoto.h"
#import "RFPhotoCell.h"
#import "RFClient.h"
#import "RFMicropub.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "RFXMLRPCParser.h"
#import "RFXMLRPCRequest.h"
#import "RFHighlightingTextStorage.h"
#import "UIBarButtonItem+Extras.h"
#import "NSString+Extras.h"
#import "UILabel+MarkupExtensions.h"
#import "UIFont+Extras.h"
#import "UUAlert.h"
#import "UUString.h"
#import "UUImage.h"
#import "SSKeychain.h"
#import "MMMarkdown.h"
//#import "Microblog-Swift.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
@import MobileCoreServices;

static NSString* const kPhotoCellIdentifier = @"PhotoCell";

@interface RFPostController()
	@property (nonatomic, weak) NSExtensionContext* appExtensionContext;
@end

@implementation RFPostController

- (instancetype) init
{
	self = [super initWithNibName:@"Post" bundle:nil];
	if (self) {
		self.attachedPhotos = @[];
		self.edgesForExtendedLayout = UIRectEdgeTop;
	}
	
	return self;
}

- (instancetype) initWithText:(NSString *)text
{
	self = [self init];
	if (self) {
		self.initialText = text;
	}
	
	return self;
}

- (instancetype) initWithReplyTo:(NSString *)postID replyUsername:(NSString *)username
{
	self = [self init];
	if (self) {
		self.isReply = YES;
		self.replyPostID = postID;
		self.replyUsername = username;
		self.attachedPhotos = @[];
	}
	
	return self;
}

- (instancetype) initWithAppExtensionContext:(NSExtensionContext*)extensionContext
{
	self = [self init];
	if (self)
	{
		self.appExtensionContext = extensionContext;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupText];
	[self setupDragAndDrop];
	[self setupNotifications];
	[self setupBlogName];
	[self setupEditingButtons];
	[self setupCollectionView];
	[self setupGestures];
	[self setupAppExtensionElements];
	[self updateTitleHeader];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	self.progressHeaderHeightConstraint.constant = 0.0;
	self.progressHeaderView.alpha = 0.0;

	[self setupBlogName];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	RFDispatchSeconds (0.1, ^{
		[self.textView becomeFirstResponder];
	});
}

- (void) setupNavigation
{
	if (self.isReply) {
		self.title = @"New Reply";
	}
	else {
		self.title = @"New Post";
	}

	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"close_button" target:self action:@selector(close:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStylePlain target:self action:@selector(sendPost:)];

	self.progressHeaderTopConstraint.constant = 44 + RFStatusBarHeight();
}

- (void) setupFont
{
	#ifndef SHARING_EXTENSION
		NSString* content_size = [UIApplication sharedApplication].preferredContentSizeCategory;
		[RFSettings setPreferredContentSize:content_size];
	#endif

	self.textView.font = [UIFont fontWithName:@"Avenir-Book" size:[UIFont rf_preferredPostingFontSize]];
}

- (void) setupText
{
	[self setupFont];

	self.textStorage = [[RFHighlightingTextStorage alloc] init];

	NSString* s = @"";
	if (self.replyUsername) {
		s = [NSString stringWithFormat:@"@%@ ", self.replyUsername];
	}
	else if (self.initialText) {
		s = self.initialText;
	}
	else if (!self.appExtensionContext) {
		s = [RFSettings draftText];
		if (s.length > 280) {
			self.titleField.text = [RFSettings draftTitle];
		}
	}
	
	NSAttributedString* attr_s = [[NSAttributedString alloc] initWithString:s];
	self.textView.attributedText = attr_s;

	[self.textStorage appendAttributedString:attr_s];
	[self.textStorage addLayoutManager:self.textView.layoutManager];

	[self updateRemainingChars];
}

- (void) setupDragAndDrop
{
	if (@available(iOS 11, *)) {
		UIDropInteraction* drop_interaction = [[UIDropInteraction alloc] initWithDelegate:self];
		[self.view addInteraction:drop_interaction];
	}
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attachPhotoNotification:) name:kAttachPhotoNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosDidCloseNotification:) name:kPhotosDidCloseNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferredContentSize:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void) setupBlogName
{
	if (self.isReply) {
		self.blognameField.hidden = YES;
	}
	else {
		if ([RFSettings hasSnippetsBlog] && ![RFSettings prefersExternalBlog]) {
			self.blognameField.text = [RFSettings accountDefaultSite];
		}
		else if ([RFSettings hasMicropubBlog]) {
			NSString* endpoint_s = [RFSettings externalMicropubMe];
			NSURL* endpoint_url = [NSURL URLWithString:endpoint_s];
			self.blognameField.text = endpoint_url.host;
		}
		else {
			NSString* endpoint_s = [RFSettings externalBlogEndpoint];
			NSURL* endpoint_url = [NSURL URLWithString:endpoint_s];
			self.blognameField.text = endpoint_url.host;
		}
	}
}

- (void) setupEditingButtons
{
	UIImage* img = [UIImage uuSolidColorImage:self.editingBar.backgroundColor];
	[self.photoButton setBackgroundImage:img forState:UIControlStateNormal];
	[self.markdownBoldButton setBackgroundImage:img forState:UIControlStateNormal];
	[self.markdownItalicsButton setBackgroundImage:img forState:UIControlStateNormal];
	[self.markdownLinkButton setBackgroundImage:img forState:UIControlStateNormal];
	[self.settingsButton setBackgroundImage:img forState:UIControlStateNormal];

	if (self.isReply) {
		self.photoButtonLeftConstraint.constant = -34;
		self.settingsButtonRightConstraint.constant = -34;
	}
}

- (void) setupCollectionView
{
	[self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCell" bundle:nil] forCellWithReuseIdentifier:kPhotoCellIdentifier];
	self.photoBarHeightConstraint.constant = 0;
}

- (void) setupGestures
{
	UISwipeGestureRecognizer* left_gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
	left_gesture.direction = UISwipeGestureRecognizerDirectionLeft;
	[self.textView addGestureRecognizer:left_gesture];

	UISwipeGestureRecognizer* right_gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
	right_gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.textView addGestureRecognizer:right_gesture];
}

- (void) updateTitleHeader
{
	if (!self.isReply && ([self currentProcessedMarkup].length > 280)) {
		self.titleHeaderHeightConstraint.constant = 44;
	}
	else {
		self.titleHeaderHeightConstraint.constant = 0;
	}
}

#pragma mark -

- (void) swipeLeft:(UISwipeGestureRecognizer *)gesture
{
	NSRange r = self.textView.selectedRange;
	if (r.location > 0) {
		r.location = r.location - 1;
		self.textView.selectedRange = r;
	}
}

- (void) swipeRight:(UISwipeGestureRecognizer *)gesture
{
	NSRange r = self.textView.selectedRange;
	NSUInteger len = [[self.textStorage string] length];
	if (r.location < len) {
		r.location = r.location + 1;
		self.textView.selectedRange = r;
	}
}

- (BOOL) canBecomeFirstResponder
{
	return YES;
}

- (NSArray *) keyCommands
{
	NSMutableArray* commands = [NSMutableArray array];
	
	UIKeyCommand* close_key = [UIKeyCommand keyCommandWithInput:@"W" modifierFlags:UIKeyModifierCommand action:@selector(close:) discoverabilityTitle:@"Close"];
	
	[commands addObject:close_key];
	
	return commands;
}

#pragma mark -

- (NSString *) currentTitle
{
	return self.titleField.text;
}

- (NSString *) currentText
{
//	return self.textView.text
	return [self.textStorage string];
}

- (NSString *) currentProcessedMarkup
{
	NSError* error = nil;
	NSString* html = [MMMarkdown HTMLStringWithMarkdown:[self currentText] error:&error];
	if (html.length > 0) {
		// Markdown processor adds a return at the end
		html = [html substringToIndex:html.length - 1];
		html = [html stringByReplacingOccurrencesOfString:@"</p>\n<p>" withString:@"</p>\n\n<p>"];
	}
	
	return [html rf_stripHTML];
}

- (void) updateRemainingChars
{
	if (!self.isReply && self.titleField.text.length > 0) {
		self.remainingField.hidden = YES;
	}
	else {
		self.remainingField.hidden = NO;
	}

	NSInteger max_chars = 280;
	NSInteger num_chars = [self currentProcessedMarkup].length;
	NSInteger num_remaining = max_chars - num_chars;
	if (num_chars <= 140) {
		[self.remainingField setMarkup:[NSString stringWithFormat:@"<font color=\"#428BCA\">%ld</font>/%ld", (long)num_chars, (long)max_chars]];
	}
	else if (num_remaining < 0) {
		[self.remainingField setMarkup:[NSString stringWithFormat:@"<font color=\"#FF6057\">%ld</font>/%ld", (long)num_chars, (long)max_chars]];
	}
	else {
		self.remainingField.text = [NSString stringWithFormat:@"%ld/%ld", (long)num_chars, (long)max_chars];
	}
}

- (void) attachPhotoNotification:(NSNotification *)notification
{
	[self setupNavigation];

	UIImage* img = [notification.userInfo objectForKey:kAttachPhotoKey];
	RFPhoto* photo = [[RFPhoto alloc] initWithThumbnail:img];
	NSMutableArray* new_photos = [self.attachedPhotos mutableCopy];
	[new_photos addObject:photo];
	self.attachedPhotos = new_photos;
	[self.collectionView reloadData];
	
	[self dismissViewControllerAnimated:YES completion:^{
		[self showPhotosBar];
	}];
}

- (void) photosDidCloseNotification:(NSNotification *)notification
{
	[self setupNavigation];
}

- (void) keyboardWillShowNotification:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    CGRect kb_r = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGFloat kb_bottom = self.view.bounds.size.height - kb_r.origin.y;
	[UIView animateWithDuration:0.3 animations:^{
		self.bottomConstraint.constant = kb_bottom;
		[self.view layoutIfNeeded];
	}];
}
 
- (void) keyboardWillHideNotification:(NSNotification*)aNotification
{
	[UIView animateWithDuration:0.3 animations:^{
		self.bottomConstraint.constant = 0;
		[self.view layoutIfNeeded];
	}];
}

- (void) didChangePreferredContentSize:(NSNotification *)notification
{
	[self setupFont];
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	[self performSelector:@selector(updateRemainingChars) withObject:nil afterDelay:0.1];
	return YES;
}

- (void) textViewDidChange:(UITextView *)textView
{
	[self updateRemainingChars];
	
	[UIView animateWithDuration:0.3 animations:^{
		[self updateTitleHeader];
		[self.view layoutIfNeeded];
	} completion:^(BOOL finished) {
		if ([self currentProcessedMarkup].length <= 280) {
			self.titleField.text = @"";
			[self updateRemainingChars];
		}
	}];
}

#pragma mark -

- (IBAction) sendPost:(id)sender
{
	NSString* s = [self currentText];
	
	if ((self.attachedPhotos.count > 0) && (s.length > 0)) {
		if (([s characterAtIndex:0] == '@') && [RFSettings hasSnippetsBlog] && ![RFSettings prefersExternalBlog]) {
			NSString* msg = @"When replying to another Micro.blog user, photos are not currently supported. Start the post with different text and @-mention the user elsewhere in the post to make this a microblog post with inline photos on your site.";
			[UUAlertViewController uuShowOneButtonAlert:@"Replies Can't Use Photos" message:msg button:@"OK" completionHandler:NULL];
			return;
		}
	}
	
	self.photoButton.hidden = YES;

	self.isSent = YES;
	[RFSettings setDraftTitle:@""];
	[RFSettings setDraftText:@""];

	if (self.attachedPhotos.count > 0) {
		self.queuedPhotos = [self.attachedPhotos copy];
		[self uploadNextPhoto];
	}
	else {
		[self uploadText:s];
	}
}

- (IBAction) close:(id)sender
{
	if (!self.isReply && !self.isSent && !self.appExtensionContext) {
		[RFSettings setDraftTitle:[self currentTitle]];
		[RFSettings setDraftText:[self currentText]];
	}

	if (![self checkForAppExtensionClose])
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kClosePostingNotification object:self];
	}
}

- (IBAction) showPhotos:(id)sender
{
	self.navigationItem.rightBarButtonItem = nil;

	RFPhotosController* photos_controller = [[RFPhotosController alloc] init];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:photos_controller];
	
	nav_controller.view.opaque = NO;
	nav_controller.view.backgroundColor = [UIColor clearColor];
	nav_controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	
	[self presentViewController:nav_controller animated:YES completion:NULL];
	[self checkMediaEndpoint];
}

- (IBAction) boldPressed:(id)sender
{
	[self replaceSelectionBySurrounding:@[ @"**", @"**" ]];
}

- (IBAction) italicsPressed:(id)sender
{
	[self replaceSelectionBySurrounding:@[ @"_", @"_" ]];
}

- (IBAction) linkPressed:(id)sender
{
	NSRange r;
	UITextRange* text_r = self.textView.selectedTextRange;
	if ([text_r isEmpty]) {
		[self.textView insertText:@"[]()"];
		r = self.textView.selectedRange;
		r.location = r.location - 3;
		self.textView.selectedRange = r;
	}
	else {
		[self replaceSelectionBySurrounding:@[ @"[", @"]()" ]];
		r = self.textView.selectedRange;
		r.location = r.location - 1;
		self.textView.selectedRange = r;
	}
}

- (IBAction) blogHostnamePressed:(id)sender
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Blogs" bundle:nil];
	UIViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"BlogsNavigation"];
	[self presentViewController:controller animated:NO completion:NULL];
}

- (IBAction) settingsPressed:(id)sender
{
	RFFeedsController* feeds_controller = [[RFFeedsController alloc] init];
	[self.navigationController pushViewController:feeds_controller animated:YES];
}

- (void) replaceSelectionBySurrounding:(NSArray *)markup
{
	UITextRange* r = self.textView.selectedTextRange;
	if ([r isEmpty]) {
		[self.textView insertText:[markup firstObject]];
	}
	else {
		NSString* s = [self.textView textInRange:r];
		NSString* new_s = [NSString stringWithFormat:@"%@%@%@", [markup firstObject], s, [markup lastObject]];
		[self.textView replaceRange:r withText:new_s];
	}
}

- (void) checkMediaEndpoint
{
	if ([RFSettings hasMicropubBlog]) {
		NSString* media_endpoint = [RFSettings externalMicropubMediaEndpoint];
		if (media_endpoint.length == 0) {
			NSString* micropub_endpoint = [RFSettings externalMicropubPostingEndpoint];
			RFMicropub* client = [[RFMicropub alloc] initWithURL:micropub_endpoint];
			NSDictionary* args = @{
				@"q": @"config"
			};
			[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
				BOOL found = NO;
				if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]]) {
					NSString* new_endpoint = [response.parsedResponse objectForKey:@"media-endpoint"];
					if (new_endpoint) {
						[RFSettings setExternalMicropubMediaEndpoint:new_endpoint];
						found = YES;
					}
				}
				
				if (!found) {
					RFDispatchMain (^{
						[UUAlertViewController uuShowOneButtonAlert:@"Error Checking Server" message:@"Micropub media-endpoint was not found." button:@"OK" completionHandler:NULL];
					});
				}
			}];
		}
	}
}

- (void) uploadText:(NSString *)text
{
	if (self.isReply) {
		[self showProgressHeader:@"Now sending your reply..."];
		RFClient* client = [[RFClient alloc] initWithPath:@"/posts/reply"];
		NSMutableDictionary* args = [NSMutableDictionary dictionary];
		NSString* uid = [RFSettings selectedBlogUid];
		if (uid)
		{
			[args setObject:uid forKey:@"mp-destination"];
		}
		[args setObject:self.replyPostID forKey:@"id"];
		[args setObject:text forKey:@"text"];

		[client postWithParams:args completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				[Answers logCustomEventWithName:@"Sent Reply" customAttributes:nil];
				[self close:nil];
			});
		}];
	}
	else {
		[self showProgressHeader:@"Now publishing to your microblog..."];
		if ([RFSettings hasSnippetsBlog] && ![RFSettings prefersExternalBlog]) {
			RFClient* client = [[RFClient alloc] initWithPath:@"/micropub"];
			NSMutableDictionary* args = [NSMutableDictionary dictionary];
			NSString* uid = [RFSettings selectedBlogUid];
			if (uid)
			{
				[args setObject:uid forKey:@"mp-destination"];
			}
			[args setObject:self.titleField.text forKey:@"name"];
			[args setObject:text forKey:@"content"];
			
			if ([self.attachedPhotos count] > 0) {
				NSMutableArray* photo_urls = [NSMutableArray array];
				for (RFPhoto* photo in self.attachedPhotos) {
					[photo_urls addObject:photo.publishedURL];
				}
				
				[args setObject:photo_urls forKey:@"photo[]"];
			}

			[client postWithParams:args completion:^(UUHttpResponse* response) {
				RFDispatchMainAsync (^{
					if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
						[self hideProgressHeader];
						NSString* msg = response.parsedResponse[@"error_description"];
						[UUAlertViewController uuShowOneButtonAlert:@"Error Sending Post" message:msg button:@"OK" completionHandler:NULL];
					}
					else {
						[Answers logCustomEventWithName:@"Sent Post" customAttributes:nil];
						[self close:nil];
					}
				});
			}];
		}
		else if ([RFSettings hasMicropubBlog]) {
			NSString* micropub_endpoint = [RFSettings externalMicropubPostingEndpoint];
			RFMicropub* client = [[RFMicropub alloc] initWithURL:micropub_endpoint];
			NSDictionary* args;
			if ([self.attachedPhotos count] > 0) {
				NSMutableArray* photo_urls = [NSMutableArray array];
				for (RFPhoto* photo in self.attachedPhotos) {
					[photo_urls addObject:photo.publishedURL];
				}

				if (photo_urls.count == 1) {
					args = @{
						@"h": @"entry",
						@"name": self.titleField.text,
						@"content": text,
						@"photo": [photo_urls firstObject]
					};
				}
				else {
					args = @{
						@"h": @"entry",
						@"name": self.titleField.text,
						@"content": text,
						@"photo[]": photo_urls
					};
				}
			}
			else {
				args = @{
					@"h": @"entry",
					@"name": self.titleField.text,
					@"content": text
				};
			}
			
			[client postWithParams:args completion:^(UUHttpResponse* response) {
				RFDispatchMainAsync (^{
					if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
						[self hideProgressHeader];
						NSString* msg = response.parsedResponse[@"error_description"];
						[UUAlertViewController uuShowOneButtonAlert:@"Error Sending Post" message:msg button:@"OK" completionHandler:NULL];
					}
					else {
						[Answers logCustomEventWithName:@"Sent Post" customAttributes:nil];
						[self close:nil];
					}
				});
			}];
		}
		else {
			NSString* xmlrpc_endpoint = [RFSettings externalBlogEndpoint];
			NSString* blog_s = [RFSettings externalBlogID];
			NSString* username = [RFSettings externalBlogUsername];
			NSString* password = [RFSettings externalBlogPassword];
			
			NSString* post_text = text;
			NSString* app_key = @"";
			NSNumber* blog_id = [NSNumber numberWithInteger:[blog_s integerValue]];
			RFBoolean* publish = [[RFBoolean alloc] initWithBool:YES];

			NSString* post_format = [RFSettings externalBlogFormat];
			NSString* post_category = [RFSettings externalBlogCategory];

			NSArray* params;
			NSString* method_name;

			if ([RFSettings externalBlogUsesWordPress]) {
				NSMutableDictionary* content = [NSMutableDictionary dictionary];
				
				content[@"post_status"] = @"publish";
				content[@"post_title"] = self.titleField.text;
				content[@"post_content"] = post_text;
				if (post_format.length > 0) {
					if (self.titleField.text.length > 0) {
						content[@"post_format"] = @"Standard";
					}
					else {
						content[@"post_format"] = post_format;
					}
				}
				if (post_category.length > 0) {
					content[@"terms"] = @{
						@"category": @[ post_category ]
					};
				}

				params = @[ blog_id, username, password, content ];
				method_name = @"wp.newPost";
			}
			else {
				params = @[ app_key, blog_id, username, password, post_text, publish ];
				method_name = @"blogger.newPost";
			}
			
			RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:xmlrpc_endpoint];
			[request sendMethod:method_name params:params completion:^(UUHttpResponse* response) {
				RFXMLRPCParser* xmlrpc = [RFXMLRPCParser parsedResponseFromData:response.rawResponse];
				RFDispatchMainAsync ((^{
					if (xmlrpc.responseFault) {
						NSString* s = [NSString stringWithFormat:@"%@ (error: %@)", xmlrpc.responseFault[@"faultString"], xmlrpc.responseFault[@"faultCode"]];
						[UUAlertViewController uuShowOneButtonAlert:@"Error Sending Post" message:s button:@"OK" completionHandler:NULL];
						[self hideProgressHeader];
						self.photoButton.hidden = NO;
					}
					else {
						[Answers logCustomEventWithName:@"Sent External" customAttributes:nil];
						[self close:nil];
					}
				}));
			}];
		}
	}
}

- (void) uploadNextPhoto
{
	RFPhoto* photo = [self.queuedPhotos firstObject];
	if (photo) {
		NSMutableArray* new_photos = [self.queuedPhotos mutableCopy];
		[new_photos removeObjectAtIndex:0];
		self.queuedPhotos = new_photos;
		
		[self uploadPhoto:photo completion:^{
			[self uploadNextPhoto];
		}];
	}
	else {
		NSString* s = [self currentText];
		
		if ([RFSettings prefersExternalBlog] && ![RFSettings hasMicropubBlog]) {
			if (s.length > 0) {
				s = [s stringByAppendingString:@"\n\n"];
			}
			
			for (RFPhoto* photo in self.attachedPhotos) {
				CGSize original_size = photo.thumbnailImage.size;
				CGFloat width = 0;
				CGFloat height = 0;

				if (original_size.width > original_size.height) {
					if (original_size.width > 600.0) {
						width = 600.0;
					}
					else {
						width = original_size.width;
					}
					height = width / original_size.width * original_size.height;
				}
				else {
					if (original_size.height > 600.0) {
						height = 600.0;
					}
					else {
						height = original_size.height;
					}
					width = height / original_size.height * original_size.width;
				}

				s = [s stringByAppendingFormat:@"<img src=\"%@\" width=\"%.0f\" height=\"%.0f\" />", photo.publishedURL, width, height];
			}
		}

		[self uploadText:s];
	}
}

- (void) uploadPhoto:(RFPhoto *)photo completion:(void (^)(void))handler
{
	if (self.attachedPhotos.count > 0) {
		[self showProgressHeader:@"Uploading photos..."];
	}
	else {
		[self showProgressHeader:@"Uploading photo..."];
	}
	
	UIImage* img = photo.thumbnailImage;
	NSData* d = UIImageJPEGRepresentation (img, 0.6);
	if (d) {
		if ([RFSettings hasSnippetsBlog] && ![RFSettings prefersExternalBlog]) {
			RFClient* client = [[RFClient alloc] initWithPath:@"/micropub/media"];
			NSMutableDictionary* args = [NSMutableDictionary dictionary];
			NSString* uid = [RFSettings selectedBlogUid];
			if (uid)
			{
				[args setObject:uid forKey:@"mp-destination"];
			}
			
			[client uploadImageData:d named:@"file" httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
				NSDictionary* headers = response.httpResponse.allHeaderFields;
				NSString* image_url = headers[@"Location"];
				RFDispatchMainAsync (^{
					if (image_url == nil) {
						[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Photo" message:@"Photo URL was blank." button:@"OK" completionHandler:NULL];
						[self hideProgressHeader];
						self.photoButton.hidden = NO;
					}
					else {
						photo.publishedURL = image_url;
						[Answers logCustomEventWithName:@"Uploaded Photo" customAttributes:nil];
						handler();
					}
				});
			}];
		}
		else if ([RFSettings hasMicropubBlog]) {
			NSString* micropub_endpoint = [RFSettings externalMicropubMediaEndpoint];
			RFMicropub* client = [[RFMicropub alloc] initWithURL:micropub_endpoint];
			NSDictionary* args = @{
			};
			[client uploadImageData:d named:@"file" httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
				NSDictionary* headers = response.httpResponse.allHeaderFields;
				NSString* image_url = headers[@"Location"];
				RFDispatchMainAsync (^{
					if (image_url == nil) {
						[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Photo" message:@"Photo URL was blank." button:@"OK" completionHandler:NULL];
						[self hideProgressHeader];
						self.photoButton.hidden = NO;
					}
					else {
						photo.publishedURL = image_url;
						[Answers logCustomEventWithName:@"Uploaded Micropub" customAttributes:nil];
						handler();
					}
				});
			}];
		}
		else {
			NSString* xmlrpc_endpoint = [RFSettings externalBlogEndpoint];
			NSString* blog_s = [RFSettings externalBlogID];
			NSString* username = [RFSettings externalBlogUsername];
			NSString* password = [RFSettings externalBlogPassword];
			
			NSNumber* blog_id = [NSNumber numberWithInteger:[blog_s integerValue]];
			NSString* filename = [[[[NSString uuGenerateUUIDString] lowercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@""] stringByAppendingPathExtension:@"jpg"];
			
			if (!blog_id || !username || !password) {
				[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Photo" message:@"Your blog settings were not saved correctly. Try signing out and trying again." button:@"OK" completionHandler:NULL];
				[self hideProgressHeader];
				self.photoButton.hidden = NO;
				return;
			}
			
			NSArray* params = @[ blog_id, username, password, @{
				@"name": filename,
				@"type": @"image/jpeg",
				@"bits": d
			}];
			NSString* method_name = @"metaWeblog.newMediaObject";

			RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:xmlrpc_endpoint];
			[request sendMethod:method_name params:params completion:^(UUHttpResponse* response) {
				RFXMLRPCParser* xmlrpc = [RFXMLRPCParser parsedResponseFromData:response.rawResponse];
				RFDispatchMainAsync ((^{
					if (xmlrpc.responseFault) {
						NSString* s = [NSString stringWithFormat:@"%@ (error: %@)", xmlrpc.responseFault[@"faultString"], xmlrpc.responseFault[@"faultCode"]];
						[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Photo" message:s button:@"OK" completionHandler:NULL];
						[self hideProgressHeader];
						self.photoButton.hidden = NO;
					}
					else {
						NSString* image_url = [[xmlrpc.responseParams firstObject] objectForKey:@"url"];
						if (image_url == nil) {
							image_url = [[xmlrpc.responseParams firstObject] objectForKey:@"link"];
						}

						if (image_url == nil) {
							[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Photo" message:@"Photo URL was blank." button:@"OK" completionHandler:NULL];
							[self hideProgressHeader];
							self.photoButton.hidden = NO;
						}
						else {
							photo.publishedURL = image_url;

							[Answers logCustomEventWithName:@"Uploaded External" customAttributes:nil];
							handler();
						}
					}
				}));
			}];
		}
	}
}

- (void) showProgressHeader:(NSString *)statusText;
{
	self.navigationItem.rightBarButtonItem.enabled = NO;

	self.progressHeaderField.text = statusText;
	[self.networkSpinner startAnimating];
	if (self.progressHeaderHeightConstraint.constant == 0.0) {
		[UIView animateWithDuration:0.3 animations:^{
			self.progressHeaderHeightConstraint.constant = 40.0;
			self.progressHeaderTopConstraint.constant = 44 + RFStatusBarHeight();
			self.progressHeaderView.alpha = 1.0;
			[self.view layoutIfNeeded];
		}];
	}
}

- (void) hideProgressHeader
{
	self.navigationItem.rightBarButtonItem.enabled = YES;

	[UIView animateWithDuration:0.3 animations:^{
		self.progressHeaderHeightConstraint.constant = 0.0;
		self.progressHeaderTopConstraint.constant = 44 + RFStatusBarHeight();
		self.progressHeaderView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[self.networkSpinner stopAnimating];
		[self.view layoutIfNeeded];
	}];
}

- (void) showPhotosBar
{
	[UIView animateWithDuration:0.3 animations:^{
		self.photoBarHeightConstraint.constant = 60;
		[self.view layoutIfNeeded];
	} completion:^(BOOL finished) {
		[self.collectionView reloadData];
	}];
}

#pragma mark -

- (BOOL) dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session NS_AVAILABLE_IOS(11.0)
{
	return [session canLoadObjectsOfClass:[UIImage class]];
}

- (UIDropProposal *) dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session NS_AVAILABLE_IOS(11.0)
{
	if (@available(iOS 11.0, *)) {
		UIDropProposal* proposal = [[UIDropProposal alloc] initWithDropOperation:UIDropOperationCopy];
		return proposal;
	} else {
		return nil;
	}
}

- (void) dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session NS_AVAILABLE_IOS(11.0)
{
	[session loadObjectsOfClass:[UIImage class] completion:^(NSArray* objects) {
		NSMutableArray* new_photos = [self.attachedPhotos mutableCopy];
		BOOL too_many_photos = NO;
		
		for (UIImage* img in objects) {
			if (new_photos.count < 10) {
				UIImage* new_img = img;
				CGFloat maxWidth = 1800.0 / [[UIScreen mainScreen] scale];
				if (new_img.size.width > maxWidth) {
					new_img = [new_img uuScaleToWidth:maxWidth];
				}
				new_img = [new_img uuRemoveOrientation];
				RFPhoto* photo = [[RFPhoto alloc] initWithThumbnail:new_img];
				[new_photos addObject:photo];
			}
			else {
				too_many_photos = YES;
			}
		}

		self.attachedPhotos = new_photos;
		[self.collectionView reloadData];
	
		[self showPhotosBar];
		
		if (too_many_photos) {
			[UUAlertViewController uuShowOneButtonAlert:@"Only 10 Photos Added" message:@"The first 10 photos were added to your post." button:@"OK" completionHandler:NULL];
		}
	}];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.attachedPhotos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFPhotoCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellIdentifier forIndexPath:indexPath];

	RFPhoto* photo = [self.attachedPhotos objectAtIndex:indexPath.item];
	cell.thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
	[cell setupWithPhoto:photo];
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	NSMutableArray* new_photos = [self.attachedPhotos mutableCopy];
	[new_photos removeObjectAtIndex:indexPath.item];
	self.attachedPhotos = new_photos;
	[self.collectionView deleteItemsAtIndexPaths:@[ indexPath ]];

	if (self.attachedPhotos.count == 0) {
		[UIView animateWithDuration:0.3 animations:^{
			self.photoBarHeightConstraint.constant = 0;
			[self.view layoutIfNeeded];
		}];
	}
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat w = 50;
	return CGSizeMake (w, w);
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
	return UIEdgeInsetsMake (5, 5, 5, 5);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return 5;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
	return 0;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark-
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) processImageForAppExtension:(UIImage*)image withInputItems:(NSMutableArray*)inputItems
{
	UIImage* new_img = image;
	CGFloat maxWidth = 1800.0 / [[UIScreen mainScreen] scale];
	if (new_img.size.width > maxWidth) {
		new_img = [new_img uuScaleToWidth:maxWidth];
	}
	new_img = [new_img uuRemoveOrientation];

	RFPhoto* photo = [[RFPhoto alloc] initWithThumbnail:new_img];

	NSMutableArray* new_photos = [NSMutableArray arrayWithArray:self.attachedPhotos];
	[new_photos addObject:photo];

	dispatch_async(dispatch_get_main_queue(), ^
	{
		self.attachedPhotos = new_photos;
		[self.collectionView reloadData];

		[self showPhotosBar];

		if (inputItems.count)
		{
			[self processAppExtensionItems:inputItems];
		}
	});
}

- (void) processAppExtensionItems:(NSMutableArray*)inputItems
{
	NSItemProvider * itemProvider = inputItems.firstObject;
	[inputItems removeObject:itemProvider];
		
	if ([itemProvider hasItemConformingToTypeIdentifier:(NSString*)kUTTypePropertyList])
	{
		[itemProvider loadItemForTypeIdentifier:(NSString*)kUTTypePropertyList options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error)
		{
			NSDictionary* dictionary = (NSDictionary*)item;
			dictionary = dictionary[NSExtensionJavaScriptPreprocessingResultsKey];
			NSString* title = [dictionary objectForKey:@"title"];
			NSURL* url = [NSURL URLWithString:[dictionary objectForKey:@"url"]];
					
			dispatch_async(dispatch_get_main_queue(), ^
			{
				if (title && url) {
					[self insertSharedURL:url withTitle:title];
				}
				else if (title) {
					[self insertSharedText:title];
				}
				else if (url) {
					[self insertSharedURL:url withTitle:@""];
				}
					
				if (inputItems.count)
				{
					[self processAppExtensionItems:inputItems];
				}
			});
		}];
	}
	else if ([itemProvider hasItemConformingToTypeIdentifier:@"public.url"])
	{
		[itemProvider loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error)
		{
			NSURL* url = [(NSURL*)item copy];;
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self insertSharedURL:url withTitle:@""];
					
				if (inputItems.count)
				{
					[self processAppExtensionItems:inputItems];
				}
			});
		}];
	}
	else if ([itemProvider hasItemConformingToTypeIdentifier:@"public.text"])
	{
		[itemProvider loadItemForTypeIdentifier:@"public.text" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error)
		{
			NSString* s = [(NSString*)item copy];
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self insertSharedText:s];
				
				if (inputItems.count)
				{
					[self processAppExtensionItems:inputItems];
				}
			});
		}];
	}
	else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage])
	{
		if (@available(iOS 11.0, *)) {
			[itemProvider loadInPlaceFileRepresentationForTypeIdentifier:(NSString*)kUTTypeImage completionHandler:^(NSURL * _Nullable url, BOOL isInPlace, NSError * _Nullable error)
			{
				NSData* data = [NSData dataWithContentsOfURL:url];
				UIImage* image = [UIImage imageWithData:data];
				if (image)
				{
					[self processImageForAppExtension:image withInputItems:inputItems];
				}
				else
				{
					[itemProvider loadFileRepresentationForTypeIdentifier:(NSString *)kUTTypeImage completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error)
					{
						NSData* data = [NSData dataWithContentsOfURL:url];
						UIImage* image = [UIImage imageWithData:data];
						if (image)
						{
							[self processImageForAppExtension:image withInputItems:inputItems];
						}
					}];
				}
			}];
		}
		else {
			[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *image, NSError *error)
			{
				if(image)
				{
					CGFloat maxWidth = 1800.0 / [[UIScreen mainScreen] scale];
					UIImage* new_img = image;
					if (new_img.size.width > maxWidth) {
						new_img = [new_img uuScaleToWidth:maxWidth];
					}
					new_img = [new_img uuRemoveOrientation];

					RFPhoto* photo = [[RFPhoto alloc] initWithThumbnail:new_img];

					NSMutableArray* new_photos = [NSMutableArray arrayWithArray:self.attachedPhotos];
					[new_photos addObject:photo];

					dispatch_async(dispatch_get_main_queue(), ^
					{
						self.attachedPhotos = new_photos;
						[self.collectionView reloadData];

						[self showPhotosBar];

						if (inputItems.count)
						{
							[self processAppExtensionItems:inputItems];
						}
					});
				}
			}];
		}
	}
	else // If we got here, it means we were passed an item that we don't handle. Sort of weird, but what can we do???
	{
		if (inputItems.count)
		{
			[self processAppExtensionItems:inputItems];
		}
	}
}

- (void) setupAppExtensionElements
{
	if (!self.appExtensionContext)
		return;
	
	// Handle alert views...
	[UUAlertViewController setActiveViewController:self];
	
	// Grab the first extension item. We really should only ever have one...
	NSExtensionItem* extensionItem = self.appExtensionContext.inputItems.firstObject;
	
	// Process all the attachements...
	NSMutableArray* itemsToProcess = [NSMutableArray arrayWithArray:extensionItem.attachments];
	[self processAppExtensionItems:itemsToProcess];
}

- (BOOL) checkForAppExtensionClose
{
	if (self.appExtensionContext)
	{
		[UUAlertViewController setActiveViewController:nil];

		[self.navigationController dismissViewControllerAnimated:NO completion:^
		{
			[self.appExtensionContext completeRequestReturningItems:@[] completionHandler:nil];
		}];
		return YES;
	}
	
	return NO;
}

- (void) insertSharedURL:(NSURL *)url withTitle:(NSString *)title
{
	NSString* s;
	
	if ([RFSettings prefersPlainSharedURLs]) {
		s = [NSString stringWithFormat:@" %@", url.absoluteString];
	}
	else if (title.length > 0) {
		s = [NSString stringWithFormat:@" [%@](%@)", title, url.absoluteString];
	}
	else {
		s = [NSString stringWithFormat:@" [%@](%@)", url.host, url.absoluteString];
	}
	
	[self.textView insertText:s];

	NSRange r = NSMakeRange (0, 0);
	self.textView.selectedRange = r;
}

- (void) insertSharedText:(NSString *)text
{
	NSString* s = [NSString stringWithFormat:@"\n\n> %@", text];
	
	[self.textView insertText:s];

	NSRange r = NSMakeRange (0, 0);
	self.textView.selectedRange = r;
}


@end
