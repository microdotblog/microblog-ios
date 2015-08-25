//
//  RFOptionsController.h
//  Snippets
//
//  Created by Manton Reece on 8/25/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFOptionsController : UIViewController <UIPopoverPresentationControllerDelegate>

- (void) attachToView:(UIView *)view atRect:(CGRect)rect;

@end
