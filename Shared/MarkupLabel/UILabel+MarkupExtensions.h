//
//  UILabel+MarkupExtensions.h
//  CoreTextHTML
//
//  Created by Jonathan Wight on 3/13/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import <UIKit/UIKit.h>

@class CMarkupTransformer;

/**
 *  Adds markup support to the stock UILabel class.
 */
@interface UILabel (MarkupExtensions)

+ (void)setDefaultMarkupTransformer:(CMarkupTransformer *)inDefaultMarkupTransformer;

/**
 *  The CMarkupTransformer to use in the setMarkup: method. If you do not provide an explicit transformer for each instant it uses the default transformer instead. See setDefaultMarkupTransformer:.
 */
@property (readwrite, nonatomic, strong) CMarkupTransformer *markupTransformer;

/**
 *  Uses markupTransformer to convert the provided markup text into an NSAttributedString, then sets the targets attributedString property.
 */
- (void)setMarkup:(NSString *)inMarkup;

@end
