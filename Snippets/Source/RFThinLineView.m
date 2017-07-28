//
//  RFThinLineView.m
//  Snippets
//
//  Created by Manton Reece on 8/22/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFThinLineView.h"

@implementation RFThinLineView

- (id) initWithCoder:(NSCoder *)inDecoder
{
	self = [super initWithCoder:inDecoder];
	if (self) {
		[self setupOffsetFromTop];
		[self setupLineColor];
	}
	
	return self;
}

- (id) initWithFrame:(CGRect)inFrame
{
	self = [super initWithFrame:inFrame];
	if (self) {
		[self setupLineColor];
	}
	
	return self;
}

- (void) setupOffsetFromTop
{
	self.offset = 0.0;
}

- (void) setupLineColor
{
	self.lineColor = self.backgroundColor;
	self.backgroundColor = [UIColor clearColor];
}

- (void) drawRect:(CGRect)visRect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect r = self.bounds;

	[[UIColor clearColor] set];
	CGContextFillRect (context, r);

	r.size.height = 0.5;
	r.origin.y += self.offset;
	
	[self.lineColor set];
	CGContextFillRect (context, r);
}

@end

#pragma mark -

@implementation RFBottomLineView

- (void) setupOffsetFromTop
{
	self.offset = 0.5;
}

@end

#pragma mark -

@implementation RFVerticalLineView

- (void) drawRect:(CGRect)visRect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect r = self.bounds;

	[[UIColor clearColor] set];
	CGContextFillRect (context, r);

	r.size.width = 0.5;
	r.origin.x += self.offset;
	
	[self.lineColor set];
	CGContextFillRect (context, r);
}

@end
