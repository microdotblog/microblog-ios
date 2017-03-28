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
#import "RFMacros.h"
#import "RFXMLRPCParser.h"
#import "RFXMLRPCRequest.h"
#import "UIBarButtonItem+Extras.h"
#import "NSString+Extras.h"
#import "UILabel+MarkupExtensions.h"
#import "UUAlert.h"
#import "SSKeychain.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

static NSString* const kPhotoCellIdentifier = @"PhotoCell";

@implementation RFPostController

- (instancetype) init
{
	self = [super initWithNibName:@"Post" bundle:nil];
	if (self) {
		self.attachedPhotos = @[];
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
	[self setupNotifications];
	[self setupBlogName];
	[self setupCollectionView];
	
	if (self.isReply) {
		self.photoButton.hidden = YES;
	}
	else if (![self hasSnippetsBlog] || [self prefersExternalBlog]) {
		self.photoButton.hidden = YES;
	}
}

- (void) viewDidAppear:(BOOL)animated
{
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

- (void) setupText
{
	if (self.replyUsername) {
		self.textView.text = [NSString stringWithFormat:@"@%@ ", self.replyUsername];
	}
	
	[self updateRemainingChars];
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attachPhotoNotification:) name:kAttachPhotoNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) setupBlogName
{
	if (self.isReply) {
		self.blognameField.hidden = YES;
	}
	else {
		if ([self hasSnippetsBlog]) {
			self.blognameField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"AccountDefaultSite"];
		}
		else {
			NSString* endpoint_s = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalBlogEndpoint"];
			NSURL* endpoint_url = [NSURL URLWithString:endpoint_s];
			self.blognameField.text = endpoint_url.host;
		}
	}
}

- (void) setupCollectionView
{
	[self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCell" bundle:nil] forCellWithReuseIdentifier:kPhotoCellIdentifier];
}

- (void) updateRemainingChars
{
	NSInteger max_chars = 280;
	NSInteger num_chars = self.textView.text.length;
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
	UIImage* img = [notification.userInfo objectForKey:kAttachPhotoKey];
	RFPhoto* photo = [[RFPhoto alloc] initWithThumbnail:img];
	NSMutableArray* new_photos = [self.attachedPhotos mutableCopy];
	[new_photos addObject:photo];
	self.attachedPhotos = new_photos;
	[self.collectionView reloadData];
	
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) keyboardWillShowNotification:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    CGSize kb_size = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

	[UIView animateWithDuration:0.3 animations:^{
		self.bottomConstraint.constant = kb_size.height;
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

- (void) textViewDidChange:(UITextView *)textView
{
	[self updateRemainingChars];
}

- (BOOL) hasSnippetsBlog
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"HasSnippetsBlog"];
}

- (BOOL) prefersExternalBlog
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"ExternalBlogIsPreferred"];
}

#pragma mark -

- (IBAction) sendPost:(id)sender
{
	if (self.attachedPhotos.count > 0) {
		RFPhoto* photo = [self.attachedPhotos firstObject];
		CGSize sz = photo.thumbnailImage.size;
		[self uploadPhoto:photo completion:^{
			NSString* s = self.textView.text;
			if (s.length > 0) {
				s = [s stringByAppendingString:@"\n\n"];
			}
			s = [s stringByAppendingFormat:@"<img src=\"%@\" width=\"%.0f\" height=\"%.0f\" style=\"height: auto\" />", photo.publishedURL, 600.0, 600.0];
			[self uploadText:s];
		}];
	}
	else {
		[self uploadText:self.textView.text];
	}
}

- (IBAction) close:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction) showPhotos:(id)sender
{
	RFPhotosController* photos_controller = [[RFPhotosController alloc] init];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:photos_controller];
	
	nav_controller.view.opaque = NO;
	nav_controller.view.backgroundColor = [UIColor clearColor];
	nav_controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	
	[self presentViewController:nav_controller animated:YES completion:NULL];
}

- (void) uploadText:(NSString *)text
{
	self.navigationItem.rightBarButtonItem.enabled = NO;

	if (self.isReply) {
		RFClient* client = [[RFClient alloc] initWithPath:@"/posts/reply"];
		NSDictionary* args = @{
			@"id": self.replyPostID,
			@"text": text
		};
		[client postWithParams:args completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				[Answers logCustomEventWithName:@"Sent Reply" customAttributes:nil];
				[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
			});
		}];
	}
	else {
		if ([self hasSnippetsBlog] && ![self prefersExternalBlog]) {
			RFClient* client = [[RFClient alloc] initWithPath:@"/micropub"];
			NSDictionary* args = @{
				@"content": text
			};
			[client postWithParams:args completion:^(UUHttpResponse* response) {
				RFDispatchMainAsync (^{
					[Answers logCustomEventWithName:@"Sent Post" customAttributes:nil];
					[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
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
				content[@"post_content"] = post_text;
				if (post_format.length > 0) {
					content[@"post_format"] = post_format;
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
						self.navigationItem.rightBarButtonItem.enabled = YES;
					}
					else {
						[Answers logCustomEventWithName:@"Sent External" customAttributes:nil];
						[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
					}
				}));
			}];
		}
	}
}

- (void) uploadPhoto:(RFPhoto *)photo completion:(void (^)())handler
{
	UIImage* img = photo.thumbnailImage;
	NSData* d = UIImageJPEGRepresentation (img, 0.6);
	if (d && [self hasSnippetsBlog] && ![self prefersExternalBlog]) {
		RFClient* client = [[RFClient alloc] initWithPath:@"/micropub/media"];
		NSDictionary* args = @{
		};
		[client uploadImageData:d named:@"file" httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
			NSDictionary* headers = response.httpResponse.allHeaderFields;
			NSString* image_url = headers[@"Location"];
			photo.publishedURL = image_url;
			RFDispatchMainAsync (^{
				[Answers logCustomEventWithName:@"Uploaded Photo" customAttributes:nil];
				handler();
			});
		}];
	}
	else {
		// ...
	}
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
