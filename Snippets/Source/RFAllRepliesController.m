//
//  AllRepliesController.m
//  Micro.blog
//
//  Created by Manton Reece on 4/22/21.
//  Copyright © 2021 Riverfold Software. All rights reserved.
//

#import "RFAllRepliesController.h"

#import "RFPostCell.h"
#import "RFPost.h"
#import "RFEditPostController.h"
#import "RFPostController.h"
#import "RFSelectBlogViewController.h"
#import "RFSwipeNavigationController.h"
#import "RFOptionsController.h"
#import "UIBarButtonItem+Extras.h"
#import "RFExternalController.h"
#import "RFClient.h"
#import "RFSettings.h"
#import "RFConstants.h"
#import "RFMacros.h"
#import "UUDate.h"
#import "UUAlert.h"

static NSString* const kPostCellIdentifier = @"PostCell";

@implementation RFAllRepliesController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupNotifications];
		
	[self fetchPosts];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kDidJustUpdatePostPrefKey]) {
		[self fetchPosts];
	}

	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDidJustUpdatePostPrefKey];

//	[[self swipeNavigationController] disableGesture];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
//	[[self swipeNavigationController] enableGesture];
}

- (void) setupNavigation
{
	self.title = @"Replies";
	
	UIViewController* root_controller = [self.navigationController.viewControllers firstObject];
	if (self.navigationController.topViewController != root_controller) {
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_backBarButtonWithTarget:self action:@selector(back:)];
	}
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPostNotification:) name:kEditPostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deletePostNotification:) name:kDeletePostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closePostingNotification:) name:kClosePostingNotification object:nil];
}

- (void) fetchPosts
{
	[self fetchPostsForSearch:@""];
}

- (void) fetchPostsForSearch:(NSString *)search
{
	self.allPosts = @[];
	self.tableView.alpha = 0.0;
	[self.progressSpinner startAnimating];

	NSDictionary* args = @{
		@"count": @50
	};

	RFClient* client = [[RFClient alloc] initWithPath:@"/posts/replies"];
	[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			NSMutableArray* new_posts = [NSMutableArray array];

			NSArray* items = [response.parsedResponse objectForKey:@"items"];
			for (NSDictionary* item in items) {
				RFPost* post = [[RFPost alloc] init];
				post.postID = [item objectForKey:@"id"];
				post.text = [item objectForKey:@"content_text"];
				post.url = [item objectForKey:@"url"];

				NSString* date_s = [item objectForKey:@"date_published"];
				post.postedAt = [NSDate uuDateFromRfc3339String:date_s];

				[new_posts addObject:post];
			}
			
			RFDispatchMainAsync (^{
				self.allPosts = new_posts;
				[self.tableView reloadData];
				[self.progressSpinner stopAnimating];
				self.headerField.hidden = NO;
				
				[UIView animateWithDuration:0.3 animations:^{
					self.tableView.alpha = 1.0;
				}];
			});
		}
	}];
}

- (RFSwipeNavigationController *) swipeNavigationController
{
	if ([self.navigationController isKindOfClass:[RFSwipeNavigationController class]]) {
		RFSwipeNavigationController* nav_controller = (RFSwipeNavigationController *)self.navigationController;
		return nav_controller;
	}
	else {
		return nil;
	}
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

- (void) editPostNotification:(NSNotification *)notification
{
	[self performSegueWithIdentifier:@"EditPostSegue" sender:self];
}

- (void) deletePostNotification:(NSNotification *)notification
{
	if (self.selectedPost) {
		NSString* destination_uid = [RFSettings selectedBlogUid];
		if (destination_uid == nil) {
			destination_uid = @"";
		}

		NSDictionary* info = @{
			@"action": @"delete",
			@"url": self.selectedPost.url,
			@"mp-destination": destination_uid
		};

		RFClient* client = [[RFClient alloc] initWithPath:@"/micropub"];
		[client postWithObject:info completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
					NSString* msg = response.parsedResponse[@"error_description"];
					[UUAlertViewController uuShowOneButtonAlert:@"Error Deleting Post" message:msg button:@"OK" completionHandler:NULL];
				}
				else {
					[self fetchPosts];
				}
			});
		}];
	}
}

- (void) closePostingNotification:(NSNotification *)notification
{
	[self fetchPosts];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.allPosts count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFPostCell* cell = [tableView dequeueReusableCellWithIdentifier:kPostCellIdentifier forIndexPath:indexPath];
	
	RFPost* post = [self.allPosts objectAtIndex:indexPath.row];
	[cell setupWithPost:post];
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.selectedPost = [self.allPosts objectAtIndex:indexPath.row];

	RFDispatchMainAsync (^{
		RFOptionsPopoverType popover_type = kOptionsPopoverEditPost;
		if (self.selectedPost.isDraft) {
			popover_type = kOptionsPopoverEditWithPublish;
		}
		else if (self.selectedPost.isTemplate) {
			popover_type = kOptionsPopoverEditDeleteOnly;
		}
		
		CGRect r = [tableView rectForRowAtIndexPath:indexPath];
		NSString* post_id = [self.selectedPost.postID stringValue];
		
		RFOptionsController* options_controller = [[RFOptionsController alloc] initWithPostID:post_id username:@"" popoverType:popover_type];
		[options_controller attachToView:tableView atRect:r];
		[self presentViewController:options_controller animated:YES completion:NULL];
	});
}

@end
