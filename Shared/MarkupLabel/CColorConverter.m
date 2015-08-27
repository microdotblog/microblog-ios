//
//	UIColor+Conveniences.m
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

#import "CColorConverter.h"

static double StringToFloat(NSString *inString, double base);
static int hexdec(const char *hex, int len);

@interface CColorConverter ()
@end

#pragma mark -

@implementation CColorConverter

static CColorConverter *gSharedInstance = NULL;

+ (instancetype)sharedInstance
    {
    static dispatch_once_t sOnceToken = 0;
    dispatch_once(&sOnceToken, ^{
        gSharedInstance = [[self alloc] init];
        });
    return(gSharedInstance);
    }

- (NSDictionary *)colorDictionaryWithString:(NSString *)inString error:(NSError **)outError
	{
	NSDictionary *theColor = NULL;

	// ### Find rgb(), rgba(), hsl(), and hsla() style colours with values provided as integers or percentages.
	static NSRegularExpression *sRGBRegex = NULL;
	static dispatch_once_t sRGBRegexOnceToken;
	dispatch_once(&sRGBRegexOnceToken, ^{
		NSError *error = NULL;
		sRGBRegex = [NSRegularExpression regularExpressionWithPattern:@"^(rgba?|hsla?)\\(\\s*(\\d+(?:\\.\\d+)?%?)\\s*,\\s*(\\d+(?:\\.\\d+)?%?),\\s*(\\d+(?:\\.\\d+)?%?)(?:,\\s*(\\d+(?:\\.\\d+)?%?))?\\)$" options:0 error:&error];
		});

	NSTextCheckingResult *theResult = [sRGBRegex firstMatchInString:inString options:0 range:(NSRange){ .length = inString.length }];
	if (theResult != NULL)
		{
		NSString *theType = [inString substringWithRange:[theResult rangeAtIndex:1]];
		if ([[theType substringToIndex:3] isEqualToString:@"rgb"])
			{
			CGFloat R = StringToFloat([inString substringWithRange:[theResult rangeAtIndex:2]], 255.0);
			CGFloat G = StringToFloat([inString substringWithRange:[theResult rangeAtIndex:3]], 255.0);
			CGFloat B = StringToFloat([inString substringWithRange:[theResult rangeAtIndex:4]], 255.0);
			if ([theType isEqualToString:@"rgba"])
				{
                CGFloat A = StringToFloat([inString substringWithRange:[theResult rangeAtIndex:5]], 1.0);
                theColor = @{ @"type": @"RGB", @"red":@(R), @"green":@(G), @"blue":@(B), @"alpha":@(A) };
				}
            else
                {
                if ([theResult rangeAtIndex:5].location != NSNotFound)
                    {
                    return(NULL);
                    }
                theColor = @{ @"type": @"RGB", @"red":@(R), @"green":@(G), @"blue":@(B) };
                }

			}
		else if ([[theType substringToIndex:3] isEqualToString:@"hsl"])
			{
			CGFloat hue = StringToFloat([inString substringWithRange:[theResult rangeAtIndex:2]], 360.0);
			CGFloat saturation = StringToFloat([inString substringWithRange:[theResult rangeAtIndex:3]], 100.0);
			CGFloat brightness = StringToFloat([inString substringWithRange:[theResult rangeAtIndex:4]], 100.0);
			if ([theType isEqualToString:@"hsla"])
				{
                CGFloat A = 1.0;
				A = StringToFloat([inString substringWithRange:[theResult rangeAtIndex:5]], 1.0);
                theColor = @{ @"type": @"HSB", @"hue":@(hue), @"saturation":@(saturation), @"brightness":@(brightness), @"alpha":@(A) };
				}
            else
                {
                if ([theResult rangeAtIndex:5].location != NSNotFound)
                    {
                    return(NULL);
                    }
                theColor = @{ @"type": @"HSB", @"hue":@(hue), @"saturation":@(saturation), @"brightness":@(brightness) };
                }

			}

		return(theColor);
		}

	// ### Find colour by hex triplets, either 3 or 6 byte (optionally preceded by a #)
	static NSRegularExpression *sHexRegex = NULL;
	static dispatch_once_t sHexRegexOnceToken;
	dispatch_once(&sHexRegexOnceToken, ^{
		NSError *error = NULL;
		sHexRegex = [NSRegularExpression regularExpressionWithPattern:@"^#?(?:([\\da-f]{3})|([\\da-f]{6}))$" options:NSRegularExpressionCaseInsensitive error:&error];
		});

	theResult = [sHexRegex firstMatchInString:inString options:0 range:(NSRange){ .length = inString.length }];
	if (theResult != NULL)
		{
		if ([theResult rangeAtIndex:1].location != NSNotFound)
			{
			NSString *theHex = [inString substringWithRange:[theResult rangeAtIndex:1]];
			UInt32 D = hexdec([theHex UTF8String], 0);
			CGFloat R = (CGFloat)((D & 0x0F00) >> 8) / 15.0;
			CGFloat G = (CGFloat)((D & 0x00F0) >> 4) / 15.0;
			CGFloat B = (CGFloat)((D & 0x000F) >> 0) / 15.0;
			theColor = @{ @"type": @"RGB", @"red":@(R), @"green":@(G), @"blue":@(B) };
			}
		else
			{
			NSString *theHex = [inString substringWithRange:[theResult rangeAtIndex:2]];
			UInt32 D = (UInt32)hexdec([theHex UTF8String], 0);
			CGFloat R = (CGFloat)((D & 0x00FF0000) >> 16) / 255.0;
			CGFloat G = (CGFloat)((D & 0x0000FF00) >> 8) / 255.0;
			CGFloat B = (CGFloat)((D & 0x000000FF) >> 0) / 255.0;
			theColor = @{ @"type": @"RGB", @"red":@(R), @"green":@(G), @"blue":@(B) };
			}
		return(theColor);
		}

	return(theColor);
	}

