//
//  RFAllPostsController.m
//  Micro.blog
//
//  Created by Manton Reece on 3/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFAllPostsController.h"

#import "RFPostCell.h"
#import "RFPost.h"
#import "RFEditPostController.h"
#import "UIBarButtonItem+Extras.h"
#import "RFClient.h"
#import "RFSettings.h"
#import "RFMacros.h"
#import "UUDate.h"

static NSString* const kPostCellIdentifier = @"PostCell";

@implementation RFAllPostsController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	
	[self fetchPosts];
}

- (void) setupNavigation
{
	self.title = @"Posts";
	
	UIViewController* root_controller = [self.navigationController.viewControllers firstObject];
	if (self.navigationController.topViewController != root_controller) {
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
	}
}

- (void) setupBlogName
{
	NSString* s = [RFSettings accountDefaultSite];
	if (s) {
		[self.hostnameButton setTitle:s forState:UIControlStateNormal];
	}
	else {
		self.hostnameButton.hidden = YES;
	}
}

- (void) fetchPosts
{
	self.allPosts = @[];
	self.currentPosts = @[];
	self.hostnameButton.hidden = YES;
	self.tableView.alpha = 0.0;
	[self.progressSpinner startAnimating];

	NSString* destination_uid = [RFSettings selectedBlogUid];
	if (destination_uid == nil) {
		destination_uid = @"";
	}

	NSDictionary* args = @{
		@"q": @"source",
		@"mp-destination": destination_uid
	};

	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub"];
	[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			NSMutableArray* new_posts = [NSMutableArray array];

			NSArray* items = [response.parsedResponse objectForKey:@"items"];
			for (NSDictionary* item in items) {
				RFPost* post = [[RFPost alloc] init];
				NSDictionary* props = [item objectForKey:@"properties"];
				post.title = [[props objectForKey:@"name"] firstObject];
				post.text = [[props objectForKey:@"content"] firstObject];
				post.url = [[props objectForKey:@"url"] firstObject];

				NSString* date_s = [[props objectForKey:@"published"] firstObject];
				post.postedAt = [NSDate uuDateFromRfc3339String:date_s];

				NSString* status = [[props objectForKey:@"post-status"] firstObject];
				post.isDraft = [status isEqualToString:@"draft"];

				[new_posts addObject:post];
			}
			
			RFDispatchMainAsync (^{
				self.allPosts = new_posts;
				self.currentPosts = new_posts;
				[self.tableView reloadData];
				[self.progressSpinner stopAnimating];
				[self setupBlogName];
				self.hostnameButton.hidden = NO;
				
				[UIView animateWithDuration:0.3 animations:^{
					self.tableView.alpha = 1.0;
				}];
			});
		}
	}];
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	RFEditPostController* edit_controller = [segue destinationViewController];
	edit_controller.post = self.selectedPost;
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.currentPosts count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFPostCell* cell = [tableView dequeueReusableCellWithIdentifier:kPostCellIdentifier forIndexPath:indexPath];
	
	RFPost* post = [self.currentPosts objectAtIndex:indexPath.row];
	[cell setupWithPost:post];
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.selectedPost = [self.currentPosts objectAtIndex:indexPath.row];
	[self performSegueWithIdentifier:@"EditPostSegue" sender:self];
}

@end
