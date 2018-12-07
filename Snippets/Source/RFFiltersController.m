//
//  RFFiltersController.m
//  Micro.blog
//
//  Created by Manton Reece on 3/26/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFViewController.h"
#import "RFFiltersController.h"

#import "RFMacros.h"
#import "RFFilterCell.h"
#import "RFFilter.h"
#import "RFPhoto.h"
#import "UIBarButtonItem+Extras.h"
#import "UUImage.h"

static NSString* const kFilterCellIdentifier = @"FilterCell";

@interface RFFiltersController()
	@property (nonatomic, assign) BOOL zoomDisabled;
	@property (nonatomic, strong) RFFilter* selectedFilter;
@end


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
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
	[self.navigationController.navigationBar setShadowImage:nil];
}

- (void) viewWillLayoutSubviews
{
	[super viewWillLayoutSubviews];

	[self setupPhotoBounds];
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	[self setupScrollView];
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
        RFFilter* f = [RFFilter filterFromDictionary:info];
		[new_filters addObject:f];
	}
	
	self.filters = new_filters;
}

- (void) setupCollectionView
{
	[self.collectionView registerNib:[UINib nibWithNibName:@"FilterCell" bundle:nil] forCellWithReuseIdentifier:kFilterCellIdentifier];
}

- (void) setupPhotoBounds
{
	if (self.view.bounds.size.height > self.view.bounds.size.width) {
		self.collectionHeightConstraint.constant = self.view.bounds.size.height  - self.view.bounds.size.width;
		if (self.collectionHeightConstraint.constant > 300) {
			self.collectionLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
		}
	}
	else {
		self.collectionHeightConstraint.constant = 250;
	}
}

- (void) setupScrollView
{
	if (self.imageView) {
		return;
	}
	
	PHImageManager* manager = [PHImageManager defaultManager];
	PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
	options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
	options.resizeMode = PHImageRequestOptionsResizeModeExact;
	options.networkAccessAllowed = YES;
	[manager requestImageDataForAsset:self.photo.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
		UIImage* img = [UIImage imageWithData:imageData];
        img = [img uuRemoveOrientation];
		
		self.nonZoomImageView.hidden = YES;
		self.nonZoomImageView.alpha = 0.0;
		self.croppingScrollView.hidden = NO;
		self.croppingScrollView.alpha = 1.0;
		
		self.nonZoomImageView.image = img;
		self.fullImage = img;

		CGRect r = CGRectZero;
		r.size = img.size;

		self.imageView = [[UIImageView alloc] initWithFrame:r];
		self.imageView.image = img;
		
		CGFloat w_scale = self.croppingScrollView.bounds.size.width / r.size.width;
		CGFloat h_scale = self.croppingScrollView.bounds.size.height / r.size.height;
		
		self.croppingScrollView.delegate = self;
		[self.croppingScrollView addSubview:self.imageView];
		self.croppingScrollView.contentSize = r.size;
		if (w_scale > h_scale) {
			self.croppingScrollView.minimumZoomScale = w_scale;
		}
		else {
			self.croppingScrollView.minimumZoomScale = h_scale;
		}
		self.croppingScrollView.maximumZoomScale = 2.0;
		self.croppingScrollView.zoomScale = self.croppingScrollView.minimumZoomScale;
	}];
}

- (CGRect) cropAreaRect
{
	CGRect r = self.croppingScrollView.bounds;
	r.origin = CGPointZero;
	return r;
}

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.imageView;
}

- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
}

#pragma mark -

