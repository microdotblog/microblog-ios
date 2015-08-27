//
//  CMarkupValueTransformer.h
//  TouchCode
//
//  Created by Jonathan Wight on 07/15/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
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

extern NSString *const kMarkupBoldMetaAttributeName;
extern NSString *const kMarkupItalicMetaAttributeName;
extern NSString *const kMarkupSizeAdjustmentMetaAttributeName;
extern NSString *const kMarkupFontNameMetaAttributeName;
extern NSString *const kMarkupFontSizeMetaAttributeName;
extern NSString *const kMarkupOutlineMetaAttributeName;

#pragma mark -

@protocol CMarkupTransformerContext;
@class CSimpleMarkupTag;

typedef NSDictionary *(^MarkupTagHandler)(CSimpleMarkupTag *tag, id <CMarkupTransformerContext> context);

#pragma mark -

@interface CMarkupTransformer : NSObject

@property (readwrite, nonatomic) NSCharacterSet *whitespaceCharacterSet;

- (NSAttributedString *)transformMarkup:(NSString *)value baseFont:(UIFont *)inBaseFont error:(NSError **)outError;

- (void)addStandardStyles;

- (void)addFormatDictionary:(NSDictionary *)inDictionary forTag:(NSString *)inTag;
- (void)removeFormatDictionaryForTag:(NSString *)inTag;

- (void)addHandler:(MarkupTagHandler)inHandler forTag:(NSString *)inTag;
- (void)removeHandlerForTag:(NSString *)inTag;

@end

#pragma mark -

@protocol CMarkupTransformerContext <NSObject>
@property (readonly, nonatomic) NSAttributedString *currentString;
@end
