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

@property (nonatomic, strong) IBOutlet NSLayoutConstraint* verticalOffsetConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* maxHeaderHeightConstraint;

@property (nonatomic, strong) IBOutlet UIView* userInfoView;
@property (nonatomic, strong) IBOutlet UIButton* moreButton;
@property (nonatomic, strong) IBOutlet UILabel* fullNameLabel;
@property (nonatomic, strong) IBOutlet UILabel* blogAddressLabel;
@property (nonatomic, strong) IBOutlet UILabel* bioLabel;
@property (nonatomic, strong) IBOutlet UIImageView* avatar;


@end
