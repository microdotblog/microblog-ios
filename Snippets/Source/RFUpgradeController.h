//
//  RFUpgradeController.h
//  Micro.blog
//
//  Created by Manton Reece on 4/1/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFUpgradeController : UIViewController

@property (strong, nonatomic) IBOutlet UIView* containerView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;
@property (strong, nonatomic) IBOutlet UILabel* blogField;

@property (assign, nonatomic) BOOL canUpload;

@end

NS_ASSUME_NONNULL_END
