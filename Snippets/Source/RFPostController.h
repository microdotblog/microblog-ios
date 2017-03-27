//
//  RFPostController.h
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFPostController : UIViewController <UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UITextView* textView;
@property (strong, nonatomic) IBOutlet UILabel* remainingField;
@property (strong, nonatomic) IBOutlet UILabel* blognameField;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* bottomConstraint;
@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;

@property (assign, nonatomic) BOOL isReply;
@property (strong, nonatomic) NSString* replyPostID;
@property (strong, nonatomic) NSString* replyUsername;
@property (strong, nonatomic) NSArray* attachedPhotos; // RFPhoto

- (instancetype) initWithReplyTo:(NSString *)postID replyUsername:(NSString *)username;

@end
