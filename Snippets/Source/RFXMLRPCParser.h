//
//  RFXMLRPCParser.h
//  Snippets
//
//  Created by Manton Reece on 8/30/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFXMLRPCParser : NSObject

@property (strong, nonatomic) NSData* responseData;

- (instancetype) initWithResponseData:(NSData *)data;

@end
