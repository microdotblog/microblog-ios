//
//  RFUserController.h
//  Snippets
//
//  Created by Manton Reece on 11/15/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFTimelineController.h"

@interface RFUserController : RFTimelineController

@property (strong, nonatomic) NSString* username;

- (instancetype) initWithEndpoint:(NSString *)endpoint username:(NSString *)username;

@end
