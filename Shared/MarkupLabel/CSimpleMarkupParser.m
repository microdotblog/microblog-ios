//
//  CSimpleMarkupParser.m
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

#import "CSimpleMarkupParser.h"

NSString *const kSimpleHTMLParserErrorDomain = @"kSimpleHTMLParserErrorDomain";

@interface CSimpleMarkupTag ()
@property (readwrite, nonatomic) NSString *name;
@property (readwrite, nonatomic) NSDictionary *attributes;
@end

#pragma mark -

@interface CSimpleMarkupParser ()
@end

#pragma mark -

@implementation CSimpleMarkupParser

- (id)init
	{
	if ((self = [super init]) != NULL)
		{
        _openTagHandler = ^(CSimpleMarkupTag *tag, NSArray *tagStack) {};
        _closeTagHandler = ^(CSimpleMarkupTag *tag, NSArray *tagStack) {};
        _textHandler = ^(NSString *text, NSArray *tagStack) {};
        _whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		}
	return(self);
	}

- (NSString *)stringForEntity:(NSString *)inEntity
    {
    static NSDictionary *sEntities = NULL;
    static dispatch_once_t sOnceToken;
    dispatch_once(&sOnceToken, ^{
        sEntities = @{
			@"quot": @"\"",
            @"amp": @"&",
            @"apos": @"'",
            @"lt": @"<",
            @"gt": @">",
            @"nbsp": [NSString stringWithFormat:@"%C", (unichar)0xA0],
//            @"nbsp": @"\uA0", ???
			};
        });

    NSString *theString = sEntities[inEntity];

    return(theString);
    }

