//
//  RFDiscoverController.m
//  Micro.blog
//
//  Created by Manton Reece on 4/28/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFDiscoverController.h"

#import "RFFeaturedPhoto.h"
#import "RFFeaturedPhotoCell.h"
#import "RFClient.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "NSString+Extras.h"

static NSString* const kPhotoCellIdentifier = @"PhotoCell";

@implementation RFDiscoverController

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupSegmentView];
	[self setupSearchButton];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self setupSearchButton];
}

- (void) setupSegmentView
{
	self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[ @"Users", @"Photos" ]];
	self.segmentedControl.tintColor = [UIColor grayColor];
	[self.segmentedControl setSelectedSegmentIndex:0];

	[self.segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
	
	self.navigationItem.titleView = self.segmentedControl;
}

- (void) setupSearchButton
{
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleSearch:)];
}

- (void) toggleSearch:(id)sender
{
	if (!self.searchBar) {
		[self showSearch];
	}
	else {
		[self hideSearch];
		
		self.endpoint = @"/hybrid/discover";
		[self refreshTimeline];
	}
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self.segmentedControl setSelectedSegmentIndex:0];
	[self hidePhotos];
	
	self.endpoint = [NSString stringWithFormat:@"/hybrid/discover/search?q=%@", [searchBar.text rf_urlEncoded]];
	[self refreshTimeline];
	[self hideSearch];
}

- (void) segmentChanged:(UISegmentedControl *)sender
{
	if (sender.selectedSegmentIndex == 0) {
		[self hidePhotos];
	}
	else if (sender.selectedSegmentIndex == 1) {
		[self showPhotos];
	}
}

- (void) showSearch
{
	CGRect r = self.view.bounds;
	r.origin.y = 44 + RFStatusBarHeight();
	r.size.height = 44;
	self.searchBar = [[UISearchBar alloc] initWithFrame:r];
	self.searchBar.alpha = 0.0;
	self.searchBar.delegate = self;

	self.backdropView = [[UIView alloc] initWithFrame:self.view.bounds];
	self.backdropView.backgroundColor = [UIColor blackColor];
	self.backdropView.alpha = 0.0;
	
	UITapGestureRecognizer* tap_gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSearch:)];
	[self.backdropView addGestureRecognizer:tap_gesture];

	[self.view addSubview:self.backdropView];
	[self.view addSubview:self.searchBar];

	[UIView animateWithDuration:0.3 animations:^{
		self.searchBar.alpha = 1.0;
		self.backdropView.alpha = 0.1;
		
	} completion:^(BOOL finished) {
		[self.searchBar becomeFirstResponder];
	}];
}

- (void) hideSearch
{
	[UIView animateWithDuration:0.3 animations:^{
		self.searchBar.alpha = 0.0;
		self.backdropView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[self.searchBar removeFromSuperview];
		[self.backdropView removeFromSuperview];
		self.searchBar = nil;
		self.backdropView = nil;
	}];
}

- (void) showPhotos
{
	UICollectionViewFlowLayout* flow_layout = [[UICollectionViewFlowLayout alloc] init];

	CGRect r = self.view.bounds;
	r.origin.y += (44 + RFStatusBarHeight());
	r.size.height -= (44 + RFStatusBarHeight());

	self.photosCollectionView = [[UICollectionView alloc] initWithFrame:r collectionViewLayout:flow_layout];
	self.photosCollectionView.delegate = self;
	self.photosCollectionView.dataSource = self;
	self.photosCollectionView.alpha = 0.0;
	self.photosCollectionView.backgroundColor = [UIColor whiteColor];
	
	[self.photosCollectionView registerNib:[UINib nibWithNibName:@"FeaturedPhotoCell" bundle:nil] forCellWithReuseIdentifier:kPhotoCellIdentifier];
	
	[self.view addSubview:self.photosCollectionView];
	
	RFClient* client = [[RFClient alloc] initWithPath:@"/discover/photos"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		NSMutableArray* featured_photos = [NSMutableArray array];
		if (response.parsedResponse) {
			for (NSDictionary* info in response.parsedResponse) {
				RFFeaturedPhoto* photo = [[RFFeaturedPhoto alloc] init];
				photo.username = info[@"username"];
				photo.imageURL = info[@"image_url"];
				[featured_photos addObject:photo];
			}
			
			RFDispatchMain (^{
				self.featuredPhotos = featured_photos;
				[self.photosCollectionView reloadData];
			});
		}
	}];
	
	[UIView animateWithDuration:0.3 animations:^{
		self.photosCollectionView.alpha = 1.0;
	}];
}

- (void) hidePhotos
{
	[UIView animateWithDuration:0.3 animations:^{
		self.photosCollectionView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[self.photosCollectionView removeFromSuperview];
		self.photosCollectionView = nil;
		self.featuredPhotos = @[];
	}];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.featuredPhotos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFFeaturedPhotoCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellIdentifier forIndexPath:indexPath];

	RFFeaturedPhoto* photo = [self.featuredPhotos objectAtIndex:indexPath.item];
	[cell setupWithPhoto:photo];
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFFeaturedPhoto* photo = [self.featuredPhotos objectAtIndex:indexPath.item];
	NSString* username = photo.username;
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowUserProfileNotification object:self userInfo:@{ kShowUserProfileUsernameKey: username }];
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return CGSizeMake (100, 130);
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
	return UIEdgeInsetsMake (8, 5, 5, 5);
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
