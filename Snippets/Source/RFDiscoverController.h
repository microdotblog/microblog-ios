//
//  RFDiscoverController.h
//  Micro.blog
//
//  Created by Manton Reece on 4/28/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFTimelineController.h"

@interface RFDiscoverController : RFTimelineController <UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate>

@property (strong, nonatomic) UICollectionView* photosCollectionView;
@property (strong, nonatomic) NSArray* featuredPhotos; // RFFeaturedPhoto
@property (strong, nonatomic) UISearchBar* searchBar;
@property (strong, nonatomic) UIView* backdropView;

@end
