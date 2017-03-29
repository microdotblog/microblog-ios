//
//  RFPhotosController.m
//  Micro.blog
//
//  Created by Manton Reece on 3/22/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFPhotosController.h"

#import "RFPhotoCell.h"
#import "RFPhoto.h"
#import "RFFiltersController.h"
#import "RFMacros.h"
#import "UIBarButtonItem+Extras.h"

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
	self.title = @"";
	self.navigationItem.leftBarButtonItem = nil;
	
	UIImage* blank_img = [[UIImage alloc] init];
	[self.navigationController.navigationBar setBackgroundImage:blank_img forBarMetrics:UIBarMetricsDefault];
	[self.navigationController.navigationBar setShadowImage:blank_img];
}

- (void) setupPhotos
{
	PHFetchOptions* options = [[PHFetchOptions alloc] init];
	options.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ];

	PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
	if (status == PHAuthorizationStatusAuthorized) {
		self.photosResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
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
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
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
	
	RFFiltersController* filters_controller = [[RFFiltersController alloc] initWithPhoto:photo];
	[self.navigationController pushViewController:filters_controller animated:YES];
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
		self.isFullScreenPhotos = YES;
		CGFloat new_height = self.view.bounds.size.height;
		[UIView animateWithDuration:0.3 animations:^{
			self.photosHeightConstraint.constant = new_height;
			[self.view layoutIfNeeded];
		}];

		[self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
		[self.navigationController.navigationBar setShadowImage:nil];
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(closePhotos:)];
		self.title = @"Photos";
	}
	else if ((scrollView.contentOffset.y < 0) && self.isFullScreenPhotos) {
		self.isFullScreenPhotos = NO;
		[UIView animateWithDuration:0.3 animations:^{
			self.photosHeightConstraint.constant = 300;
			[self.view layoutIfNeeded];
		}];
	}
}

@end
