//
//  RFXMLElementStack.h
//  Snippets
//
//  Created by Manton Reece on 9/1/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFXMLElementStack : NSObject

@property (strong, nonatomic) NSMutableArray* stackArray;

- (void) push:(id)obj;
- (id) pop;
- (id) peek;

@end
