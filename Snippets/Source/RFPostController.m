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
#import "UIView+Extras.h"
#import "UUAlert.h"
#import "UUString.h"
#import "UUImage.h"
#import "UUHttpSession.h"
#import "SSKeychain.h"
#import "MMMarkdown.h"
#import "RFUserCache.h"
#import "RFAutoCompleteCache.h"
#import "RFAutoCompleteCollectionViewCell.h"
#import "SDAVAssetExportSession.h"
#import "RFSelectBlogViewController.h"
#import "RFUpgradeController.h"
#import "UnzipKit.h"
#import "UITraitCollection+Extras.h"
#import "HTMLParser.h"

//#import "Microblog-Swift.h"

@import MobileCoreServices;

static NSString* const kPhotoCellIdentifier = @"PhotoCell";

@interface RFPostController()
	@property (atomic, strong) NSMutableArray* autoCompleteData;
	@property (nonatomic, strong) NSString* activeReplacementString;
	@property (assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@implementation RFPostController

- (instancetype) init
{
	self = [super initWithNibName:@"Post" bundle:nil];
	if (self) {
		self.attachedPhotos = @[];
		self.edgesForExtendedLayout = UIRectEdgeTop;
		self.selectedCategories = [NSSet set];
		self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
		self.channel = @"default";
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
	
		[RFAutoCompleteCache addAutoCompleteString:username];
	}
	
	return self;
}

- (instancetype) initWithChannel:(NSString *)channel
{
	self = [self init];
	if (self) {
		self.channel = channel;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	if (@available(iOS 13.0, *)) {
		self.modalInPresentation = YES;
	}

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

	self.progressHeaderTopConstraint.constant = 0;
	self.progressHeaderHeightConstraint.constant = 0.0;
	self.progressHeaderView.alpha = 0.0;

	[self setupBlogName];
	
	if (self.extensionContext)
	{
		if ([RFSettings needsExternalBlogSetup] && ![RFSettings hasSnippetsBlog])
		{
			[UUAlertViewController setActiveViewController:self];
		
			[UUAlertViewController uuShowOneButtonAlert:nil message:@"You need to configure your blog settings first. Please launch Micro.blog and sign in to your account." button:@"OK" completionHandler:^(NSInteger buttonIndex)
			 {
				 [UUAlertViewController setActiveViewController:nil];
			 
				 [self.extensionContext completeRequestReturningItems:nil completionHandler:^(BOOL expired)
				  {
				  }];
			 }];
		}
	}
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if (self.feedsController) {
		self.selectedCategories = self.feedsController.selectedCategories;
		self.isDraft = self.feedsController.isDraft;

		[self setupNavigation];
	}

	RFDispatchSeconds (0.1, ^{
		[self.textView becomeFirstResponder];
	});
}

- (void) setupNavigation
{
	NSString* post_button = @"Post";
	if (self.isReply) {
		self.title = @"New Reply";
	}
	else if ([self.channel isEqualToString:@"pages"]) {
		self.title = @"New Page";
		post_button = @"Add Page";
	}
	else if (self.isDraft) {
		self.title = @"New Draft";
		post_button = @"Save";
	}
	else {
		self.title = @"New Post";
	}

	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_closeBarButtonWithTarget:self action:@selector(close:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:post_button style:UIBarButtonItemStylePlain target:self action:@selector(sendPost:)];
}

- (void) setupFont
{
	#ifndef SHARING_EXTENSION
		NSString* content_size = [UIApplication sharedApplication].preferredContentSizeCategory;
		[RFSettings setPreferredContentSize:content_size];
	#endif

	self.textView.font = [UIFont systemFontOfSize:[UIFont rf_preferredPostingFontSize]];
}

- (void) setupText
{
	if (UIAccessibilityIsVoiceOverRunning()) {
		// disable highlighting
		self.textStorage = [[NSTextStorage alloc] init];
	}
	else {
		self.textStorage = [[RFHighlightingTextStorage alloc] init];
	}

	// setup layout and container
	NSLayoutManager* text_layout = [[NSLayoutManager alloc] init];
	CGRect r = self.textView.frame;
	CGSize container_size = CGSizeMake (r.size.width, CGFLOAT_MAX);
	NSTextContainer* text_container = [[NSTextContainer alloc] initWithSize:container_size];
	text_container.widthTracksTextView = YES;
	[text_layout addTextContainer:text_container];
	[self.textStorage addLayoutManager:text_layout];

	// recreate text view
	UITextView* old_textview = self.textView;
	UIView* old_superview = old_textview.superview;
	self.textView = [[UITextView alloc] initWithFrame:r textContainer:text_container];
	self.textView.delegate = self;
	[old_superview insertSubview:self.textView belowSubview:self.remainingField];

	// constraints
	self.textView.translatesAutoresizingMaskIntoConstraints = NO;
	NSArray* old_constraints = old_superview.constraints;
	for (NSLayoutConstraint* old_c in old_constraints) {
		if (old_c.firstItem == old_textview) {
			NSLayoutConstraint* c = [NSLayoutConstraint constraintWithItem:self.textView attribute:old_c.firstAttribute relatedBy:old_c.relation toItem:old_c.secondItem attribute:old_c.secondAttribute multiplier:old_c.multiplier constant:old_c.constant];
			[c setActive:YES];
		}
		else if (old_c.secondItem == old_textview) {
			NSLayoutConstraint* c = [NSLayoutConstraint constraintWithItem:old_c.firstItem attribute:old_c.firstAttribute relatedBy:old_c.relation toItem:self.textView attribute:old_c.secondAttribute multiplier:old_c.multiplier constant:old_c.constant];
			[c setActive:YES];
		}
	}

	// remove old view
	[old_textview removeFromSuperview];

	[self setupFont];

	NSString* s = @"";
	if (self.replyUsername) {
		s = [NSString stringWithFormat:@"@%@ ", self.replyUsername];
	}
	else if (self.initialText) {
		s = self.initialText;
	}
	else if (!self.extensionContext) {
		s = [RFSettings draftText];
		if (s.length > 280) {
			self.titleField.text = [RFSettings draftTitle];
		}
	}

	NSDictionary* attr_info = @{
		NSFontAttributeName: [UIFont systemFontOfSize:[UIFont rf_preferredPostingFontSize]]
	};
	NSAttributedString* attr_s = [[NSAttributedString alloc] initWithString:s attributes:attr_info];
	self.textView.attributedText = attr_s;

	[self.textStorage setAttributedString:attr_s];
//	[self.textStorage addLayoutManager:self.textView.layoutManager];
//	[self.textStorage addLayoutManager:self.textLayout];

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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attachVideoNotification:) name:kAttachVideoNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosDidCloseNotification:) name:kPhotosDidCloseNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferredContentSize:) name:UIContentSizeCategoryDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupBlogName) name:kPostToBlogSelectedNotification object:nil];
	
	if (@available(iOS 11, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAutoCompleteNotification:) name:kRFFoundUserAutoCompleteNotification object:nil];
    }
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
//	UIImage* img = [UIImage uuSolidColorImage:self.editingBar.backgroundColor];
//	[self.photoButton setBackgroundImage:img forState:UIControlStateNormal];
//	[self.markdownBoldButton setBackgroundImage:img forState:UIControlStateNormal];
//	[self.markdownItalicsButton setBackgroundImage:img forState:UIControlStateNormal];
//	[self.markdownLinkButton setBackgroundImage:img forState:UIControlStateNormal];
//	[self.settingsButton setBackgroundImage:img forState:UIControlStateNormal];

	if (self.isReply || [self isPage]) {
		self.photoButtonLeftConstraint.constant = -34;
		self.settingsButtonRightConstraint.constant = -34;
	}
}

