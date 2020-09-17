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
#import "UUImage.h"
#import "RFConstants.h"

@import MobileCoreServices;
@import SafariServices;

@interface RFAllUploadsController() <NYTPhotosViewControllerDelegate, NYTPhotoViewerDataSource>

@property (nonatomic, strong) NYTPhotosViewController* photoViewerController;
@property (nonatomic, strong) RFNYTPhoto* photoToView;

@end

#pragma mark -

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
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_backBarButtonWithTarget:self action:@selector(back:)];
	}
	
	if (@available(iOS 14.0, *)) {
		UIImage* upload_img = [UIImage systemImageNamed:@"icloud.and.arrow.up"];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:upload_img style:UIBarButtonItemStylePlain target:self action:NULL];
		
		UIImage* library_img = [UIImage systemImageNamed:@"photo"];
		UIAction* library_action = [UIAction actionWithTitle:@"Photo Library" image:library_img identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
			[self chooseUpload:nil];
		}];

		UIImage* files_img = [UIImage systemImageNamed:@"folder"];
		UIAction* files_action = [UIAction actionWithTitle:@"Files" image:files_img identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
			[self chooseFiles:nil];
		}];

		NSArray* items = @[ library_action, files_action ];
		self.navigationItem.rightBarButtonItem.menu = [UIMenu menuWithChildren:items];
	}
	else if (@available(iOS 13.0, *)) {
		UIImage* upload_img = [UIImage systemImageNamed:@"icloud.and.arrow.up"];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:upload_img style:UIBarButtonItemStylePlain target:self action:@selector(chooseUpload:)];
	}
	else {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Upload..." style:UIBarButtonItemStylePlain target:self action:@selector(chooseUpload:)];
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

- (void) uploadData:(NSData *)data isVideo:(BOOL)isVideo
{
	return [self uploadData:data isVideo:isVideo otherFilename:nil contentType:nil];
}

- (void) uploadData:(NSData *)data isVideo:(BOOL)isVideo otherFilename:(NSString *)filename contentType:(NSString *)contentType
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub/media"];
	NSString* destination_uid = [RFSettings selectedBlogUid];
	if (destination_uid == nil) {
		destination_uid = @"";
	}

	NSDictionary* args = @{
		@"mp-destination": destination_uid
	};

	self.hostnameButton.hidden = YES;
	[self.progressSpinner startAnimating];

	if (filename) {
		[client uploadFileData:data named:@"file" filename:filename contentType:contentType httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
					[self.progressSpinner stopAnimating];
					NSString* msg = response.parsedResponse[@"error_description"];
					[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Video" message:msg button:@"OK" completionHandler:NULL];
				}
				else {
					[self fetchPosts];
				}
			});
		}];
	}
	else if (isVideo) {
		[client uploadVideoData:data named:@"file" httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
					[self.progressSpinner stopAnimating];
					NSString* msg = response.parsedResponse[@"error_description"];
					[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Video" message:msg button:@"OK" completionHandler:NULL];
				}
				else {
					[self fetchPosts];
				}
			});
		}];
	}
	else {
		[client uploadImageData:data named:@"file" httpMethod:@"POST" queryArguments:args completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
					[self.progressSpinner stopAnimating];
					NSString* msg = response.parsedResponse[@"error_description"];
					[UUAlertViewController uuShowOneButtonAlert:@"Error Uploading Photo" message:msg button:@"OK" completionHandler:NULL];
				}
				else {
					[self fetchPosts];
				}
			});
		}];
	}
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) chooseUpload:(id)sender
{
	UIImagePickerController* picker_controller = [[UIImagePickerController alloc] init];
	picker_controller.delegate = self;
	picker_controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker_controller.mediaTypes = @[ (NSString *)kUTTypeMovie, (NSString *)kUTTypeImage ];
	[self presentViewController:picker_controller animated:YES completion:NULL];
}

