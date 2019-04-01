//
//  RFPhotosController.m
//  Micro.blog
//
//  Created by Manton Reece on 3/22/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFPhotosController.h"

#import "RFPhotoCell.h"
#import "RFPhoto.h"
#import "RFFiltersController.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"
#import "RFUpgradeController.h"
#import "RFSettings.h"

@import MobileCoreServices;

static NSString* const kPhotoCellIdentifier = @"PhotoCell";

@implementation RFPhotosController

- (id) init
{
	self = [super initWithNibName:@"Photos" bundle:nil];
	if (self) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
		self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupPhotos];
	[self setupCollectionView];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self setupNavigation];
}

- (void) setupNavigation
{
	UIImage* blank_img = [[UIImage alloc] init];

	self.title = @"";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:blank_img style:UIBarButtonItemStylePlain target:self action:@selector(closePhotos:)];
	if (self.isFullScreenPhotos) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Library..." style:UIBarButtonItemStylePlain target:self action:@selector(chooseFromLibrary:)];
	}
	else {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:blank_img style:UIBarButtonItemStylePlain target:self action:@selector(closePhotos:)];
	}
	
	[self.navigationController.navigationBar setBackgroundImage:blank_img forBarMetrics:UIBarMetricsDefault];
	[self.navigationController.navigationBar setShadowImage:blank_img];
}

- (void) setupPhotos
{
	PHFetchOptions* options = [[PHFetchOptions alloc] init];
	options.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ];
	options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld || mediaType == %ld", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
	
	PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
	if (status == PHAuthorizationStatusAuthorized) {
		self.photosResult = [PHAsset fetchAssetsWithOptions:options];//[PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
	}
	else if (status == PHAuthorizationStatusNotDetermined) {
		[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
			if (status == PHAuthorizationStatusAuthorized) {
				RFDispatchMain (^{
					self.photosResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
					[self.collectionView reloadData];
				});
			}
		}];
	}	
}

- (void) setupCollectionView
{
	[self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCell" bundle:nil] forCellWithReuseIdentifier:kPhotoCellIdentifier];
}

- (IBAction) closePhotos:(id)sender
{
	[self setupNavigation];
	[[NSNotificationCenter defaultCenter] postNotificationName:kPhotosDidCloseNotification object:self];
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
	}];
}