@end

#pragma mark -

#if TARGET_OS_IPHONE == 1

@implementation CColorConverter (UIColor)

- (UIColor *)colorWithColorDictionary:(NSDictionary *)inDictionary error:(NSError **)outError
    {
    UIColor *theColor = NULL;

	if ([inDictionary[@"type"] isEqualToString:@"RGB"])
		{
		const CGFloat R = [inDictionary[@"red"] floatValue];
		const CGFloat G = [inDictionary[@"green"] floatValue];
		const CGFloat B = [inDictionary[@"blue"] floatValue];
		const CGFloat A = inDictionary[@"alpha"] ? [inDictionary[@"alpha"] floatValue] : 1.0f;

		theColor = [UIColor colorWithRed:R green:G blue:B alpha:A];
		}
	else if ([inDictionary[@"type"] isEqualToString:@"HSB"])
		{
		const CGFloat H = [inDictionary[@"hue"] floatValue];
		const CGFloat S = [inDictionary[@"saturation"] floatValue];
		const CGFloat B = [inDictionary[@"brightness"] floatValue];
		const CGFloat A = inDictionary[@"alpha"] ? [inDictionary[@"alpha"] floatValue] : 1.0f;

		theColor = [UIColor colorWithHue:H saturation:S brightness:B alpha:A];
		}
	return(theColor);
    }

- (UIColor *)colorWithString:(NSString *)inString error:(NSError **)outError
	{
	UIColor *theColor = NULL;
	CColorConverter *theConverter = [[CColorConverter alloc] init];
	NSDictionary *theDictionary = [theConverter colorDictionaryWithString:inString error:outError];
    theColor = [self colorWithColorDictionary:theDictionary error:outError];
    return(theColor);
	}

@end

#pragma mark -

@implementation UIColor (CColorConverter)

+ (UIColor *)colorWithString:(NSString *)inString error:(NSError **)outError
	{
	return([[CColorConverter sharedInstance] colorWithString:inString error:outError]);
	}

@end

#endif /* TARGET_OS_IPHONE == 1 */

#pragma mark -

// Adapted from http://stackoverflow.com/a/11068850
/** 
 * @brief convert a hexidecimal string to a signed long
 * will not produce or process negative numbers except 
 * to signal error.
 * 
 * @param hex without decoration, case insensative. 
 * 
 * @return -1 on error, or result (max sizeof(long)-1 bits)
 */
static int hexdec(const char *hex, int len)
    {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Winitializer-overrides"
    static const int hextable[] = {
       [0 ... 255] = -1,                     // bit aligned access into this table is considerably
       ['0'] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, // faster for most modern processors,
       ['A'] = 10, 11, 12, 13, 14, 15,       // for the space conscious, reduce to
       ['a'] = 10, 11, 12, 13, 14, 15        // signed char.
    };
    #pragma clang diagnostic pop

    int ret = 0;
    if (len > 0)
        {
        while (*hex && ret >= 0 && (len--))
            {
            ret = (ret << 4) | hextable[*hex++];
            }
        }
    else
        {
        while (*hex && ret >= 0)
            {
            ret = (ret << 4) | hextable[*hex++];
            }
        }
    return ret; 
    }

static double StringToFloat(NSString *inString, double base)
	{
	if ([inString characterAtIndex:inString.length - 1] == '%')
		{
		return([[inString substringToIndex:inString.length - 1] doubleValue] / 100.0);
		}
	else
		{
		return([inString doubleValue] / base);
		}
	}
