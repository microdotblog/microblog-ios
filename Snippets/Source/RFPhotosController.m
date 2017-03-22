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
	self.photosResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
}

- (void) setupCollectionView
{
	[self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCell" bundle:nil] forCellWithReuseIdentifier:kPhotoCellIdentifier];
	[self.collectionView reloadData];
}

- (IBAction) closePhotos:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
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