- (void) setupCollectionView
{
    self.autoCompleteHeightConstraint.constant = 0.0;
    
	self.autoCompleteCollectionView.prefetchingEnabled = NO;
	[self.autoCompleteCollectionView registerNib:[UINib nibWithNibName:@"RFAutoCompleteCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"RFAutoCompleteCollectionViewCell"];
	[self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCell" bundle:nil] forCellWithReuseIdentifier:kPhotoCellIdentifier];
	self.photoBarHeightConstraint.constant = 0;
	
	UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	flowLayout.itemSize = CGSizeMake(50.0, 50.0);
	self.collectionView.collectionViewLayout = flowLayout;
	
	flowLayout = (UICollectionViewFlowLayout*)self.autoCompleteCollectionView.collectionViewLayout;
	flowLayout.itemSize = UICollectionViewFlowLayoutAutomaticSize;
	flowLayout.estimatedItemSize = CGSizeMake(150,36);
	self.autoCompleteCollectionView.collectionViewLayout = flowLayout;
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
	if (!self.isReply && (([self currentProcessedMarkup].length > 280) || [self isPage])) {
		if (self.titleHeaderHeightConstraint.constant == 0) {
			self.isAnimatingTitle = YES;
		}
		self.titleHeaderHeightConstraint.constant = 64;
	}
	else {
		if (self.titleHeaderHeightConstraint.constant == 64) {
			self.isAnimatingTitle = YES;
		}
		self.titleHeaderHeightConstraint.constant = 0;
	}
}

- (BOOL) isPage
{
	return [self.channel isEqualToString:@"pages"];
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
	UIKeyCommand* send_key = [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierCommand action:@selector(sendPost:) discoverabilityTitle:@"Send Post"];

	[commands addObject:close_key];
	[commands addObject:send_key];
	
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

- (void) handleAutoCompleteNotification:(NSNotification*)notification
{
	NSDictionary* dictionary = notification.object;
	NSArray* array = dictionary[@"array"];
	self.activeReplacementString = dictionary[@"string"];

	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.autoCompleteCollectionView setContentOffset:CGPointZero animated:FALSE];
		
		CGFloat size = 36.0;
		if (!array.count)
		{
			size = 0.0;
			
			if (self.activeReplacementString.length > 3)
			{
				NSString* cleanUserName = self.activeReplacementString;
				if ([cleanUserName uuStartsWithSubstring:@"@"])
				{
					cleanUserName = [cleanUserName substringFromIndex:1];
				}
				
				NSString* path = [NSString stringWithFormat:@"/users/search?q=%@", cleanUserName];  //https://micro.blog/users/search?q=jon]
				RFClient* client = [[RFClient alloc] initWithPath:path];
				[client getWithQueryArguments:nil completion:^(UUHttpResponse *response)
				{
					if (response.parsedResponse)
					{
						NSMutableArray* matchingUsernames = [NSMutableArray array];
						NSArray* array = response.parsedResponse;
						for (NSDictionary* userDictionary in array)
						{
							NSString* userName = userDictionary[@"username"];
							[matchingUsernames addObject:userName];
						}
						
						NSDictionary* dictionary = @{ @"string" : self.activeReplacementString, @"array" : matchingUsernames };
						[[NSNotificationCenter defaultCenter] postNotificationName:kRFFoundUserAutoCompleteNotification object:dictionary];
					}
				}];
			}
		}
		
		if (size != self.autoCompleteHeightConstraint.constant) {
			[UIView animateWithDuration:0.25 animations:^{
				self.autoCompleteHeightConstraint.constant = size;
				[self.view layoutIfNeeded];
			}];
		}
		
		if (size > 0) {
			@synchronized(self.autoCompleteData)
			{
				[self.autoCompleteData removeAllObjects];
				self.autoCompleteData = [NSMutableArray array];

				NSUInteger count = array.count;
			
				for (NSUInteger i = 0; i < count; i++)
				{
					NSString* username = [array objectAtIndex:i];
					UIImage* image = [UIImage uuSolidColorImage:[UIColor lightGrayColor]];
					NSMutableDictionary* userDictionary = [NSMutableDictionary dictionaryWithDictionary:@{ 	@"username" : username,
																											@"avatar" : image }];

					NSString* profile_s = [NSString stringWithFormat:@"https://micro.blog/%@/avatar.jpg", username];
				
					//Check the cache for the avatar...
					image = [RFUserCache avatar:[NSURL URLWithString:profile_s] completionHandler:^(UIImage * _Nonnull image)
					{
						[userDictionary setObject:image forKey:@"avatar"];
							
						dispatch_async(dispatch_get_main_queue(), ^{
							[self.autoCompleteCollectionView reloadData];
						});
					}];
				
					if (image)
					{
						[userDictionary setObject:image forKey:@"avatar"];
					}
			
				
					[self.autoCompleteData addObject:userDictionary];
				}
			}
			
			[self.autoCompleteCollectionView reloadData];
		}
	});
}

- (void) autoCompleteSelected:(NSString*)username
{
	[UIView animateWithDuration:0.25 animations:^{
		self.autoCompleteHeightConstraint.constant = 0.0;
		[self.view layoutIfNeeded];
	}];
	
	NSString* stringToReplace = [self.activeReplacementString lowercaseString];
	NSString* replacementString = [username lowercaseString];
	NSString* remainingString = [replacementString stringByReplacingOccurrencesOfString:stringToReplace withString:@""];
	remainingString = [remainingString stringByAppendingString:@" "];
	
	[self.textView insertText:remainingString];
	//self.textView.selectedTextRange = nil;
	
	[self hideAutocompleteBar];
}

- (void) hideAutocompleteBar
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		NSDictionary* dictionary = @{ @"string" : @"", @"array" : @[] };
		[[NSNotificationCenter defaultCenter] postNotificationName:kRFFoundUserAutoCompleteNotification object:dictionary];
	});
}

