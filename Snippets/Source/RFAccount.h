//
//  RFAccount.h
//  Micro.blog
//
//  Created by Manton Reece on 9/5/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFAccount : NSObject

@property (strong, nonatomic) NSString* username;

+ (NSArray *) allAccounts;
+ (instancetype) defaultAccount;
- (NSString *) password;
- (NSString *) profileURL;
- (void) setDefault;

@end

NS_ASSUME_NONNULL_END
