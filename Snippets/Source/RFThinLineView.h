//
//  RFThinLineView.h
//  Snippets
//
//  Created by Manton Reece on 8/22/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFThinLineView : UIView

@property (strong, nonatomic) UIColor* lineColor;
@property (assign, nonatomic) CGFloat offset;

- (void) setupLineColor;

@end

@interface RFTopLineView : RFThinLineView
{
}

@end

@interface RFBottomLineView : RFThinLineView
{
}

@end

@interface RFVerticalLineView : RFThinLineView
{
}

@end