- (void) attachPhotoNotification:(NSNotification *)notification
{
	[self setupNavigation];

	UIImage* img = [notification.userInfo objectForKey:kAttachPhotoKey];
	RFPhoto* photo = [[RFPhoto alloc] initWithThumbnail:img];
	photo.isPNG = [[notification.userInfo objectForKey:kAttachIsPNGKey] boolValue];
	NSMutableArray* new_photos = [self.attachedPhotos mutableCopy];
	[new_photos addObject:photo];
	self.attachedPhotos = new_photos;
	[self.collectionView reloadData];
	
	[self dismissViewControllerAnimated:YES completion:^{
		[self showPhotosBar];
	}];
}

- (void) attachVideoNotification:(NSNotification*)notification
{
	[self setupNavigation];
	
	NSURL* url = [notification.userInfo objectForKey:kAttachVideoKey];
	UIImage* thumbnail = [notification.userInfo objectForKey:kAttachVideoThumbnailKey];

	RFPhoto* photo = [[RFPhoto alloc] initWithVideo:url thumbnail:thumbnail];
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
	__block CGFloat kb_bottom = kb_r.size.height - self.view.safeAreaInsets.bottom;

	if (!RFIsPhone()) {
		// delay to make sure form sheet is in position
		RFDispatchSeconds(0.4, ^{
			// for iPad, take into account modal form sheet position too
			UIWindow* win = self.view.window;
			CGRect view_r = [self.view convertRect:self.view.frame toView:win];
			CGFloat bottom_inset = kb_r.size.height - (win.frame.size.height - view_r.size.height - view_r.origin.y);
			if (bottom_inset > 0) {
				kb_bottom = bottom_inset;
			}
			else {
				kb_bottom = 0;
			}
		
			[UIView animateWithDuration:0.3 animations:^{
				self.bottomConstraint.constant = kb_bottom;
				[self.view layoutIfNeeded];
			}];
		});
	}
	else {
		[UIView animateWithDuration:0.3 animations:^{
			self.bottomConstraint.constant = kb_bottom;
			[self.view layoutIfNeeded];
		}];
	}
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

	self.isAnimatingTitle = NO;
	
	[UIView animateWithDuration:0.3 animations:^{
		[self updateTitleHeader];
		if (self.isAnimatingTitle) {
			[self.view layoutIfNeeded];
		}
	} completion:^(BOOL finished) {
		if ([self currentProcessedMarkup].length <= 280) {
			self.titleField.text = @"";
			[self updateRemainingChars];
		}
	}];
}

#pragma mark -

- (void) beginBackgrounding
{
#ifndef SHARING_EXTENSION
	self.backgroundTaskIdentifier = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"SunlitBackgroundTask" expirationHandler:^
	{
		[UIApplication.sharedApplication endBackgroundTask:self.backgroundTaskIdentifier];
		self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
	}];
#endif
}

- (void) endBackgrounding
{
#ifndef SHARING_EXTENSION
	[UIApplication.sharedApplication endBackgroundTask:self.backgroundTaskIdentifier];
	self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
#endif
}


- (BOOL) canPublish:(RFPhoto*)photo
{
	BOOL can_publish = YES;

	if (photo.videoURL)
	{
		if ([RFSettings hasSnippetsBlog] && ![RFSettings prefersExternalBlog]) {
			NSDictionary* info = [RFSettings selectedBlogInfo];
			if (info && ![[info objectForKey:@"microblog-audio"] boolValue]) {
				can_publish = NO;
			}
		}
	}
	return can_publish;
}

- (void) upgradeVideo:(void (^)(BOOL canUpload))handler
{
	RFUpgradeController* upgrade_controller = [[RFUpgradeController alloc] init];
	upgrade_controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	upgrade_controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	upgrade_controller.handler = handler;
	[self presentViewController:upgrade_controller animated:YES completion:NULL];
}

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
	
	BOOL needsUpgrade = NO;
	for (RFPhoto* photo in self.attachedPhotos)
	{
		if (![self canPublish:photo])
		{
			needsUpgrade = YES;
		}
	}
	
	if (needsUpgrade)
	{
		[self upgradeVideo:^(BOOL canUpload) {
			if (canUpload)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self beginPost];
				});
			}
		}];
	}
	else
	{
		[self beginPost];
	}
}

- (void) beginPost
{
	[self beginBackgrounding];

	NSString* s = [self currentText];

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
	if (!self.isReply && !self.isSent && !self.extensionContext) {
		[RFSettings setDraftTitle:[self currentTitle]];
		[RFSettings setDraftText:[self currentText]];
	}
	
	for (RFPhoto* photo in self.attachedPhotos) {
		if (photo.videoURL) {
			[[NSFileManager defaultManager] removeItemAtURL:photo.videoURL error:nil];
		}
	}

	if (![self checkForAppExtensionClose])
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kClosePostingNotification object:self];
	}
	else {
		[self.extensionContext completeRequestReturningItems:nil completionHandler:^(BOOL expired)
		 {
		 }];
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
	NSString* insert_s = @"";
	NSString* url = [UIPasteboard generalPasteboard].string;
	if ([url uuStartsWithSubstring:@"http"]) {
		insert_s = url;
	}
	
	UITextRange* text_r = self.textView.selectedTextRange;
	if ([text_r isEmpty]) {
		[self.textView insertText:[NSString stringWithFormat:@"[](%@)", insert_s]];
		r = self.textView.selectedRange;
		r.location = r.location - 3 - insert_s.length;
		self.textView.selectedRange = r;
	}
	else {
		[self replaceSelectionBySurrounding:@[ @"[", [NSString stringWithFormat:@"](%@)", insert_s] ]];
		r = self.textView.selectedRange;
		if (insert_s.length == 0) {
			r.location = r.location - 1;
		}
		self.textView.selectedRange = r;
	}
}

