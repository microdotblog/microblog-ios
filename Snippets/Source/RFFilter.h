//
//  RFFilter.h
//  Micro.blog
//
//  Created by Manton Reece on 3/26/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFFilter : NSObject

@property (strong) NSString* name;
@property (strong) NSString* ciFilter;

- (UIImage *) filterImage:(UIImage *)image;

@end
