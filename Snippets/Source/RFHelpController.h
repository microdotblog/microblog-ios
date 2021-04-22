//
//  RFHelpController.h
//  Snippets
//
//  Created by Manton Reece on 8/21/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface RFHelpController : RFViewController <MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIButton* emailButton;
@property (strong, nonatomic) IBOutlet UIButton* helpButton;

@end
