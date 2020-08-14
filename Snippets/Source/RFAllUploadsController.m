//
//  RFAllUploadsController.m
//  Micro.blog
//
//  Created by Manton Reece on 8/14/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFAllUploadsController.h"

#import "RFUpload.h"
#import "RFSelectBlogViewController.h"
#import "RFClient.h"
#import "RFMacros.h"
#import "RFSettings.h"
#import "UUDate.h"
#import "UIBarButtonItem+Extras.h"

@implementation RFAllUploadsController

static NSString* const kUploadCellIdentifier = @"UploadCell";

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupNotifications];
		
	[self fetchPosts];
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

- (void) setupNavigation
{
	self.title = @"Uploads";
	
	UIViewController* root_controller = [self.navigationController.viewControllers firstObject];
	if (self.navigationController.topViewController != root_controller) {
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
	}
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedBlogNotification:) name:kPostToBlogSelectedNotification object:nil];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPostNotification:) name:kEditPostNotification object:nil];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deletePostNotification:) name:kDeletePostNotification object:nil];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publishPostNotification:) name:kPublishPostNotification object:nil];
}

- (void) fetchPosts
{
	self.allPosts = @[];
	self.hostnameButton.hidden = YES;
	[self.progressSpinner startAnimating];
//	self.collectionView.animator.alphaValue = 0.0;

	NSString* destination_uid = [RFSettings selectedBlogUid];
	if (destination_uid == nil) {
		destination_uid = @"";
	}

	NSDictionary* args = @{
		@"q": @"source",
		@"mp-destination": destination_uid
	};

	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub/media"];
	[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			NSMutableArray* new_posts = [NSMutableArray array];

			NSArray* items = [response.parsedResponse objectForKey:@"items"];
			for (NSDictionary* item in items) {
				RFUpload* upload = [[RFUpload alloc] init];
				upload.url = [item objectForKey:@"url"];

				upload.width = [[item objectForKey:@"width"] integerValue];
				upload.height = [[item objectForKey:@"height"] integerValue];

				NSString* date_s = [item objectForKey:@"published"];
				upload.createdAt = [NSDate uuDateFromRfc3339String:date_s];

				[new_posts addObject:upload];
			}
			
			RFDispatchMainAsync (^{
				self.allPosts = new_posts;
				[self.collectionView reloadData];
				[self.progressSpinner stopAnimating];
				[self setupBlogName];
				self.hostnameButton.hidden = NO;
//				self.collectionView.animator.alphaValue = 1.0;
			});
		}
	}];
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) blogHostnamePressed:(id)sender
{
	NSArray* blogs = [RFSettings blogList];
	if (blogs.count > 1) {
		UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Blogs" bundle:nil];
		UIViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"BlogsNavigation"];
		RFSelectBlogViewController* select_controller = [controller.childViewControllers firstObject];
		select_controller.isCancelable = YES;
		[self presentViewController:controller animated:YES completion:NULL];
	}
}

- (void) selectedBlogNotification:(NSNotification *)notification
{
	[self setupBlogName];
	[self fetchPosts];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.allPosts.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kUploadCellIdentifier forIndexPath:indexPath];

	return cell;
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
