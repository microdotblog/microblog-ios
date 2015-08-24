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
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* bottomConstraint;

@property (assign, nonatomic) BOOL isReply;

- (instancetype) initWithReplyTo:(id)postID;

@end
