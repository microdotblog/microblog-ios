//
//  RFHighlightsController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFHighlightsController.h"

#import "RFHighlight.h"
#import "RFHighlightCell.h"
#import "UUHttpSession.h"
#import "UUDate.h"
#import "RFClient.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "UIBarButtonItem+Extras.h"

@implementation RFHighlightsController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self fetchHighlights];
}

- (void) setupNavigation
{
	self.title = @"Highlights";
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_backBarButtonWithTarget:self action:@selector(back:)];
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) fetchHighlights
{
	self.tableView.alpha = 0.0;
	[self.progressSpinner startAnimating];

	NSDictionary* args = @{};
	
	RFClient* client = [[RFClient alloc] initWithPath:@"/posts/bookmarks/highlights"];
	[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			NSMutableArray* new_highlights = [NSMutableArray array];

			NSArray* items = [response.parsedResponse objectForKey:@"items"];
			for (NSDictionary* item in items) {
				RFHighlight* h = [[RFHighlight alloc] init];
				h.linkTitle = [item objectForKey:@"title"];
				h.selectionText = [item objectForKey:@"content_text"];

				NSString* date_s = [item objectForKey:@"date_published"];
				h.createdAt = [NSDate uuDateFromRfc3339String:date_s];

				[new_highlights addObject:h];
			}
			
			RFDispatchMainAsync (^{
				self.highlights = new_highlights;
				[self.tableView reloadData];
				[self.progressSpinner stopAnimating];
			});

			[UIView animateWithDuration:0.3 animations:^{
				self.tableView.alpha = 1.0;
			}];
		}
	}];
}

#pragma mark -

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.highlights.count;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
	RFHighlight* h = [self.highlights objectAtIndex:indexPath.row];
	RFHighlightCell* cell = [tableView dequeueReusableCellWithIdentifier:@"HighlightCell" forIndexPath:indexPath];

	cell.selectionField.text = h.selectionText;
	cell.titleField.text = h.linkTitle;
	
	return cell;
}

@end
