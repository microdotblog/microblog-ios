//
//	UIColor+Conveniences.h
//	Morsel
//
//	Created by Jonathan Wight on 12/12/12.
//	Copyright 2012 Jonathan Wight. All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without modification, are
//	permitted provided that the following conditions are met:
//
//	   1. Redistributions of source code must retain the above copyright notice, this list of
//	      conditions and the following disclaimer.
//
//	   2. Redistributions in binary form must reproduce the above copyright notice, this list
//	      of conditions and the following disclaimer in the documentation and/or other materials
//	      provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY JONATHAN WIGHT ``AS IS'' AND ANY EXPRESS OR IMPLIED
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//	FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JONATHAN WIGHT OR
//	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//	ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//	The views and conclusions contained in the software and documentation are those of the
//	authors and should not be interpreted as representing official policies, either expressed
//	or implied, of Jonathan Wight.

#import <Foundation/Foundation.h>

#import <CoreGraphics/CoreGraphics.h>

/**
 *  Utility class for creating color objects (either UIColor or NSColor) from strings.
 *
 *  The follow strings all represent the color green and can be understood by this class:
 *  "0F0", "00FF00", "#00FF00", "rgb(0,100%,0), rgb(0,255,0), rgba(0,255,0,1.0), hsl(120,100%,100%)"
 *
 */
@interface CColorConverter : NSObject

+ (instancetype)sharedInstance;

/**
 *  Parses the color as defined by inString and returns a dictionary containing the color model name, channel and alpha information.
 *  This is used to provide common cross-platform (iOS & Mac OS X) implementations.
 */
- (NSDictionary *)colorDictionaryWithString:(NSString *)inString error:(NSError **)outError;

@end

#pragma mark -

#if TARGET_OS_IPHONE == 1

#import <UIKit/UIKit.h>

@interface CColorConverter (UIColor)
- (UIColor *)colorWithColorDictionary:(NSDictionary *)inDictionary error:(NSError **)outError;
- (UIColor *)colorWithString:(NSString *)inString error:(NSError **)outError;
@end

@interface UIColor (CColorConverter)
+ (UIColor *)colorWithString:(NSString *)inString error:(NSError **)outError;
@end
#endif /* TARGET_OS_IPHONE == 1 */
