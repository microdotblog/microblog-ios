//
//  UIBarButtonItem+Extras.h
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Extras)

+ (UIBarButtonItem *) rf_barButtonWithImageNamed:(NSString *)imageName target:(id)target action:(SEL)action;
- (UIImage *) rf_customImage;
- (void) rf_setCustomImage:(UIImage *)img;

@end