- (IBAction) onToggleZoom:(id)sender
{
	self.zoomDisabled = !self.zoomDisabled;
	
	CGFloat croppingScrollViewAlpha;
	CGFloat nonZoomImageViewAlpha;
	
	if (self.zoomDisabled)
	{
		self.croppingScrollView.hidden = YES;
		self.nonZoomImageView.hidden = NO;
		
		nonZoomImageViewAlpha = 1.0;
		croppingScrollViewAlpha = 0.0;
	}
	else
	{
		self.croppingScrollView.hidden = NO;
		self.nonZoomImageView.hidden = YES;

		nonZoomImageViewAlpha = 0.0;
		croppingScrollViewAlpha = 1.0;
	}
	

	[UIView animateWithDuration:0.35 animations:^
	{
		self.nonZoomImageView.alpha = nonZoomImageViewAlpha;
		self.croppingScrollView.alpha = croppingScrollViewAlpha;
	}
	completion:^(BOOL finished)
	{
	}];

}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) attachPhoto:(id)sender
{
	UIImage* cropped_image = nil;
	
	if (self.zoomDisabled)
	{
		cropped_image = self.fullImage;
	}
	else
	{
		CGRect ui_crop_r = [self cropAreaRect];
		UIImage* img = self.fullImage;
	
		CGPoint content_offset = self.croppingScrollView.contentOffset;
		CGSize scaled_size = self.croppingScrollView.contentSize;
		CGSize img_size = [img size];
	
		CGFloat scaled_ratio = scaled_size.width / img_size.width;

		ui_crop_r.origin.x += content_offset.x;
		ui_crop_r.origin.y += content_offset.y;
	
		CGRect image_crop_r;
		image_crop_r.origin.x = ui_crop_r.origin.x / scaled_ratio * img.scale;
		image_crop_r.origin.y = ui_crop_r.origin.y / scaled_ratio * img.scale;
		image_crop_r.size.width = ui_crop_r.size.width / scaled_ratio * img.scale;
		image_crop_r.size.height = ui_crop_r.size.height / scaled_ratio * img.scale;
	
		BOOL needs_cg_cleanup = NO;
		CGImageRef cg_image = img.CGImage;
		if (cg_image == nil) {
			CIContext* context = [CIContext contextWithOptions:nil];
			cg_image = [context createCGImage:img.CIImage fromRect:img.CIImage.extent];
			needs_cg_cleanup = YES;
		}
	
		CGImageRef new_img = CGImageCreateWithImageInRect (cg_image, image_crop_r);
		cropped_image = [[UIImage alloc] initWithCGImage:new_img];
    	CGImageRelease(new_img);

		if (needs_cg_cleanup) {
			CGImageRelease (cg_image);
		}
	}
	
	if (cropped_image)
	{
		if (self.selectedFilter && self.selectedFilter.ciFilter)
		{
			cropped_image = [self.selectedFilter filterImage:cropped_image];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kAttachPhotoNotification object:self userInfo:@{ kAttachPhotoKey: cropped_image }];
	}
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
	RFFilter* filter = [self.filters objectAtIndex:indexPath.item];
	/*
	PHImageManager* manager = [PHImageManager defaultManager];
	PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
	options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
	options.resizeMode = PHImageRequestOptionsResizeModeExact;
	options.networkAccessAllowed = YES;
	*/
	self.selectedFilter = filter;
	
	UIImage* img = self.fullImage;
	if (self.selectedFilter.ciFilter)
	{
		img = [self.selectedFilter filterImage:self.fullImage];
	}


	self.imageView.image = img;
	self.nonZoomImageView.image = img;
	
	/*
	[manager requestImageForAsset:self.photo.asset targetSize:CGSizeMake (1800, 1800) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage* result, NSDictionary* info) {
		UIImage* img = [result uuRemoveOrientation];
		if (filter.ciFilter) {
			img = [filter filterImage:img];
		}
		self.imageView.image = img;
		self.fullImage = img;
	}];
	*/
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return CGSizeMake (112, 150);
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
//	if (collectionView.bounds.size.height > 300) {
//		return UIEdgeInsetsMake (25, 5, 25, 5);
//	}
//	else {
		return UIEdgeInsetsMake (5, 5, 5, 5);
//	}
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
