//
//  RFFeed.h
//  Micro.blog
//
//  Created by Manton Reece on 2/4/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFFeed : NSObject

@property (strong) NSNumber* feedID;
@property (strong) NSString* url;
@property (strong) NSString* twitterUsername;
@property (strong) NSString* facebookName;
@property (assign) BOOL isDisabledCrossposting;
@property (assign) BOOL hasBot;

- (id) initWithResponse:(NSDictionary *)info;
- (NSString *) summary;

@end
