//
//  RFPopupNotificationViewController.h
//  Micro.blog
//
//  Created by Jonathan Hays on 5/17/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFPopupNotificationViewController : UIViewController

+ (void) show:(NSString*)body fromUsername:(NSString *)username inController:(UIViewController*) controller completionBlock:(void(^)(void))completionBlock;

	@property (nonatomic, strong) IBOutlet UILabel* messageLabel;
	@property (nonatomic, strong) IBOutlet UIImageView* profileImageView;
@property (nonatomic, copy) void (^completionHandler)(void);

@end
