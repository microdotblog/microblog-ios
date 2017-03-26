//
//  RFFiltersController.m
//  Micro.blog
//
//  Created by Manton Reece on 3/26/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFFiltersController.h"

#import "RFFilterCell.h"
#import "RFFilter.h"
#import "RFPhoto.h"

static NSString* const kFilterCellIdentifier = @"FilterCell";

@implementation RFFiltersController

- (id) initWithPhoto:(RFPhoto *)photo
{
	self = [super initWithNibName:@"Filters" bundle:nil];
	if (self) {
		self.photo = photo;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupFilters];
	[self setupCollectionView];
}

- (void) setupFilters
{
	NSMutableArray* new_filters = [NSMutableArray array];
	
	NSArray* filters = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Filters" ofType:@"plist"]];
	for (NSDictionary* info in filters) {
		RFFilter* f = [[RFFilter alloc] init];
		f.name = info[@"name"];
		// ...
		[new_filters addObject:f];
	}
	
	self.filters = new_filters;
	
//	self.filters = @[ @"Normal", @"Mono", @"Tonal", @"Noir", @"Fade", @"Chrome", @"Process", @"Transfer", @"Instant" ];
}

- (void) setupCollectionView
{
	[self.collectionView registerNib:[UINib nibWithNibName:@"FilterCell" bundle:nil] forCellWithReuseIdentifier:kFilterCellIdentifier];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.filters.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFFilterCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kFilterCellIdentifier forIndexPath:indexPath];

	RFFilter* filter = [self.filters objectAtIndex:indexPath.item];
	[cell setupWithPhoto:self.photo applyingFilter:filter];
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
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