- (BOOL)parseString:(NSString *)inString error:(NSError **)outError
    {
    @autoreleasepool
        {
        NSMutableCharacterSet *theCharacterSet = [self.whitespaceCharacterSet mutableCopy];
        [theCharacterSet addCharactersInString:@"<&"];
        [theCharacterSet invert];

        NSScanner *theScanner = [[NSScanner alloc] initWithString:inString];
        theScanner.charactersToBeSkipped = NULL;

        NSMutableArray *theTagStack = [NSMutableArray array];
        NSMutableString *theString = [NSMutableString string];

        BOOL theLastCharacterWasWhitespace = NO;

        while ([theScanner isAtEnd] == NO)
            {
            @autoreleasepool
                {
                NSString *theRun = NULL;
                NSString *theTagName = NULL;
                NSDictionary *theAttributes = NULL;

                if ([self scanner:theScanner scanCloseMarkupTag:&theTagName] == YES)
                    {
                    CSimpleMarkupTag *theTag = [[CSimpleMarkupTag alloc] init];
                    theTag.name = theTagName;
                    
                    if (theString.length > 0)
                        {
                        theLastCharacterWasWhitespace = [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[theString characterAtIndex:theString.length - 1]];
                        self.textHandler(theString, theTagStack);
                        }
                    theString = [NSMutableString string];

                    self.closeTagHandler(theTag, theTagStack);

                    NSUInteger theIndex = [theTagStack indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) { return([[obj name] isEqualToString:theTagName]); }];
                    if (theIndex == NSNotFound)
                        {
                        if (outError)
                            {
                            NSDictionary *theUserInfo = @{NSLocalizedDescriptionKey: @"Stack underflow"};
                            *outError = [NSError errorWithDomain:kSimpleHTMLParserErrorDomain code:kSimpleHTMLParserErrorCode_StackUnderflow userInfo:theUserInfo];
                            }
                        return(NO);
                        }

                    [theTagStack removeObjectsInRange:(NSRange){ .location = theIndex, .length = theTagStack.count - theIndex }];
                    }
                else if ([self scanner:theScanner scanOpenMarkupTag:&theTagName attributes:&theAttributes] == YES)
                    {
                    CSimpleMarkupTag *theTag = [[CSimpleMarkupTag alloc] init];
                    theTag.name = theTagName;
                    theTag.attributes = theAttributes;

                    if (theString.length > 0)
                        {
                        theLastCharacterWasWhitespace = NO;
                        self.textHandler(theString, theTagStack);
                        theString = [NSMutableString string];
                        }

                    if ([theTagName isEqualToString:@"br"])
                        {
                        theLastCharacterWasWhitespace = YES;
                        self.textHandler(@"\n", theTagStack);
                        theString = [NSMutableString string];
                        }
                    else
                        {
                        self.openTagHandler(theTag, theTagStack);

                        [theTagStack addObject:theTag];
                        }
                    }
                else if ([self scanner:theScanner scanStandaloneMarkupTag:&theTagName attributes:&theAttributes] == YES)
                    {
                    CSimpleMarkupTag *theTag = [[CSimpleMarkupTag alloc] init];
                    theTag.name = theTagName;
                    theTag.attributes = theAttributes;

                    if (theString.length > 0)
                        {
                        theLastCharacterWasWhitespace = NO;
                        self.textHandler(theString, theTagStack);
                        theString = [NSMutableString string];
                        }

                    if ([theTagName isEqualToString:@"br"])
                        {
                        theLastCharacterWasWhitespace = YES;
                        self.textHandler(@"\n", theTagStack);
                        theString = [NSMutableString string];
                        }
                    else
                        {
                        self.openTagHandler(theTag, theTagStack);
                        self.closeTagHandler(theTag, theTagStack);
                        }
                    }
                else if ([theScanner scanString:@"&" intoString:NULL] == YES)
                    {
                    NSString *theEntity = NULL;
                    if ([theScanner scanUpToString:@";" intoString:&theEntity] == NO)
                        {
                        if (outError)
                            {
                            NSDictionary *theUserInfo = @{NSLocalizedDescriptionKey: @"& not followed by ;"};
                            *outError = [NSError errorWithDomain:kSimpleHTMLParserErrorDomain code:kSimpleHTMLParserErrorCode_MalformedEntity userInfo:theUserInfo];
                            }
                        return(NO);
                        }
                    if ([theScanner scanString:@";" intoString:NULL] == NO)
                        {
                        if (outError)
                            {
                            NSDictionary *theUserInfo = @{NSLocalizedDescriptionKey: @"& not followed by ;"};
                            *outError = [NSError errorWithDomain:kSimpleHTMLParserErrorDomain code:kSimpleHTMLParserErrorCode_MalformedEntity userInfo:theUserInfo];
                            }
                        return(NO);
                        }

                    if (theString.length > 0)
                        {
                        theLastCharacterWasWhitespace = [self.whitespaceCharacterSet characterIsMember:[theString characterAtIndex:theString.length - 1]];
                        self.textHandler(theString, theTagStack);
                        theString = [NSMutableString string];
                        }

                    NSString *theEntityString = [self stringForEntity:theEntity];
                    if (theEntityString.length > 0)
                        {
                        self.textHandler(theEntityString, theTagStack);
                        theLastCharacterWasWhitespace = NO;
                        }
                    }
                else if ([theScanner scanCharactersFromSet:self.whitespaceCharacterSet intoString:NULL])
                    {
                    if (theLastCharacterWasWhitespace == NO)
                        {
                        [theString appendString:@" "];
                        theLastCharacterWasWhitespace = YES;
                        }
                    }
                else if ([theScanner scanCharactersFromSet:theCharacterSet intoString:&theRun])
                    {
                    [theString appendString:theRun];
                    theLastCharacterWasWhitespace = [self.whitespaceCharacterSet characterIsMember:[theString characterAtIndex:theString.length - 1]];
                    }
                else
                    {
                    if (outError)
                        {
                        NSDictionary *theUserInfo = @{
							NSLocalizedDescriptionKey: @"Unknown error occured!",
                            @"character": @(theScanner.scanLocation),
                            @"markup": inString
							};
                        *outError = [NSError errorWithDomain:kSimpleHTMLParserErrorDomain code:kSimpleHTMLParserErrorCode_UnknownError userInfo:theUserInfo];
                        }
                    return(NO);
                    }
                }
            }

        if (theString.length > 0)
            {
            // TODO this is never used - what is for?
            theLastCharacterWasWhitespace = [self.whitespaceCharacterSet characterIsMember:[theString characterAtIndex:theString.length - 1]];

            self.textHandler(theString, theTagStack);
            }
        }
        
    return(YES);
    }

