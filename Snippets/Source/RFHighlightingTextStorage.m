//
//  TKDHighlightingTextStorage.m
//  TextKitDemo
//
//  Created by Max Seelemann on 29.09.13.
//  Copyright (c) 2013 Max Seelemann. All rights reserved.
//

#import "RFHighlightingTextStorage.h"

#import "UIFont+Extras.h"

@implementation RFHighlightingTextStorage
{
	NSMutableAttributedString *_imp;
}

- (id) init
{
	self = [super init];
	
	if (self) {
		_imp = [NSMutableAttributedString new];
	}
	
	return self;
}

- (NSString *) string
{
	return _imp.string;
}

- (NSDictionary *) attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
	return [_imp attributesAtIndex:location effectiveRange:range];
}

- (void) replaceCharactersInRange:(NSRange)range withString:(NSString *)str
{
	[_imp replaceCharactersInRange:range withString:str];
	[self edited:NSTextStorageEditedCharacters range:range changeInLength:(NSInteger)str.length - (NSInteger)range.length];
}

- (void) setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
	[_imp setAttributes:attrs range:range];
	[self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
}

- (void) processBold
{
	UIFont* bold_font = [UIFont fontWithName:@"Avenir-Heavy" size:[UIFont rf_preferredPostingFontSize]];
	NSRange current_r = NSMakeRange (0, 0);
	BOOL is_bold = NO;
	for (NSInteger i = 0; i < self.string.length; i++) {
		unichar c = [self.string characterAtIndex:i];
		unichar next_c = '\0';
		if ((i + 1) < self.string.length) {
			next_c = [self.string characterAtIndex:i + 1];
		}
		if ((c == '*') && (next_c == '*')) {
			if (!is_bold) {
				is_bold = YES;
				current_r.location = i;
			}
			else {
				is_bold = NO;
				current_r.length = i - current_r.location + 2;
				[self addAttribute:NSFontAttributeName value:bold_font range:current_r];
			}
		}
	}
	
	if (is_bold) {
		current_r.length = self.string.length - current_r.location;
		[self addAttribute:NSFontAttributeName value:bold_font range:current_r];
	}
}

- (void) processItalic
{
	UIFont* italic_font = [UIFont fontWithName:@"Avenir-Oblique" size:[UIFont rf_preferredPostingFontSize]];
	NSRange current_r = NSMakeRange (0, 0);
	BOOL is_italic = NO;
	for (NSInteger i = 0; i < self.string.length; i++) {
		unichar c = [self.string characterAtIndex:i];
		if (c == '_') {
			if (!is_italic) {
				is_italic = YES;
				current_r.location = i;
			}
			else {
				is_italic = NO;
				current_r.length = i - current_r.location + 1;
				[self addAttribute:NSFontAttributeName value:italic_font range:current_r];
			}
		}
	}
	
	if (is_italic) {
		current_r.length = self.string.length - current_r.location;
		[self addAttribute:NSFontAttributeName value:italic_font range:current_r];
	}
}

- (void) processEditing
{
	// clear fonts and color
	NSRange paragraph_r = [self.string paragraphRangeForRange:self.editedRange];
	UIFont* normal_font = [UIFont fontWithName:@"Avenir-Book" size:[UIFont rf_preferredPostingFontSize]];
	[self addAttribute:NSFontAttributeName value:normal_font range:paragraph_r];
	[self removeAttribute:NSForegroundColorAttributeName range:paragraph_r];

	[self processBold];
	[self processItalic];

#if 0
	// Regular expression matching all iWords -- first character i, followed by an uppercase alphabetic character, followed by at least one other character. Matches words like iPod, iPhone, etc.
	static NSRegularExpression *iExpression;
	iExpression = iExpression ?: [NSRegularExpression regularExpressionWithPattern:@"i[\\p{Alphabetic}&&\\p{Uppercase}][\\p{Alphabetic}]+" options:0 error:NULL];

	// Find all iWords in range
	[iExpression enumerateMatchesInString:self.string options:0 range:paragaphRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
		// Add red highlight color
		[self addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:result.range];
	}];
#endif

	// Call super *after* changing the attrbutes, as it finalizes the attributes and calls the delegate methods.
	[super processEditing];
}

@end
