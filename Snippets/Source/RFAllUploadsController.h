//
//  RFAllUploadsController.h
//  Micro.blog
//
//  Created by Manton Reece on 8/14/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RFNYTPhoto;
@class NYTPhotosViewController;

NS_ASSUME_NONNULL_BEGIN

@interface RFAllUploadsController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate>

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;
@property (strong, nonatomic) IBOutlet UIButton* hostnameButton;
@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) NSArray* allPosts; // RFUpload

@end

NS_ASSUME_NONNULL_END
