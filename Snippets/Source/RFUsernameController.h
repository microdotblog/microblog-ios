//
//  RFUsernameController.h
//  Micro.blog
//
//  Created by Manton Reece on 9/9/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFUsernameController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField* usernameField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* networkSpinner;

@property (strong, nonatomic) NSString* appleUserID;
@property (strong, nonatomic) NSString* appleIdentityToken;

- (instancetype) initWithUserID:(NSString *)userID identityToken:(NSString *)identityToken;

@end

NS_ASSUME_NONNULL_END