- (BOOL)scanner:(NSScanner *)inScanner scanOpenMarkupTag:(NSString **)outTag attributes:(NSDictionary **)outAttributes
    {
    NSUInteger theSavedScanLocation = inScanner.scanLocation;
    NSCharacterSet *theSavedCharactersToBeSkipped = inScanner.charactersToBeSkipped;

    if ([inScanner scanString:@"<" intoString:NULL] == NO)
        {
        inScanner.scanLocation = theSavedScanLocation;
        inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }

    inScanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    NSString *theTag = NULL;
    if ([inScanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&theTag] == NO)
        {
        inScanner.scanLocation = theSavedScanLocation;
        inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }

    NSMutableDictionary *theAttributes = [NSMutableDictionary dictionary];
    while (inScanner.isAtEnd == NO)
        {
        NSString *theAttributeName = NULL;
        if ([inScanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&theAttributeName] == NO)
            {
            break;
            }

        id theAttributeValue = [NSNull null];

        if ([inScanner scanString:@"=" intoString:NULL] == YES)
            {
            if ([inScanner scanString:@"\"" intoString:NULL] == NO)
                {
                inScanner.scanLocation = theSavedScanLocation;
                inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
                return(NO);
                }

            [inScanner scanUpToString:@"\"" intoString:&theAttributeValue];

            if ([inScanner scanString:@"\"" intoString:NULL] == NO)
                {
                inScanner.scanLocation = theSavedScanLocation;
                inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
                return(NO);
                }
            }

        theAttributes[theAttributeName] = theAttributeValue;
        }

    if ([inScanner scanString:@">" intoString:NULL] == NO)
        {
        inScanner.scanLocation = theSavedScanLocation;
        inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }

    if (outTag)
        {
        *outTag = theTag;
        }

    if (outAttributes && [theAttributes count] > 0)
        {
        *outAttributes = [theAttributes copy];
        }

    inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
    return(YES);
    }

- (BOOL)scanner:(NSScanner *)inScanner scanCloseMarkupTag:(NSString **)outTag
    {
    NSUInteger theSavedScanLocation = inScanner.scanLocation;
    NSCharacterSet *theSavedCharactersToBeSkipped = inScanner.charactersToBeSkipped;

    NSString *theTag = NULL;

    if ([inScanner scanString:@"</" intoString:NULL] == NO)
        {
        inScanner.scanLocation = theSavedScanLocation;
        inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }
        
    inScanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    if ([inScanner scanUpToString:@">" intoString:&theTag] == NO)
        {
        inScanner.scanLocation = theSavedScanLocation;
        inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;

        return(NO);
        }

    if ([inScanner scanString:@">" intoString:NULL] == NO)
        {
        inScanner.scanLocation = theSavedScanLocation;
        inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }

    if (outTag)
        {
        *outTag = theTag;
        }

    inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
    return(YES);
    }

- (BOOL)scanner:(NSScanner *)inScanner scanStandaloneMarkupTag:(NSString **)outTag attributes:(NSDictionary **)outAttributes;
    {
    NSUInteger theSavedScanLocation = inScanner.scanLocation;
    NSCharacterSet *theSavedCharactersToBeSkipped = inScanner.charactersToBeSkipped;

    if ([inScanner scanString:@"<" intoString:NULL] == NO)
        {
        inScanner.scanLocation = theSavedScanLocation;
        inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }

    inScanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    NSString *theTag = NULL;
    if ([inScanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&theTag] == NO)
        {
        inScanner.scanLocation = theSavedScanLocation;
        inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }

    NSMutableDictionary *theAttributes = [NSMutableDictionary dictionary];
    while (inScanner.isAtEnd == NO)
        {
        NSString *theAttributeName = NULL;
        if ([inScanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&theAttributeName] == NO)
            {
            break;
            }

        id theAttributeValue = [NSNull null];

        if ([inScanner scanString:@"=" intoString:NULL] == YES)
            {
            if ([inScanner scanString:@"\"" intoString:NULL] == NO)
                {
                inScanner.scanLocation = theSavedScanLocation;
                inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
                return(NO);
                }

            [inScanner scanUpToString:@"\"" intoString:&theAttributeValue];

            if ([inScanner scanString:@"\"" intoString:NULL] == NO)
                {
                inScanner.scanLocation = theSavedScanLocation;
                inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
                return(NO);
                }
            }

        theAttributes[theAttributeName] = theAttributeValue;
        }

    if ([inScanner scanString:@"/>" intoString:NULL] == NO)
        {
        inScanner.scanLocation = theSavedScanLocation;
        inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }

    if (outTag)
        {
        *outTag = theTag;
        }

    if (outAttributes && [theAttributes count] > 0)
        {
        *outAttributes = [theAttributes copy];
        }

    inScanner.charactersToBeSkipped = theSavedCharactersToBeSkipped;
    return(YES);
    }

@end

#pragma mark - 

@implementation CSimpleMarkupTag

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (%@, %@)", [super description], self.name, self.attributes]);
    }

@end
