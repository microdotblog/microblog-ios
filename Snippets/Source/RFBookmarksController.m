//
//  RFBookmarksController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFBookmarksController.h"

#import "RFHighlightsController.h"
#import "RFClient.h"
#import "UUHttpSession.h"
#import "RFMacros.h"

@implementation RFBookmarksController

- (instancetype) initWithEndpoint:(NSString *)endpoint title:(NSString *)title
{
	self = [super initWithNibName:@"Bookmarks" endPoint:endpoint title:title];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self fetchCount];
}

- (void) fetchCount
{
	self.highlightsCountButton.hidden = YES;
	[self.progressSpinner startAnimating];

	NSDictionary* args = @{};
	
	RFClient* client = [[RFClient alloc] initWithPath:@"/posts/bookmarks/highlights"];
	[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			NSDictionary* info = [response.parsedResponse objectForKey:@"_microblog"];
			NSInteger num = [[info objectForKey:@"count"] integerValue];
			
			RFDispatchMainAsync ((^{
				if (num == 0) {
					self.highlightsHeightConstraint.constant = 0;
				}
				else {
					NSString* s;
					if (num == 1) {
						s = @"1 highlight";
					}
					else {
						s = [NSString stringWithFormat:@"%ld highlights", (long)num];
					}
					
					[self.highlightsCountButton setTitle:s forState:UIControlStateNormal];
					self.highlightsCountButton.hidden = NO;
				}
				
				[self.progressSpinner stopAnimating];
			}));
		}
		else {
			RFDispatchMainAsync ((^{
				self.highlightsHeightConstraint.constant = 0;
				[self.progressSpinner stopAnimating];
			}));
		}
	}];
}

- (IBAction) showHighlights:(id)sender
{
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Bookmark" bundle:nil];
	RFHighlightsController* controller = [storyboard instantiateViewControllerWithIdentifier:@"Highlights"];
	[self.navigationController pushViewController:controller animated:YES];
}

@end
