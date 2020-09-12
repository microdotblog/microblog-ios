//
//  RFBookmarksController.h
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFTimelineController.h"

NS_ASSUME_NONNULL_BEGIN

@interface RFBookmarksController : RFTimelineController

- (instancetype) initWithEndpoint:(NSString *)endpoint title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
