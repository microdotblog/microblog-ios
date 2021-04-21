//
//  RFHighlight.h
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFHighlight : NSObject

@property (strong, nonatomic) NSNumber* highlightID;
@property (strong, nonatomic) NSString* selectionText;
@property (strong, nonatomic) NSString* linkTitle;
@property (strong, nonatomic) NSString* linkURL;
@property (strong, nonatomic) NSDate* createdAt;

@end

NS_ASSUME_NONNULL_END
