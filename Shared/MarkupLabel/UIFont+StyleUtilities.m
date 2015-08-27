//
//  StyleUtilities.m
//  TouchCode
//
//  Created by Jonathan Wight on 07/12/11.
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

#import "UIFont+StyleUtilities.h"

@implementation UIFont (StyleUtilities)

+ (NSSet *)featuresForFontName:(NSString *)inFontName
    {
    NSMutableSet *theFeatures = nil;
        
    NSScanner *theScanner = [[NSScanner alloc] initWithString:inFontName];

    if ([theScanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:NULL] == NO)
        {
        NSLog(@"Could not scan font name");
        return(NULL);
        }

    [theScanner scanString:@"-" intoString:NULL];

    theFeatures = [NSMutableSet set];

    while([theScanner isAtEnd] == NO)
        {
        NSString *theLetter;
        [theScanner scanUpToCharactersFromSet:[NSCharacterSet lowercaseLetterCharacterSet] intoString:&theLetter];

        NSString *theRemainder;
        [theScanner scanUpToCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet] intoString:&theRemainder];

        [theFeatures addObject:[theLetter stringByAppendingString:theRemainder]];
        }

    return(theFeatures);
    }

- (UIFont *)boldFont
    {
    if (self == [UIFont systemFontOfSize:self.pointSize]) return [UIFont boldSystemFontOfSize:self.pointSize];
        
    for (NSString *theFontName in [UIFont fontNamesForFamilyName:self.familyName])
        {
        NSSet *theFeatures = [UIFont featuresForFontName:theFontName];
        if (theFeatures.count == 1 && [theFeatures containsObject:@"Bold"])
            {
            return([UIFont fontWithName:theFontName size:self.pointSize]);
            }
        }

    NSLog(@"No bold font found in %@ for %@", [UIFont fontNamesForFamilyName:self.familyName], self);

    return(NULL);
    }

- (UIFont *)italicFont
    {
    if (self == [UIFont systemFontOfSize:self.pointSize]) return [UIFont italicSystemFontOfSize:self.pointSize];
        
    for (NSString *theFontName in [UIFont fontNamesForFamilyName:self.familyName])
        {
        NSSet *theFeatures = [UIFont featuresForFontName:theFontName];
        if (theFeatures.count == 1 && [theFeatures containsObject:@"Italic"])
            {
            return([UIFont fontWithName:theFontName size:self.pointSize]);
            }
        }

    return([self obliqueFont]);
    }

- (UIFont *)boldItalicFont
    {
    for (NSString *theFontName in [UIFont fontNamesForFamilyName:self.familyName])
        {
        NSSet *theFeatures = [UIFont featuresForFontName:theFontName];
        if (theFeatures.count == 2 && [theFeatures containsObject:@"Bold"] && [theFeatures containsObject:@"Italic"])
            {
            return([UIFont fontWithName:theFontName size:self.pointSize]);
            }
        }

    return([self boldObliqueFont]);
    }

- (UIFont *)obliqueFont
    {
    for (NSString *theFontName in [UIFont fontNamesForFamilyName:self.familyName])
        {
        NSSet *theFeatures = [UIFont featuresForFontName:theFontName];
        if (theFeatures.count == 1 && [theFeatures containsObject:@"Oblique"])
            {
            return([UIFont fontWithName:theFontName size:self.pointSize]);
            }
        }

    NSLog(@"No Oblique font found in %@", [UIFont fontNamesForFamilyName:self.familyName]);

    return(NULL);
    }

- (UIFont *)boldObliqueFont
    {
    for (NSString *theFontName in [UIFont fontNamesForFamilyName:self.familyName])
        {
        NSSet *theFeatures = [UIFont featuresForFontName:theFontName];
        if (theFeatures.count == 2 && [theFeatures containsObject:@"Bold"] && [theFeatures containsObject:@"Oblique"])
            {
            return([UIFont fontWithName:theFontName size:self.pointSize]);
            }
        }

    NSLog(@"No bold/oblique font found in %@ for %@", [UIFont fontNamesForFamilyName:self.familyName], self.familyName);

    return(NULL);
    }



@end
