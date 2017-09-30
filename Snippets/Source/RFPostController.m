//
//  RFPostController.m
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFPostController.h"

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
#import "Microblog-Swift.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

static NSString* const kPhotoCellIdentifier = @"PhotoCell";

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
	
	[self updateTitleHeader];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	self.progressHeaderHeightConstraint.constant = 0.0;
	self.progressHeaderView.alpha = 0.0;
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.textView becomeFirstResponder];
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
}

- (void) setupFont
{
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
	NSAttributedString* attr_s = [[NSAttributedString alloc] initWithString:s];
	self.textView.attributedText = attr_s;

	[self.textStorage appendAttributedString:attr_s];
	[self.textStorage addLayoutManager:self.textView.layoutManager];

	[self updateRemainingChars];
}

- (void) setupDragAndDrop
{
	if (NSClassFromString (@"UIDropInteraction") != nil) {
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
		if ([self hasSnippetsBlog] && ![self prefersExternalBlog]) {
			self.blognameField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"AccountDefaultSite"];
		}
		else if ([self hasMicropubBlog]) {
			NSString* endpoint_s = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubMe"];
			NSURL* endpoint_url = [NSURL URLWithString:endpoint_s];
			self.blognameField.text = endpoint_url.host;
		}
		else {
			NSString* endpoint_s = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogEndpoint"];
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

	if (self.isReply) {
		self.photoButtonLeftConstraint.constant = -34;
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
	if (!self.isReply && ([[self.textStorage string] length] > 280)) {
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

- (NSString *) currentText
{
//	return self.textView.text
	return [self.textStorage string];
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
	NSInteger num_chars = [self currentText].length;
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
		if ([[self.textStorage string] length] <= 280) {
			self.titleField.text = @"";
			[self updateRemainingChars];
		}
	}];
}

- (BOOL) hasSnippetsBlog
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"HasSnippetsBlog"];
}

- (BOOL) hasMicropubBlog
{
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubMe"] != nil);
}

- (BOOL) prefersExternalBlog
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"ExternalBlogIsPreferred"];
}

#pragma mark -

- (IBAction) sendPost:(id)sender
{
	self.photoButton.hidden = YES;

	if (self.attachedPhotos.count > 0) {
		self.queuedPhotos = [self.attachedPhotos copy];
		[self uploadNextPhoto];
	}
	else {
		[self uploadText:[self currentText]];
	}
}

- (IBAction) close:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kClosePostingNotification object:self];
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
	if ([self hasMicropubBlog]) {
		NSString* media_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubMediaEndpoint"];
		if (media_endpoint.length == 0) {
			NSString* micropub_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubPostingEndpoint"];
			RFMicropub* client = [[RFMicropub alloc] initWithURL:micropub_endpoint];
			NSDictionary* args = @{
				@"q": @"config"
			};
			[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
				BOOL found = NO;
				if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]]) {
					NSString* new_endpoint = [response.parsedResponse objectForKey:@"media-endpoint"];
					if (new_endpoint) {
						[[NSUserDefaults standardUserDefaults] setObject:new_endpoint forKey:@"ExternalMicropubMediaEndpoint"];
						found = YES;
					}
				}
				
				if (!found) {
					RFDispatchMain (^{
						[UIAlertView uuShowOneButtonAlert:@"Error Checking Server" message:@"Micropub media-endpoint was not found." button:@"OK" completionHandler:NULL];
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
		NSDictionary* args = @{
			@"id": self.replyPostID,
			@"text": text
		};
		[client postWithParams:args completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				[Answers logCustomEventWithName:@"Sent Reply" customAttributes:nil];
				[self close:nil];
			});
		}];
	}
	else {
		[self showProgressHeader:@"Now publishing to your microblog..."];
		if ([self hasSnippetsBlog] && ![self prefersExternalBlog]) {
			RFClient* client = [[RFClient alloc] initWithPath:@"/micropub"];
			NSDictionary* args;
			if ([self.attachedPhotos count] > 0) {
				NSMutableArray* photo_urls = [NSMutableArray array];
				for (RFPhoto* photo in self.attachedPhotos) {
					[photo_urls addObject:photo.publishedURL];
				}
				
				args = @{
					@"name": self.titleField.text,
					@"content": text,
					@"photo[]": photo_urls
				};
			}
			else {
				args = @{
					@"name": self.titleField.text,
					@"content": text
				};
			}

			[client postWithParams:args completion:^(UUHttpResponse* response) {
				RFDispatchMainAsync (^{
					if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
						[self hideProgressHeader];
						NSString* msg = response.parsedResponse[@"error_description"];
						[UIAlertView uuShowOneButtonAlert:@"Error Sending Post" message:msg button:@"OK" completionHandler:NULL];
					}
					else {
						[Answers logCustomEventWithName:@"Sent Post" customAttributes:nil];
						[self close:nil];
					}
				});
			}];
		}
		else if ([self hasMicropubBlog]) {
			NSString* micropub_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubPostingEndpoint"];
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
					[Answers logCustomEventWithName:@"Sent Micropub" customAttributes:nil];
					[self close:nil];
				});
			}];
		}
		else {
			NSString* xmlrpc_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogEndpoint"];
			NSString* blog_s = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogID"];
			NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogUsername"];
			NSString* password = [SSKeychain passwordForService:@"ExternalBlog" account:@"default"];
			
			NSString* post_text = text;
			NSString* app_key = @"";
			NSNumber* blog_id = [NSNumber numberWithInteger:[blog_s integerValue]];
			RFBoolean* publish = [[RFBoolean alloc] initWithBool:YES];

			NSString* post_format = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogFormat"];
			NSString* post_category = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogCategory"];

			NSArray* params;
			NSString* method_name;

			if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogApp"] isEqualToString:@"WordPress"]) {
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
						[UIAlertView uuShowOneButtonAlert:@"Error Sending Post" message:s button:@"OK" completionHandler:NULL];
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
		
		if ([self prefersExternalBlog] && ![self hasMicropubBlog]) {
			if (s.length > 0) {
				s = [s stringByAppendingString:@"\n\n"];
			}
			
			for (RFPhoto* photo in self.attachedPhotos) {
				s = [s stringByAppendingFormat:@"<img src=\"%@\" width=\"%.0f\" height=\"%.0f\" />", photo.publishedURL, 600.0, 600.0];
			}
		}

		[self uploadText:s];
	}
}