- (void) expandPhotos
{
	self.isFullScreenPhotos = YES;
	CGFloat new_height = self.view.bounds.size.height;
	[UIView animateWithDuration:0.3 animations:^{
		self.photosHeightConstraint.constant = new_height;
		[self.view layoutIfNeeded];
	}];

	[self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
	[self.navigationController.navigationBar setShadowImage:nil];
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(closePhotos:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Library..." style:UIBarButtonItemStylePlain target:self action:@selector(chooseFromLibrary:)];
	self.title = @"Photos";
}

- (void) collapsePhotos
{
	self.navigationItem.rightBarButtonItem = nil;
	self.isFullScreenPhotos = NO;
	[UIView animateWithDuration:0.3 animations:^{
		self.photosHeightConstraint.constant = 300;
		[self.view layoutIfNeeded];
	}];
}

- (void) chooseFromLibrary:(id)sender
{
	UIImagePickerController* picker_controller = [[UIImagePickerController alloc] init];
	picker_controller.delegate = self;
	picker_controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker_controller.mediaTypes = @[ (NSString*)kUTTypeMovie, (NSString*)kUTTypeImage ];
	[self presentViewController:picker_controller animated:YES completion:NULL];
}

- (void) checkVideoUpload:(RFPhoto *)photo completion:(void (^)(BOOL canUpload))handler
{
	BOOL needs_upgrade = NO;
	
	if ([RFSettings hasSnippetsBlog] && ![RFSettings prefersExternalBlog]) {
		NSDictionary* info = [RFSettings selectedBlogInfo];
		if (info && ![[info objectForKey:@"microblog-audio"] boolValue]) {
			needs_upgrade = YES;
		}
	}
	
	if (needs_upgrade) {
		RFUpgradeController* upgrade_controller = [[RFUpgradeController alloc] init];
		upgrade_controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		upgrade_controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
		upgrade_controller.handler = handler;
		[self presentViewController:upgrade_controller animated:YES completion:NULL];
	}
	else {
		handler(YES);
	}
}

#pragma mark -

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
	NSURL* reference_url = [info objectForKey:UIImagePickerControllerReferenceURL];
	PHAsset* asset = [[PHAsset fetchAssetsWithALAssetURLs:@[ reference_url ] options:nil] lastObject];

	if (asset) {
		if (asset.mediaType == PHAssetMediaTypeVideo)
		{
			RFPhoto* photo = [[RFPhoto alloc] initWithVideo:reference_url asset:asset];
			
			[photo generateVideoThumbnail:^(UIImage *thumbnail) {
				[photo generateVideoURL:^(NSURL* url) {
					
					dispatch_async(dispatch_get_main_queue(), ^{
						
						NSDictionary* dictionary = @{ kAttachVideoKey : url,
													  kAttachVideoThumbnailKey : thumbnail
													  };
						
						[[NSNotificationCenter defaultCenter] postNotificationName:kAttachVideoNotification object:self userInfo:dictionary];
					});
				}];
			}];
		}
		else {

			[self dismissViewControllerAnimated:YES completion:^{
				RFPhoto* photo = [[RFPhoto alloc] initWithAsset:asset];
			
				RFFiltersController* filters_controller = [[RFFiltersController alloc] initWithPhoto:photo];
				[self.navigationController pushViewController:filters_controller animated:YES];
			}];
		}
	}
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	if (self.photosResult.count < 100) {
		return self.photosResult.count;
		}
	else {
		return 100;
	}
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFPhotoCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellIdentifier forIndexPath:indexPath];

	PHAsset* asset = [self.photosResult objectAtIndex:indexPath.item];
	RFPhoto* photo = [[RFPhoto alloc] initWithAsset:asset];
	[cell setupWithPhoto:photo];
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	PHAsset* asset = [self.photosResult objectAtIndex:indexPath.item];
	RFPhoto* photo = [[RFPhoto alloc] initWithAsset:asset];
	
	if (asset.mediaType == PHAssetMediaTypeImage)
	{
		RFFiltersController* filters_controller = [[RFFiltersController alloc] initWithPhoto:photo];
		[self.navigationController pushViewController:filters_controller animated:YES];
	}
	else if (asset.mediaType == PHAssetMediaTypeVideo)
	{
		[self checkVideoUpload:photo completion:^(BOOL canUpload) {
			if (canUpload) {
				self.busyIndicator.hidden = NO;
				
				[photo generateVideoThumbnail:^(UIImage *thumbnail) {
					[photo generateVideoURL:^(NSURL* url) {
						
						dispatch_async(dispatch_get_main_queue(), ^{
							
							NSDictionary* dictionary = @{ kAttachVideoKey : url,
														  kAttachVideoThumbnailKey : thumbnail
														};
							
							[[NSNotificationCenter defaultCenter] postNotificationName:kAttachVideoNotification object:self userInfo:dictionary];
							
							self.busyIndicator.hidden = YES;
						});
					}];
				}];
			}
		}];
	}
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat w = ([UIScreen mainScreen].bounds.size.width / 4.0) - 5;
	if (w > 100) {
		w = 100;
	}
	return CGSizeMake (w, w);
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
	return UIEdgeInsetsMake (5, 5, 5, 5);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return 5;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
	return 0;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
	if ((scrollView.contentOffset.y > 0) && !self.isFullScreenPhotos) {
		[self expandPhotos];
	}
	else if ((scrollView.contentOffset.y < 0) && self.isFullScreenPhotos) {
		[self collapsePhotos];
	}
}

@end
