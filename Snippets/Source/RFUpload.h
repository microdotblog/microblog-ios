//
//  RFUpload.h
//  Micro.blog
//
//  Created by Manton Reece on 8/14/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFUpload : NSObject

@property (strong) UIImage* cachedImage;
@property (strong) NSString* url;
@property (assign) NSInteger width;
@property (assign) NSInteger height;
@property (strong) NSDate* createdAt;

- (NSString *) filename;

@end

NS_ASSUME_NONNULL_END