- (void) chooseFiles:(id)sender
{
	NSArray* types = @[ (NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, (NSString *)kUTTypeAudio, (NSString *)kUTTypePDF, (NSString *)kUTTypeText ];
	UIDocumentPickerViewController* picker_controller = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeImport];
	picker_controller.delegate = self;
	picker_controller.allowsMultipleSelection = NO;
	[self presentViewController:picker_controller animated:YES completion:NULL];
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

#pragma mark -

- (NSNumber*) numberOfPhotos
{
	return @(0);
}

- (NSInteger) indexOfPhoto:(id <NYTPhoto>)photo
{
	return 0;
}

- (nullable id <NYTPhoto>) photoAtIndex:(NSInteger)photoIndex
{
	return self.photoToView;
}

- (UIView * _Nullable)photosViewController:(NYTPhotosViewController *)photosViewController loadingViewForPhoto:(id <NYTPhoto>)photo
{
	UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	[activityIndicator startAnimating];
	
	return activityIndicator;
}

#pragma mark -

- (void) openUpload:(RFUpload *)upload
{
	if ([upload isPhoto]) {
		self.photoToView = [[RFNYTPhoto alloc] init];
		self.photoToView.image = nil;

		self.photoViewerController = [[NYTPhotosViewController alloc] initWithDataSource:self initialPhoto:self.photoToView delegate:self];
		self.photoViewerController.rightBarButtonItems = @[];
		
		[self presentViewController:self.photoViewerController animated:YES completion:NULL];

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
	else {
		SFSafariViewController* safari_controller = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:upload.url]];
		[self presentViewController:safari_controller animated:YES completion:NULL];
	}
}
	
- (void) copyUpload:(RFUpload *)upload
{
	NSString* s;
	if ([upload isPhoto]) {
		s = [NSString stringWithFormat:@"<img src=\"%@\" />", upload.url];
	}
	else if ([upload isVideo]) {
		s = [NSString stringWithFormat:@"<video src=\"%@\" controls=\"controls\" playsinline=\"playsinline\" preload=\"none\"></video>", upload.url];
	}
	else if ([upload isAudio]) {
		s = [NSString stringWithFormat:@"<audio src=\"%@\" controls=\"controls\" preload=\"metadata\" />", upload.url];
	}
	else {
		s = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", upload.url, [upload filename]];
	}

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

	self.hostnameButton.hidden = YES;
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

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
	NSURL* reference_url = [info objectForKey:UIImagePickerControllerReferenceURL];
	PHAsset* asset = [[PHAsset fetchAssetsWithALAssetURLs:@[ reference_url ] options:nil] lastObject];

	if (asset) {
		if (asset.mediaType == PHAssetMediaTypeVideo) {
			RFPhoto* photo = [[RFPhoto alloc] initWithVideo:reference_url asset:asset];
			[photo generateVideoURL:^(NSURL* url) {
				NSData* d = [NSData dataWithContentsOfURL:photo.videoURL];
				if (d) {
					[self uploadData:d isVideo:YES];
				}
			}];
		}
		else {
			PHImageManager* manager = [PHImageManager defaultManager];
			PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
			options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
			options.resizeMode = PHImageRequestOptionsResizeModeExact;
			options.networkAccessAllowed = YES;
			[manager requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
				UIImage* img = [UIImage imageWithData:imageData];
				img = [img uuRemoveOrientation];

				NSData* d = UIImageJPEGRepresentation (img, 0.9);
				if (d) {
					[self uploadData:d isVideo:NO];
				}
			}];
		}

		[self dismissViewControllerAnimated:YES completion:NULL];
	}
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

- (void) documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls
{
	NSURL* url = [urls firstObject];

	NSString* filename = [url lastPathComponent];
	NSString* e = [url pathExtension];
	NSString* uti = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)e, NULL);
	NSString* content_type = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)uti, kUTTagClassMIMEType);
	
	NSData* d = [NSData dataWithContentsOfURL:url];
	[self uploadData:d isVideo:NO otherFilename:filename contentType:content_type];
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
	if ([up isPhoto]) {
		cell.thumbnailView.image = up.cachedImage;
		cell.iconView.image = nil;
	}
	else if (@available(iOS 13.0, *)) {
		cell.thumbnailView.image = nil;
		if ([up isVideo]) {
			cell.iconView.image = [UIImage systemImageNamed:@"film"];
		}
		else if ([up isAudio]) {
			cell.iconView.image = [UIImage systemImageNamed:@"waveform"];
		}
		else {
			cell.iconView.image = [UIImage systemImageNamed:@"doc"];
		}
	}
	else {
		cell.thumbnailView.image = nil;
		cell.iconView.image = nil;
	}
	
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
					if ([collectionView numberOfItemsInSection:0] > indexPath.item) {
						[collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
					}
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
