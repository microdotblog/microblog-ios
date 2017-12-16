//
//  RFPostController.h
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>

@interface RFPostController : UIViewController <UITextViewDelegate, UIDropInteractionDelegate, UITextFieldDelegate, NSLayoutManagerDelegate>

@property (strong, nonatomic) IBOutlet UITextView* textView;
@property (strong, nonatomic) IBOutlet UILabel* remainingField;
@property (strong, nonatomic) IBOutlet UILabel* blognameField;
@property (strong, nonatomic) IBOutlet UIButton* photoButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* networkSpinner;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* bottomConstraint;
@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;
@property (strong, nonatomic) IBOutlet UIView* progressHeaderView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* progressHeaderHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* progressHeaderTopConstraint;
@property (strong, nonatomic) IBOutlet UILabel* progressHeaderField;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* titleHeaderHeightConstraint;
@property (strong, nonatomic) IBOutlet UITextField* titleField;
@property (strong, nonatomic) IBOutlet UIView* editingBar;
@property (strong, nonatomic) IBOutlet UIButton* markdownBoldButton;
@property (strong, nonatomic) IBOutlet UIButton* markdownItalicsButton;
@property (strong, nonatomic) IBOutlet UIButton* markdownLinkButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* photoButtonLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* photoBarHeightConstraint;

@property (assign, nonatomic) BOOL isSent;
@property (assign, nonatomic) BOOL isReply;
@property (strong, nonatomic) NSString* replyPostID;
@property (strong, nonatomic) NSString* replyUsername;
@property (strong, nonatomic) NSString* initialText;
@property (strong, nonatomic) NSArray* attachedPhotos; // RFPhoto
@property (strong, nonatomic) NSArray* queuedPhotos; // RFPhoto
@property (strong, nonatomic) id textStorage;

- (instancetype) initWithText:(NSString *)text;
- (instancetype) initWithReplyTo:(NSString *)postID replyUsername:(NSString *)username;
- (instancetype) initWithAppExtensionContext:(NSExtensionContext*)extensionContext;

@end
