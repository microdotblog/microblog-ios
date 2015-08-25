//
//  RFOptionsController.h
//  Snippets
//
//  Created by Manton Reece on 8/25/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFOptionsController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSString* postID;

- (instancetype) initWithPostID:(NSString *)postID;
- (void) attachToView:(UIView *)view atRect:(CGRect)rect;

@end
