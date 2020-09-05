//
//  RFAccountsController.h
//  Micro.blog
//
//  Created by Manton Reece on 9/4/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFAccountsController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UIView* containerView;

@property (strong, nonatomic) NSArray* accounts;

@end

NS_ASSUME_NONNULL_END
