//
//  RFEditPostController.m
//  Micro.blog
//
//  Created by Manton Reece on 3/25/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFEditPostController.h"

#import "RFPost.h"
#import "RFHighlightingTextStorage.h"
#import "UIBarButtonItem+Extras.h"
#import "UITraitCollection+Extras.h"
#import "UIFont+Extras.h"

@implementation RFEditPostController

- (void) viewDidLoad
{
	[super viewDidLoad];
		
	[self setupNavigation];
	[self setupTitle];
	[self setupText];
}

- (void) setupNavigation
{
	self.title = @"Edit Post";
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Update" style:UIBarButtonItemStylePlain target:self action:@selector(sendPost:)];
	if ([UITraitCollection rf_isDarkMode]) {
		self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
	}
	else {
		self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
	}
}

- (void) setupFont
{
	self.textView.font = [UIFont systemFontOfSize:[UIFont rf_preferredPostingFontSize]];
}

- (void) setupTitle
{
	self.titleField.text = self.post.title;
}

- (void) setupText
{
	if (UIAccessibilityIsVoiceOverRunning()) {
		// disable highlighting
		self.textStorage = [[NSTextStorage alloc] init];
	}
	else {
		self.textStorage = [[RFHighlightingTextStorage alloc] init];
	}

	// setup layout and container
	NSLayoutManager* text_layout = [[NSLayoutManager alloc] init];
	CGRect r = self.textView.frame;
	CGSize container_size = CGSizeMake (r.size.width, CGFLOAT_MAX);
	NSTextContainer* text_container = [[NSTextContainer alloc] initWithSize:container_size];
	text_container.widthTracksTextView = YES;
	[text_layout addTextContainer:text_container];
	[self.textStorage addLayoutManager:text_layout];

	// recreate text view
	UITextView* old_textview = self.textView;
	UIView* old_superview = old_textview.superview;
	self.textView = [[UITextView alloc] initWithFrame:r textContainer:text_container];
	self.textView.delegate = self;
//	[old_superview insertSubview:self.textView belowSubview:self.remainingField];
	[old_superview addSubview:self.textView];

	// constraints
	self.textView.translatesAutoresizingMaskIntoConstraints = NO;
	NSArray* old_constraints = old_superview.constraints;
	for (NSLayoutConstraint* old_c in old_constraints) {
		if (old_c.firstItem == old_textview) {
			NSLayoutConstraint* c = [NSLayoutConstraint constraintWithItem:self.textView attribute:old_c.firstAttribute relatedBy:old_c.relation toItem:old_c.secondItem attribute:old_c.secondAttribute multiplier:old_c.multiplier constant:old_c.constant];
			[c setActive:YES];
		}
		else if (old_c.secondItem == old_textview) {
			NSLayoutConstraint* c = [NSLayoutConstraint constraintWithItem:old_c.firstItem attribute:old_c.firstAttribute relatedBy:old_c.relation toItem:self.textView attribute:old_c.secondAttribute multiplier:old_c.multiplier constant:old_c.constant];
			[c setActive:YES];
		}
	}

	// remove old view
	[old_textview removeFromSuperview];

	[self setupFont];

	NSString* s = self.post.text;
	NSDictionary* attr_info = @{
		NSFontAttributeName: [UIFont systemFontOfSize:[UIFont rf_preferredPostingFontSize]]
	};
	NSAttributedString* attr_s = [[NSAttributedString alloc] initWithString:s attributes:attr_info];
	self.textView.attributedText = attr_s;

	[self.textStorage setAttributedString:attr_s];
//	[self.textStorage addLayoutManager:self.textView.layoutManager];
//	[self.textStorage addLayoutManager:self.textLayout];

	[self updateRemainingChars];
}

- (void) updateRemainingChars
{
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) sendPost:(id)sender
{
}

@end
