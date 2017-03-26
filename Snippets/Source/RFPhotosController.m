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

static NSString* const kPhotoCellIdentifier = @"PhotoCell";

@implementation RFPhotosController

- (id) init
{
	self = [super initWithNibName:@"Photos" bundle:nil];
	if (self) {
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
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
//	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	if (self.photosResult.count < 50) {
		return self.photosResult.count;
		}
	else {
		return 50;
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
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:filters_controller];
	[self presentViewController:nav_controller animated:YES completion:NULL];
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return CGSizeMake (150, 150);
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

@end