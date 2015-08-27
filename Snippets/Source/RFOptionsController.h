//
//  RFOptionsController.h
//  Snippets
//
//  Created by Manton Reece on 8/25/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	kOptionsPopoverDefault = 0,
	kOptionsPopoverWithUnfavorite = 1,
	kOptionsPopoverWithDelete = 2
} RFOptionsPopoverType;

@interface RFOptionsController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView* defaultView;
@property (strong, nonatomic) IBOutlet UIView* withUnfavoriteView;
@property (strong, nonatomic) IBOutlet UIView* withDeleteView;

@property (strong, nonatomic) NSString* postID;
@property (strong, nonatomic) NSString* username;
@property (assign, nonatomic) RFOptionsPopoverType popoverType;

- (instancetype) initWithPostID:(NSString *)postID username:(NSString *)username popoverType:(RFOptionsPopoverType)popoverType;
- (void) attachToView:(UIView *)view atRect:(CGRect)rect;

@end
