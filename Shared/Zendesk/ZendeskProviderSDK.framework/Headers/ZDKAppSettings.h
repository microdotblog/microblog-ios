/*
 *
 *  ZDKAppSettings.h
 *  ZendeskSDK
 *
 *  Created by Zendesk on 16/10/2014.  
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
#import "ZDKCoding.h"

@class ZDKRateMyAppSettings, ZDKContactUsSettings, ZDKConversationsSettings, ZDKHelpCenterSettings;

@interface ZDKAppSettings : ZDKCoding


/**
 * Settings model object associated with the remote configuration of Rate My App component within your Zendesk instance.
 *
 *  @since 0.9.3.1
 */
@property (nonatomic, strong, readonly) ZDKRateMyAppSettings *rateMyAappSettings;


/**
 * Settings model object associated with the remote configuration of Conversations component within your Zendesk instance.
 *
 *  @since 0.9.3.1
 */
@property (nonatomic, strong, readonly) ZDKConversationsSettings *conversationsSettings;


/**
 * Settings model object associated with the remote configuration of Contact component within your Zendesk instance.
 *
 *  @since 0.9.3.1
 */
@property (nonatomic, strong, readonly) ZDKContactUsSettings *contactUsSettings;


/**
 * Settings model object associated with the remote configuration of Help Center component within your Zendesk instance.
 *
 *  @since 0.9.3.1
 */
@property (nonatomic, strong, readonly) ZDKHelpCenterSettings *helpCenterSettings;


/**
 *  Authentication type, anonymous or jwt.
 *
 *  @since 0.9.3.1
 */
@property (nonatomic, copy, readonly) NSString *authentication;


/**
 *  Initialize with a dictionary representation.
 *
 *  @since 0.9.3.1
 *
 *  @param dictionary a dictionary with settings data.
 *
 *  @return A new instance.
 */
- (id) initWithDictionary: (NSDictionary *) dictionary;

@end
