//
//  RFPostController.h
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImagePicker/ImagePicker-Swift.h>

@interface RFPostController : UIViewController <UITextViewDelegate, ImagePickerDelegate>

@property (strong, nonatomic) IBOutlet UITextView* textView;
@property (strong, nonatomic) IBOutlet UILabel* remainingField;
@property (strong, nonatomic) IBOutlet UILabel* blognameField;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* bottomConstraint;

@property (assign, nonatomic) BOOL isReply;
@property (strong, nonatomic) NSString* replyPostID;
@property (strong, nonatomic) NSString* replyUsername;

- (instancetype) initWithReplyTo:(NSString *)postID replyUsername:(NSString *)username;

@end
