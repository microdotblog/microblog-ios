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
#import "UIBarButtonItem+Extras.h"

static NSString* const kFilterCellIdentifier = @"FilterCell";

@implementation RFFiltersController

- (id) initWithPhoto:(RFPhoto *)photo
{
	self = [super initWithNibName:@"Filters" bundle:nil];
	if (self) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
		self.photo = photo;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupFilters];
	[self setupCollectionView];
	[self setupScrollView];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
	[self.navigationController.navigationBar setShadowImage:nil];
}

- (void) setupNavigation
{
	self.title = @"Filters";
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Photo" style:UIBarButtonItemStylePlain target:self action:@selector(attachPhoto:)];
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

- (void) setupScrollView
{
	PHImageManager* manager = [PHImageManager defaultManager];
	[manager requestImageForAsset:self.photo.asset targetSize:CGSizeMake (800, 800) contentMode:PHImageContentModeAspectFill options:0 resultHandler:^(UIImage* result, NSDictionary* info) {
		[self.croppingScrollView performSelector:@selector(setImageToDisplay:) withObject:result];
		[self.croppingScrollView performSelector:@selector(zoom) withObject:nil];
	}];
}

#pragma mark -

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) attachPhoto:(id)sender
{
	UIImage* img = [self.croppingScrollView performSelector:@selector(captureVisibleRect) withObject:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kAttachPhotoNotification object:self userInfo:@{ kAttachPhotoKey: img }];
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
	return CGSizeMake (112, 150);
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
