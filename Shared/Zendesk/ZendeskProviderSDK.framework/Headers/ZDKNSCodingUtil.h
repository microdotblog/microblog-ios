/*
 *
 *  ZDKNSCodingUtil.h
 *  ZendeskSDK
 *
 *  Created by Zendesk on 25/11/2014.  
 *
 *  Copyright (c) 2014 Zendesk. All rights reserved.
 *
 *  By downloading or using the Zendesk Mobile SDK, You agree to the Zendesk Terms
 *  of Service https://www.zendesk.com/company/terms and Application Developer and API License
 *  Agreement https://www.zendesk.com/company/application-developer-and-api-license-agreement and
 *  acknowledge that such terms govern Your use of and access to the Mobile SDK.
 *
 */

#import <Foundation/Foundation.h>

@interface ZDKNSCodingUtil : NSObject

+ (void)encodeWithCoder:(NSCoder *)aCoder forInstance:(NSObject *)instance ;

+ (void)decodeWithCoder:(NSCoder *)aDecoder forInstance:(NSObject *)instance ;


@end