- (void) uploadPhoto:(RFPhoto *)photo completion:(void (^)())handler
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
		if ([self hasSnippetsBlog] && ![self prefersExternalBlog]) {
			RFClient* client = [[RFClient alloc] initWithPath:@"/micropub/media"];
			NSDictionary* args = @{
			};
			[client uploadImageData:d named:@"file" httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
				NSDictionary* headers = response.httpResponse.allHeaderFields;
				NSString* image_url = headers[@"Location"];
				RFDispatchMainAsync (^{
					if (image_url == nil) {
						[UIAlertView uuShowOneButtonAlert:@"Error Uploading Photo" message:@"Photo URL was blank." button:@"OK" completionHandler:NULL];
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
		else if ([self hasMicropubBlog]) {
			NSString* micropub_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubMediaEndpoint"];
			RFMicropub* client = [[RFMicropub alloc] initWithURL:micropub_endpoint];
			NSDictionary* args = @{
			};
			[client uploadImageData:d named:@"file" httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
				NSDictionary* headers = response.httpResponse.allHeaderFields;
				NSString* image_url = headers[@"Location"];
				RFDispatchMainAsync (^{
					if (image_url == nil) {
						[UIAlertView uuShowOneButtonAlert:@"Error Uploading Photo" message:@"Photo URL was blank." button:@"OK" completionHandler:NULL];
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
			NSString* xmlrpc_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogEndpoint"];
			NSString* blog_s = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogID"];
			NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogUsername"];
			NSString* password = [SSKeychain passwordForService:@"ExternalBlog" account:@"default"];
			
			NSNumber* blog_id = [NSNumber numberWithInteger:[blog_s integerValue]];
			NSString* filename = [[[[NSString uuGenerateUUIDString] lowercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@""] stringByAppendingPathExtension:@"jpg"];
			
			if (!blog_id || !username || !password) {
				[UIAlertView uuShowOneButtonAlert:@"Error Uploading Photo" message:@"Your blog settings were not saved correctly. Try signing out and trying again." button:@"OK" completionHandler:NULL];
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
						[UIAlertView uuShowOneButtonAlert:@"Error Uploading Photo" message:s button:@"OK" completionHandler:NULL];
						[self hideProgressHeader];
						self.photoButton.hidden = NO;
					}
					else {
						NSString* image_url = [[xmlrpc.responseParams firstObject] objectForKey:@"link"];
						if (image_url == nil) {
							[UIAlertView uuShowOneButtonAlert:@"Error Uploading Photo" message:@"Photo URL was blank." button:@"OK" completionHandler:NULL];
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
			self.progressHeaderTopConstraint.constant = 62.0;
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
		self.progressHeaderTopConstraint.constant = 62.0;
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

- (BOOL) dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session
{
	return [session canLoadObjectsOfClass:[UIImage class]];
}

- (UIDropProposal *) dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session
{
	UIDropProposal* proposal = [[UIDropProposal alloc] initWithDropOperation:UIDropOperationCopy];
	return proposal;
}

- (void) dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session
{
	[session loadObjectsOfClass:[UIImage class] completion:^(NSArray* objects) {
		NSMutableArray* new_photos = [self.attachedPhotos mutableCopy];
		BOOL too_many_photos = NO;
		
		for (UIImage* img in objects) {
			if (new_photos.count < 10) {
				UIImage* new_img = [img uuScaleToWidth:1200];
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
			[UIAlertView uuShowOneButtonAlert:@"Only 10 Photos Added" message:@"The first 10 photos were added to your post." button:@"OK" completionHandler:NULL];
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

@end
