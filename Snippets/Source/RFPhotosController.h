//
//  RFPhotosController.h
//  Micro.blog
//
//  Created by Manton Reece on 3/22/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

static NSString* const kPhotosDidCloseNotification = @"RFPhotosDidCloseNotification";

@interface RFPhotosController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;
@property (strong, nonatomic) IBOutlet UIButton* overlayButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* photosHeightConstraint;

@property (strong, nonatomic) PHFetchResult* photosResult;
@property (assign, nonatomic) BOOL isFullScreenPhotos;

@end
