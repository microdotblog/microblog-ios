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
#import "RFPhotoCell.h"
#import "RFPhoto.h"
#import "RFMacros.h"
#import "RFSettings.h"
#import "RFOptionsController.h"
#import "UUDate.h"
#import "UIBarButtonItem+Extras.h"
#import "UUAlert.h"
#import "NYTPhotoViewer+Extras.h"
#import "RFNYTPhoto.h"
#import "RFConstants.h"

@interface RFAllUploadsController() <NYTPhotosViewControllerDelegate, NYTPhotoViewerDataSource>

@property (nonatomic, strong) NYTPhotosViewController* photoViewerController;
@property (nonatomic, strong) RFNYTPhoto* photoToView;

@end

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
		if (@available(iOS 13.0, *)) {
			self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left"] style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
		}
		else {
			self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
		}
	}
	
	if (@available(iOS 13.0, *)) {
		UIImage* upload_img = [UIImage systemImageNamed:@"icloud.and.arrow.up"];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:upload_img style:UIBarButtonItemStylePlain target:self action:@selector(chooseUpload:)];
	}
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedBlogNotification:) name:kPostToBlogSelectedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openUploadNotification:) name:kOpenUploadNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(copyUploadNotification:) name:kCopyUploadNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteUploadNotification:) name:kDeleteUploadNotification object:nil];
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

- (void) chooseUpload:(id)sender
{
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

- (void) openUploadNotification:(NSNotification *)notification
{
	NSArray* index_paths = [self.collectionView indexPathsForSelectedItems];
	if (index_paths) {
		NSIndexPath* index_path = [index_paths firstObject];
		RFUpload* up = [self.allPosts objectAtIndex:index_path.item];
		[self openUpload:up];
	}
}

- (void) copyUploadNotification:(NSNotification *)notification
{
	NSArray* index_paths = [self.collectionView indexPathsForSelectedItems];
	if (index_paths) {
		NSIndexPath* index_path = [index_paths firstObject];
		RFUpload* up = [self.allPosts objectAtIndex:index_path.item];
		[self copyUpload:up];
	}
}

- (void) deleteUploadNotification:(NSNotification *)notification
{
	NSArray* index_paths = [self.collectionView indexPathsForSelectedItems];
	if (index_paths) {
		NSIndexPath* index_path = [index_paths firstObject];
		RFUpload* up = [self.allPosts objectAtIndex:index_path.item];
		[self deleteUpload:up];
	}
}

- (NSNumber*) numberOfPhotos
{
	return @(0);
}

- (NSInteger)indexOfPhoto:(id <NYTPhoto>)photo
{
	return 0;
}

- (nullable id <NYTPhoto>)photoAtIndex:(NSInteger)photoIndex
{
	return self.photoToView;
}

- (UIView * _Nullable)photosViewController:(NYTPhotosViewController *)photosViewController loadingViewForPhoto:(id <NYTPhoto>)photo
{
	UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	[activityIndicator startAnimating];
	
	return activityIndicator;
}

- (void) openUpload:(RFUpload *)upload
{
	self.photoToView = [[RFNYTPhoto alloc] init];
	self.photoToView.image = nil;

	self.photoViewerController = [[NYTPhotosViewController alloc] initWithDataSource:self initialPhoto:self.photoToView delegate:self];
	self.photoViewerController.rightBarButtonItems = @[];
	
	[self presentViewController:self.photoViewerController animated:YES completion:^
	{
	}];

	[UUHttpSession get:upload.url queryArguments:nil completionHandler:^(UUHttpResponse *response) {
		UIImage* image = response.parsedResponse;
		if (image && [image isKindOfClass:[UIImage class]])
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				self.photoToView.image = image;
				[self.photoViewerController updatePhoto:self.photoToView];
				self.photoViewerController.pageViewController.dataSource = nil;
			});
		}
	}];
}
	
- (void) copyUpload:(RFUpload *)upload
{
	NSString* s = [NSString stringWithFormat:@"<img src=\"%@\" />", upload.url];
	[[UIPasteboard generalPasteboard] setString:s];
}

- (void) deleteUpload:(RFUpload *)upload
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub/media"];
	NSString* destination_uid = [RFSettings selectedBlogUid];
	if (destination_uid == nil) {
		destination_uid = @"";
	}

	NSDictionary* args = @{
		@"action": @"delete",
		@"mp-destination": destination_uid,
		@"url": upload.url,
	};

	[self.progressSpinner startAnimating];
	
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync (^{
			if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
				[self.progressSpinner stopAnimating];
				NSString* msg = response.parsedResponse[@"error_description"];
				[UUAlertViewController uuShowOneButtonAlert:@"Error Deleting Upload" message:msg button:@"OK" completionHandler:NULL];
			}
			else {
				[self fetchPosts];
			}
		});
	}];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.allPosts.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFPhotoCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kUploadCellIdentifier forIndexPath:indexPath];

	RFUpload* up = [self.allPosts objectAtIndex:indexPath.item];
	cell.thumbnailView.image = up.cachedImage;
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFUpload* up = [self.allPosts objectAtIndex:indexPath.item];
	if (up.cachedImage == nil) {
		NSString* url = [NSString stringWithFormat:@"https://micro.blog/photos/200/%@", up.url];

		[UUHttpSession get:url queryArguments:nil completionHandler:^(UUHttpResponse* response) {
			if ([response.parsedResponse isKindOfClass:[UIImage class]]) {
				UIImage* img = response.parsedResponse;
				RFDispatchMain(^{
					up.cachedImage = img;
					[collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
				});
			}
		}];
	}
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
	
	RFDispatchMainAsync (^{
		RFOptionsPopoverType popover_type = kOptionsPopoverUpload;
		
		CGRect r = cell.bounds;
		
		RFOptionsController* options_controller = [[RFOptionsController alloc] initWithPostID:@"" username:@"" popoverType:popover_type];
		[options_controller attachToView:cell atRect:r];
		[self presentViewController:options_controller animated:YES completion:NULL];
	});
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