- (IBAction) blogHostnamePressed:(id)sender
{
	if ([RFSettings hasSnippetsBlog] || [RFSettings hasMicropubBlog]) {
		NSArray* blogs = [RFSettings blogList];
		if (blogs.count > 1) {
			UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Blogs" bundle:nil];
			UIViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"BlogsNavigation"];
			RFSelectBlogViewController* select_controller = [controller.childViewControllers firstObject];
			select_controller.isCancelable = YES;
			[self presentViewController:controller animated:YES completion:NULL];
		}
	}
}

- (IBAction) settingsPressed:(id)sender
{
	self.feedsController = [[RFFeedsController alloc] initWithSelectedCategories:self.selectedCategories];
	[self.navigationController pushViewController:self.feedsController animated:YES];
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

- (NSString *) currentStatus
{
	if (self.isDraft) {
		return @"draft";
	}
	else {
		return @"published";
	}
}

- (void) uploadText:(NSString *)text
{
	if (self.isReply) {
		[self showProgressHeader:@"Now sending your reply..."];
		RFClient* client = [[RFClient alloc] initWithPath:@"/posts/reply"];
		NSMutableDictionary* args = [NSMutableDictionary dictionary];
		[args setObject:self.replyPostID forKey:@"id"];
		[args setObject:text forKey:@"text"];

		[client postWithParams:args completion:^(UUHttpResponse* response) {
			[self endBackgrounding];
			
			RFDispatchMainAsync (^{
				[self close:nil];
			});
		}];
	}
	else {
		if (self.isDraft) {
			[self showProgressHeader:@"Saving your draft..."];
		}
		else {
			[self showProgressHeader:@"Now publishing to your microblog..."];
		}
		
		if ([RFSettings hasSnippetsBlog] && ![RFSettings prefersExternalBlog]) {
			RFClient* client = [[RFClient alloc] initWithPath:@"/micropub"];
			NSMutableDictionary* args = [NSMutableDictionary dictionary];
			NSString* uid = [RFSettings selectedBlogUid];
			if (uid) {
				[args setObject:uid forKey:@"mp-destination"];
			}

			[args setObject:self.channel forKey:@"mp-channel"];
			[args setObject:self.titleField.text forKey:@"name"];
			[args setObject:text forKey:@"content"];
			
			if ([self.attachedPhotos count] > 0) {
				NSMutableArray* photo_urls = [NSMutableArray array];
				NSMutableArray* photo_alts = [NSMutableArray array];
				NSMutableArray* video_urls = [NSMutableArray array];
				NSMutableArray* video_alts = [NSMutableArray array];

				for (RFPhoto* photo in self.attachedPhotos) {
					if (photo.videoURL) {
						[video_urls addObject:photo.publishedURL];
						[video_alts addObject:photo.altText];
					}
					else {
						[photo_urls addObject:photo.publishedURL];
						[photo_alts addObject:photo.altText];
					}
				}
				
				[args setObject:photo_urls forKey:@"photo[]"];
				[args setObject:photo_alts forKey:@"mp-photo-alt[]"];
				[args setObject:video_urls forKey:@"video[]"];
				[args setObject:video_alts forKey:@"mp-video-alt[]"];
			}

			[args setObject:[self currentStatus] forKey:@"post-status"];
			if (self.selectedCategories.count > 0) {
				[args setObject:[self.selectedCategories allObjects] forKey:@"category[]"];
			}

			[client postWithParams:args completion:^(UUHttpResponse* response) {
				[self endBackgrounding];

				RFDispatchMainAsync (^{
					if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
						[self hideProgressHeader];
						NSString* msg = response.parsedResponse[@"error_description"];
						[UUAlertViewController uuShowOneButtonAlert:@"Error Sending Post" message:msg button:@"OK" completionHandler:NULL];
					}
					else {
						[self close:nil];
					}
				});
			}];
		}
		else if ([RFSettings hasMicropubBlog]) {
			NSString* micropub_endpoint = [RFSettings externalMicropubPostingEndpoint];
			RFMicropub* client = [[RFMicropub alloc] initWithURL:micropub_endpoint];
			NSMutableDictionary* args = [NSMutableDictionary dictionary];
			if ([self.attachedPhotos count] > 0) {
				NSMutableArray* photo_urls = [NSMutableArray array];
				NSMutableArray* photo_alts = [NSMutableArray array];
				NSMutableArray* video_urls = [NSMutableArray array];
				NSMutableArray* video_alts = [NSMutableArray array];
				
				for (RFPhoto* photo in self.attachedPhotos) {
					if (photo.videoURL) {
						[video_urls addObject:photo.publishedURL];
						[video_alts addObject:photo.altText];
					}
					else {
						[photo_urls addObject:photo.publishedURL];
						[photo_alts addObject:photo.altText];
					}
				}
				

				[args setObject:@"entry" forKey:@"h"];
				[args setObject:self.titleField.text forKey:@"name"];
				[args setObject:text forKey:@"content"];
				[args setObject:photo_urls forKey:@"photo[]"];
				[args setObject:photo_alts forKey:@"mp-photo-alt[]"];
				[args setObject:video_urls forKey:@"video[]"];
				[args setObject:video_alts forKey:@"mp-video-alt[]"];
			}
			else {
				[args setObject:@"entry" forKey:@"h"];
				[args setObject:self.titleField.text forKey:@"name"];
				[args setObject:text forKey:@"content"];
			}

			[args setObject:[self currentStatus] forKey:@"post-status"];
			if (self.selectedCategories.count > 0) {
				[args setObject:[self.selectedCategories allObjects] forKey:@"category[]"];
			}

			[client postWithParams:args completion:^(UUHttpResponse* response) {
				[self endBackgrounding];

				RFDispatchMainAsync (^{
					if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
						[self hideProgressHeader];
						NSString* msg = response.parsedResponse[@"error_description"];
						[UUAlertViewController uuShowOneButtonAlert:@"Error Sending Post" message:msg button:@"OK" completionHandler:NULL];
					}
					else {
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
				
				if (self.isDraft) {
					content[@"post_status"] = @"draft";
				}
				else {
					content[@"post_status"] = @"publish";
				}
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

				[self endBackgrounding];

				RFXMLRPCParser* xmlrpc = [RFXMLRPCParser parsedResponseFromData:response.rawResponse];
				RFDispatchMainAsync ((^{
					if (xmlrpc.responseFault) {
						NSString* s = [NSString stringWithFormat:@"%@ (error: %@)", xmlrpc.responseFault[@"faultString"], xmlrpc.responseFault[@"faultCode"]];
						[UUAlertViewController uuShowOneButtonAlert:@"Error Sending Post" message:s button:@"OK" completionHandler:NULL];
						[self hideProgressHeader];
						self.photoButton.hidden = NO;
					}
					else {
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
		
		[self uploadMedia:photo completion:^{
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
				// TODO: for videos, need the actual size, thumbnail is smaller?
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
				
				if (photo.videoURL)
					s = [s stringByAppendingFormat:@"<video controls=\"controls\" playsinline=\"playsinline\" src=\"%@\" width=\"%.0f\" height=\"%.0f\" alt=\"%@\" />", photo.publishedURL, width, height, photo.altText];
				else
					s = [s stringByAppendingFormat:@"<img src=\"%@\" width=\"%.0f\" height=\"%.0f\" alt=\"%@\" />", photo.publishedURL, width, height, photo.altText];
			}
		}

		[self uploadText:s];
	}
}

- (void) uploadMedia:(RFPhoto*)photo completion:(void(^)(void))handler
{
	if (photo.videoURL) {
		[self showProgressHeader:@"Uploading video..."];
	}
	else if (self.attachedPhotos.count > 0) {
		[self showProgressHeader:@"Uploading photos..."];
	}
	else {
		[self showProgressHeader:@"Uploading photo..."];
	}

	if (photo.videoURL)
	{
		[self uploadVideo:photo completion:handler];
	}
	else {
		[self uploadPhoto:photo completion:handler];
	}
}
	
- (void) uploadVideo:(RFPhoto*)photo completion:(void(^)(void))handler
{
	NSData* d = [NSData dataWithContentsOfURL:photo.videoURL];
	if (d) {
		if ([RFSettings hasSnippetsBlog] && ![RFSettings prefersExternalBlog]) {
			RFClient* client = [[RFClient alloc] initWithPath:@"/micropub/media"];
			NSMutableDictionary* args = [NSMutableDictionary dictionary];
			NSString* uid = [RFSettings selectedBlogUid];
			if (uid)
			{
				[args setObject:uid forKey:@"mp-destination"];
			}
			
			[client uploadVideoData:d named:@"file" httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
				NSDictionary* headers = response.httpResponse.allHeaderFields;
				NSString* image_url = headers[@"Location"];
				RFDispatchMainAsync (^{
					if (image_url == nil) {
						[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Video" message:@"Video URL was blank." button:@"OK" completionHandler:NULL];
						[self hideProgressHeader];
						self.photoButton.hidden = NO;
					}
					else {
						photo.publishedURL = image_url;
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
			[client uploadVideoData:d named:@"file" httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
				NSDictionary* headers = response.httpResponse.allHeaderFields;
				NSString* image_url = headers[@"Location"];
				RFDispatchMainAsync (^{
					if (image_url == nil) {
						[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Video" message:@"Video URL was blank." button:@"OK" completionHandler:NULL];
						[self hideProgressHeader];
						self.photoButton.hidden = NO;
					}
					else {
						photo.publishedURL = image_url;
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
			NSString* filename = [[[[NSString uuGenerateUUIDString] lowercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@""] stringByAppendingPathExtension:@"mov"];
			
			if (!blog_id || !username || !password) {
				[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Video" message:@"Your blog settings were not saved correctly. Try signing out and trying again." button:@"OK" completionHandler:NULL];
				[self hideProgressHeader];
				self.photoButton.hidden = NO;
				return;
			}
			
			NSArray* params = @[ blog_id, username, password, @{
									 @"name": filename,
									 @"type": @"video/mov",
									 @"bits": d
									 }];
			NSString* method_name = @"metaWeblog.newMediaObject";
			
			RFXMLRPCRequest* request = [[RFXMLRPCRequest alloc] initWithURL:xmlrpc_endpoint];
			[request sendMethod:method_name params:params completion:^(UUHttpResponse* response) {
				RFXMLRPCParser* xmlrpc = [RFXMLRPCParser parsedResponseFromData:response.rawResponse];
				RFDispatchMainAsync ((^{
					if (xmlrpc.responseFault) {
						NSString* s = [NSString stringWithFormat:@"%@ (error: %@)", xmlrpc.responseFault[@"faultString"], xmlrpc.responseFault[@"faultCode"]];
						[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Video" message:s button:@"OK" completionHandler:NULL];
						[self hideProgressHeader];
						self.photoButton.hidden = NO;
					}
					else {
						NSString* image_url = [[xmlrpc.responseParams firstObject] objectForKey:@"url"];
						if (image_url == nil) {
							image_url = [[xmlrpc.responseParams firstObject] objectForKey:@"link"];
						}
						
						if (image_url == nil) {
							[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Video" message:@"Video URL was blank." button:@"OK" completionHandler:NULL];
							[self hideProgressHeader];
							self.photoButton.hidden = NO;
						}
						else {
							photo.publishedURL = image_url;
							handler();
						}
					}
				}));
			}];
		}
	}
}
	
- (void) uploadPhoto:(RFPhoto *)photo completion:(void (^)(void))handler
{
	UIImage* img = photo.thumbnailImage;
	NSData* d;
	NSString* filename;
	
	if (photo.isPNG) {
		d = UIImagePNGRepresentation (img);
		filename = @"image.png";
	}
	else {
		d = UIImageJPEGRepresentation (img, 0.9);
		filename = @"image.jpg";
	}
	if (d) {
		if ([RFSettings hasSnippetsBlog] && ![RFSettings prefersExternalBlog]) {
			RFClient* client = [[RFClient alloc] initWithPath:@"/micropub/media"];
			NSMutableDictionary* args = [NSMutableDictionary dictionary];
			NSString* uid = [RFSettings selectedBlogUid];
			if (uid)
			{
				[args setObject:uid forKey:@"mp-destination"];
			}
			
			[client uploadImageData:d named:@"file" filename:filename httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
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
			[client uploadImageData:d named:@"file" filename:filename httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
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
			self.progressHeaderHeightConstraint.constant = 44.0;
			self.progressHeaderTopConstraint.constant = 0;
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
		self.progressHeaderTopConstraint.constant = 0;
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

- (void) removePhoto:(RFPhoto*)photo
{
	NSMutableArray* new_photos = [self.attachedPhotos mutableCopy];
	NSUInteger index = [new_photos indexOfObject:photo];
	[new_photos removeObjectAtIndex:index];
	self.attachedPhotos = new_photos;
	[self.collectionView deleteItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:index inSection:0] ]];

	if (self.attachedPhotos.count == 0) {
		[UIView animateWithDuration:0.3 animations:^{
			self.photoBarHeightConstraint.constant = 0;
			[self.view layoutIfNeeded];
		}];
	}
}

- (void) addAltTextToPhoto:(RFPhoto*)photo
{
	__block UITextField* altTextTextField = nil;
	
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Accessibility Description" message:nil preferredStyle:UIAlertControllerStyleAlert];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		altTextTextField = textField;
		altTextTextField.text = photo.altText;
	}];
	
	[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	NSString* save_title;
	if (photo.altText.length > 0) {
		save_title = @"Update";
	}
	else {
		save_title = @"Add";
	}
	
	[alertController addAction:[UIAlertAction actionWithTitle:save_title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		NSString* altText = altTextTextField.text;
		photo.altText = altText;
	}]];
	
	[self.navigationController presentViewController:alertController animated:YES completion:nil];
}

- (void) handlePhotoTap:(RFPhoto*)photo
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	
	[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	NSString* edit_title;
	if (photo.altText.length > 0) {
		edit_title = @"Edit Description";
	}
	else {
		edit_title = @"Add Description";
	}
	
	[alertController addAction:[UIAlertAction actionWithTitle:edit_title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self addAltTextToPhoto:photo];
	}]];

	[alertController addAction:[UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
		[self removePhoto:photo];
	}]];

	NSIndexPath* path = [[self.collectionView indexPathsForSelectedItems] firstObject];
	if (path) {
		UICollectionViewLayoutAttributes* attrs = [self.collectionView layoutAttributesForItemAtIndexPath:path];

		alertController.popoverPresentationController.sourceView = self.collectionView;
		alertController.popoverPresentationController.sourceRect = attrs.frame;
	}
	
	[self.navigationController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Drag and Drop

- (BOOL) dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session NS_AVAILABLE_IOS(11.0)
{
	return [session canLoadObjectsOfClass:[UIImage class]];
}

- (UIDropProposal *) dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session NS_AVAILABLE_IOS(11.0)
{
	UIDropProposal* proposal = [[UIDropProposal alloc] initWithDropOperation:UIDropOperationCopy];
	return proposal;
}

- (void) dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session NS_AVAILABLE_IOS(11.0)
{
	[session loadObjectsOfClass:[UIImage class] completion:^(NSArray* objects) {
		NSMutableArray* new_photos = [self.attachedPhotos mutableCopy];
		BOOL too_many_photos = NO;
		
		for (UIImage* img in objects) {
			if (new_photos.count < 10) {
				RFPhoto* photo = [[RFPhoto alloc] initWithThumbnail:img];
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

#pragma mark UICollectionViewDataSource UICollectionViewDelegate

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	if (collectionView == self.autoCompleteCollectionView)
	{
		@synchronized (self.autoCompleteData) {
			return self.autoCompleteData.count;
		}
	}
	
	return self.attachedPhotos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	if (collectionView == self.autoCompleteCollectionView)
	{
		RFAutoCompleteCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RFAutoCompleteCollectionViewCell" forIndexPath:indexPath];
		@synchronized (self.autoCompleteData) {
			NSDictionary* dictionary = [self.autoCompleteData objectAtIndex:indexPath.item];
			cell.userNameLabel.text = [NSString stringWithFormat:@"@%@", dictionary[@"username"]];
			cell.userImageView.image = dictionary[@"avatar"];
		}
		return cell;
		
	}
	
	RFPhotoCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellIdentifier forIndexPath:indexPath];

	RFPhoto* photo = [self.attachedPhotos objectAtIndex:indexPath.item];
	cell.thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
	cell.thumbnailView.isAccessibilityElement = YES;
	cell.thumbnailView.accessibilityLabel = @"attached photo";
	
	[cell setupWithPhoto:photo];
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	if (collectionView == self.autoCompleteCollectionView)
	{
		@synchronized (self.autoCompleteData) {
			NSDictionary* dictionary = [self.autoCompleteData objectAtIndex:indexPath.item];
			NSString* userName = [NSString stringWithFormat:@"@%@", dictionary[@"username"]];
			[self autoCompleteSelected:userName];
		}
		return;
	}
	
	RFPhoto* photo = [self.attachedPhotos objectAtIndex:indexPath.item];
	[self handlePhotoTap:photo];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark-
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) processImageForAppExtension:(UIImage*)image withInputItems:(NSMutableArray*)inputItems
{
	UIImage* new_img = image;
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

- (void) handleVideoObject:(AVURLAsset*)asset
{
	NSError* error = nil;
	AVAssetImageGenerator* imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
	CGImageRef cgImage = [imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:&error];
	UIImage* thumbnail = [UIImage imageWithCGImage:cgImage];
	
	NSString* tempPath = NSTemporaryDirectory();
	tempPath = [tempPath stringByAppendingPathComponent:@"video.mov"];
	
	SDAVAssetExportSession* exportSession = [[SDAVAssetExportSession alloc] initWithAsset:asset];
	exportSession.outputURL = [NSURL fileURLWithPath:tempPath];
	exportSession.outputFileType = AVFileTypeAppleM4V;
	exportSession.videoSettings = [RFPhoto videoSettingsForSize:thumbnail.size];
	exportSession.audioSettings = [RFPhoto audioSettings];
	
	[exportSession exportAsynchronouslyWithCompletionHandler:^
	 {
		 RFPhoto* photo = [[RFPhoto alloc] initWithVideo:exportSession.outputURL thumbnail:thumbnail];
		 
		 NSMutableArray* new_photos = [NSMutableArray arrayWithArray:self.attachedPhotos];
		 [new_photos addObject:photo];
		 
		 dispatch_async(dispatch_get_main_queue(), ^
						{
							self.attachedPhotos = new_photos;
							[self.collectionView reloadData];
							
							[self showPhotosBar];
							
						});
		 
	 }];

}

- (void) loadExtensionVideo:(NSItemProvider*)itemProvider inputItems:(NSMutableArray*)inputItems
{
	[itemProvider loadItemForTypeIdentifier:(NSString*)kUTTypeMovie options:nil completionHandler:^(NSURL* url, NSError * _Null_unspecified err) {
		
		AVURLAsset* asset = [AVURLAsset assetWithURL:url];
		[self handleVideoObject:asset];

		if (inputItems.count)
		{
			[self processAppExtensionItems:inputItems];
		}
	}];
}

- (void) loadExtensionImage:(NSItemProvider*)itemProvider inputItems:(NSMutableArray*)inputItems
{
	if (@available(iOS 11.0, *))
	{
		[itemProvider loadInPlaceFileRepresentationForTypeIdentifier:(NSString*)kUTTypeImage completionHandler:^(NSURL * _Nullable url, BOOL isInPlace, NSError * _Nullable error)
		{
			CGFloat max_size = 1800;
			
			CFDictionaryRef options = (__bridge CFDictionaryRef) @{
				(id)kCGImageSourceCreateThumbnailFromImageAlways: (id)kCFBooleanTrue,
				(id)kCGImageSourceCreateThumbnailWithTransform: (id)kCFBooleanTrue,
				(id)kCGImageSourceThumbnailMaxPixelSize: (id)@(max_size)
			};
			
			CGImageSourceRef cg_source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
			CGImageRef cg_img = CGImageSourceCreateThumbnailAtIndex (cg_source, 0, options);
			
			UIImage* image = [UIImage imageWithCGImage:cg_img];
			
			CGImageRelease (cg_img);
			CFRelease (cg_source);

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
					else // If we get here, we have exhausted our ability to load an image...
					{
						[self processAppExtensionItems:inputItems];
					}
				}];
			}
		}];
	}
	else // If we get here, we have exhausted our ability to load an image...
	{
		[self processAppExtensionItems:inputItems];
	}
}

- (void) loadExtensionPropertyList:(NSItemProvider*)itemProvider inputItems:(NSMutableArray*)inputItems
{
	[itemProvider loadItemForTypeIdentifier:(NSString*)kUTTypePropertyList options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error)
	{
		NSDictionary* dictionary = (NSDictionary*)item;
		dictionary = dictionary[NSExtensionJavaScriptPreprocessingResultsKey];
		NSString* title = [dictionary objectForKey:@"title"];
		NSURL* url = [NSURL URLWithString:[dictionary objectForKey:@"url"]];
		NSString* text = [dictionary objectForKey:@"text"];

		dispatch_async(dispatch_get_main_queue(), ^
		{
			if (title && url && text) {
				[self insertSharedURL:url withTitle:title andText:text];
			}
			else if (title) {
				[self insertSharedText:title];
			}
			else if (url) {
				[self insertSharedURL:url withTitle:@"" andText:@""];
			}
				
			[self processAppExtensionItems:inputItems];
		});
	}];
}

- (NSString *)tempPath
{
    NSString* tempDirectory = NSTemporaryDirectory();
    tempDirectory = [tempDirectory stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    
    NSURL *url = [NSURL fileURLWithPath:tempDirectory];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:url
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:&error];
    if (error) {
        return nil;
    }
    return url.path;
}


- (void) handleZipFileContents:(NSArray*)contents
{
    for (NSFileWrapper* item in contents)
    {
        if (item.isDirectory)
        {
            NSDictionary* fileWrappers = item.fileWrappers;
            NSMutableArray* subContents = [NSMutableArray array];
            for (id key in fileWrappers)
            {
                NSFileWrapper* fileWrapper = [fileWrappers objectForKey:key];
                [subContents addObject:fileWrapper];
            }
            
            [self handleZipFileContents:subContents];
        }
        else if (item.isRegularFile)
        {
            NSString* extension = item.filename.pathExtension.lowercaseString;
            NSData* data = item.regularFileContents;
            
            if ([extension isEqualToString:@"txt"])
            {
                NSString* text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self insertSharedText:text];
                });
            }
            else {
                UIImage* image = [UIImage imageWithData:data];
                if (image)
                {
                    [self processImageForAppExtension:image withInputItems:nil];
                }
            }
        }
    }
}

- (void) loadZipFileExtension:(NSURL*)url inputItems:(NSMutableArray*)inputItems
{
    NSString* destFilePath = [self tempPath];
    NSError* archiveError = nil;
    NSError* decompressError = nil;

    UZKArchive *archive = [[UZKArchive alloc] initWithURL:url error:&archiveError];
    BOOL success = [archive extractFilesTo:destFilePath overwrite:YES progress:^(UZKFileInfo * _Nonnull currentFile, CGFloat percentArchiveDecompressed)
    {
        //NSLog(@"Decompressing %f", (float)percentArchiveDecompressed);
    }
    error:&decompressError];
    
    if (success && !decompressError)
    {
        destFilePath = [destFilePath stringByAppendingPathComponent:url.lastPathComponent];
        NSURL* url = [NSURL fileURLWithPath:destFilePath];
        
        NSError* readError = nil;
        NSFileWrapper* textBundleFileWrapper = [[NSFileWrapper alloc] initWithURL:url options:NSFileWrapperReadingImmediate error:&readError];
        if (textBundleFileWrapper && !readError)
        {
            if (textBundleFileWrapper.isDirectory)
            {
                NSDictionary* fileWrappers = textBundleFileWrapper.fileWrappers;
                NSMutableArray* subContents = [NSMutableArray array];
                for (id key in fileWrappers)
                {
                    NSFileWrapper* fileWrapper = [fileWrappers objectForKey:key];
                    [subContents addObject:fileWrapper];
                }
                
                [self handleZipFileContents:subContents];
            }
        }
    }

    [self processAppExtensionItems:inputItems];
}

- (void) loadExtensionURL:(NSItemProvider*)itemProvider inputItems:(NSMutableArray*)inputItems
{
	[itemProvider loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error)
	{
		NSURL* url = [(NSURL*)item copy];
		
        // Check for known archive extensions
        NSString* extension = [url pathExtension].lowercaseString;
        if ([extension isEqualToString:@"bearnote"] ||
            [extension isEqualToString:@"zip"] ||
            [extension isEqualToString:@"archive"])
        {
            [self loadZipFileExtension:url inputItems:inputItems];
            return;
        }
        
		AVURLAsset* asset = [AVURLAsset assetWithURL:url];
		BOOL playable = NO;
		for (AVAssetTrack* track in asset.tracks)
		{
			if (track.isPlayable) {
				playable = YES;
			}
		}
		
		if (playable)
		{
			[self handleVideoObject:asset];
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self insertSharedURL:url withTitle:@"" andText:@""];
			});
		}
	
		[self processAppExtensionItems:inputItems];

	}];
}

- (void) loadExtensionText:(NSItemProvider*)itemProvider inputItems:(NSMutableArray*)inputItems
{
	[itemProvider loadItemForTypeIdentifier:@"public.text" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error)
	{
		NSString* s = [(NSString*)item copy];
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self insertSharedText:s];
				
			[self processAppExtensionItems:inputItems];
		});
	}];
}

- (void) processAppExtensionItems:(NSMutableArray*)inputItems
{
	// Bail if there's nothing to do...
	if (!inputItems.count)
		return;
	
	NSItemProvider * itemProvider = inputItems.firstObject;
	[inputItems removeObject:itemProvider];
		
	if ([itemProvider hasItemConformingToTypeIdentifier:(NSString*)kUTTypePropertyList])
	{
		[self loadExtensionPropertyList:itemProvider inputItems:inputItems];
	}
	else if ([itemProvider hasItemConformingToTypeIdentifier:@"public.url"])
	{
		[self loadExtensionURL:itemProvider inputItems:inputItems];
	}
	else if ([itemProvider hasItemConformingToTypeIdentifier:@"public.text"])
	{
		[self loadExtensionText:itemProvider inputItems:inputItems];
	}
	else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage])
	{
		[self loadExtensionImage:itemProvider inputItems:inputItems];
	}
	else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString*)kUTTypeMovie])
	{
		[self loadExtensionVideo:itemProvider inputItems:inputItems];
	}
	else // If we got here, it means we were passed an item that we don't handle. Sort of weird, but what can we do???
	{
		[self processAppExtensionItems:inputItems];
	}
}

- (void) setupAppExtensionElements
{
	if (!self.extensionContext)
		return;
	
	// Handle alert views...
	[UUAlertViewController setActiveViewController:self];
	
	// Grab the first extension item. We really should only ever have one...
	NSExtensionItem* extensionItem = self.extensionContext.inputItems.firstObject;
	
	// Process all the attachements...
	NSMutableArray* itemsToProcess = [NSMutableArray arrayWithArray:extensionItem.attachments];
	[self processAppExtensionItems:itemsToProcess];
}

- (BOOL) checkForAppExtensionClose
{
	if (self.extensionContext)
	{
		[UUAlertViewController setActiveViewController:nil];

		[self.navigationController dismissViewControllerAnimated:NO completion:^
		{
			[self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
		}];
		return YES;
	}
	
	return NO;
}

- (void) insertSharedURL:(NSURL *)url withTitle:(NSString *)title andText:(NSString *)text
{
	NSString* s;

	if ([url.host isEqualToString:@"glass.photo"]) {
		[self insertGlassPhoto:url];
		return;
	}

	if ([RFSettings prefersPlainSharedURLs]) {
		s = [NSString stringWithFormat:@" %@", url.absoluteString];
	}
	else if (title.length > 0) {
		// work around pipe character messing up Markdown
		NSString* new_title = [title stringByReplacingOccurrencesOfString:@"|" withString:@"-"];
		s = [NSString stringWithFormat:@" [%@](%@)", new_title, url.absoluteString];
		
		if (text.length > 0) {
			s = [s stringByAppendingString:@"\n\n> "];
			s = [s stringByAppendingString:text];
		}
	}
	else {
		s = [NSString stringWithFormat:@" [%@](%@)", url.host, url.absoluteString];

		if (text.length > 0) {
			s = [s stringByAppendingString:@"\n\n> "];
			s = [s stringByAppendingString:text];
		}
	}
	
	[self.textView insertText:s];

	NSRange r = NSMakeRange (0, 0);
	self.textView.selectedRange = r;
}

- (void) insertSharedText:(NSString *)text
{
	BOOL is_markup = NO;
	
	if ([text containsString:@"]("] || [text containsString:@"/>"] || [text containsString:@"</"]) {
		is_markup = YES;
	}

	NSString* s = text;
	if (!is_markup) {
		s = [NSString stringWithFormat:@"\n\n> %@", text];
	}
	
	[self.textView insertText:s];

	NSRange r = NSMakeRange (0, 0);
	self.textView.selectedRange = r;
}

- (void) insertGlassPhoto:(NSURL *)pageURL
{
	// download web page HTML
	// extract photo reference and description
	// download photo
	
	UUHttpRequest* request = [UUHttpRequest getRequest:[pageURL absoluteString] queryArguments:NULL];
	[UUHttpSession executeRequest:request completionHandler:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSString class]]) {
			RFDispatchMain (^{
				NSString* s = response.parsedResponse;

				NSString* found_src = nil;
				NSString* found_description = nil;
				
				NSError* error = nil;
				HTMLParser* p = [[HTMLParser alloc] initWithString:s error:&error];
				if (error == nil) {
					HTMLNode* body = [p body];
					NSArray* div_tags = [body findChildTags:@"div"];
					for (HTMLNode* div_tag in div_tags) {
						NSString* class = [div_tag getAttributeNamed:@"class"];
						if ([class containsString:@"image"]) {
							NSArray* img_tags = [div_tag findChildTags:@"img"];
							HTMLNode* img_tag = [img_tags firstObject];
							if (img_tag) {
								found_src = [img_tag getAttributeNamed:@"src"];
							}
						}
						else if ([class containsString:@"meta"]) {
							NSArray* p_tags = [div_tag findChildTags:@"p"];
							for (HTMLNode* p_tag in p_tags) {
								NSString* class = [p_tag getAttributeNamed:@"class"];
								if ([class containsString:@"description"]) {
									found_description = [p_tag contents];
								}
							}
						}
					}
				}

				if (found_src) {
					NSString* new_text = @"";
					if (found_description) {
						new_text = found_description;
					}
					
					[self.textView insertText:new_text];
					[self showProgressHeader:@"Downloading photo from Glass..."];

					UUHttpRequest* request = [UUHttpRequest getRequest:found_src queryArguments:NULL];
					[UUHttpSession executeRequest:request completionHandler:^(UUHttpResponse* response) {
						if ([response.parsedResponse isKindOfClass:[UIImage class]]) {
							RFDispatchMain (^{
								UIImage* img = response.parsedResponse;
								RFPhoto* photo = [[RFPhoto alloc] initWithThumbnail:img];

								self.attachedPhotos = @[ photo ];
								[self.collectionView reloadData];

								[self showPhotosBar];
								
								RFDispatchSeconds (1, ^{
									// wait a second because sometimes it's too fast to see
									[self hideProgressHeader];
								});
							});
						}
					}];
				}
			});
		}
	}];
}

@end
