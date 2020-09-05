//
//  RFBookmarkController.h
//  Micro.blog
//
//  Created by Manton Reece on 9/5/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFBookmarkController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField* urlField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;

@end

NS_ASSUME_NONNULL_END
