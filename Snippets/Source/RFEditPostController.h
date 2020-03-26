//
//  RFEditPostController.h
//  Micro.blog
//
//  Created by Manton Reece on 3/25/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RFPost;

@interface RFEditPostController : UIViewController <UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField* titleField;
@property (strong, nonatomic) IBOutlet UITextView* textView;
@property (strong, nonatomic) IBOutlet UILabel* remainingField;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* bottomConstraint;

@property (strong, nonatomic) RFPost* post;
@property (strong, nonatomic) id textStorage;
@property (strong, nonatomic) NSLayoutManager* textLayout;

@end

NS_ASSUME_NONNULL_END
