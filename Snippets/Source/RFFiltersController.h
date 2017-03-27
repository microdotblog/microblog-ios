//
//  RFFiltersController.h
//  Micro.blog
//
//  Created by Manton Reece on 3/26/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RFPhoto;

@interface RFFiltersController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView* croppingScrollView;
@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) RFPhoto* photo;
@property (strong, nonatomic) NSArray* filters; // RFFilter
@property (strong, nonatomic) UIImageView* imageView;
@property (strong, nonatomic) UIImage* fullImage;

- (id) initWithPhoto:(RFPhoto *)photo;

@end
