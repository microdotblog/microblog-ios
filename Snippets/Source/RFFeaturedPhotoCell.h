//
//  RFFeaturedPhotoCell.h
//  Micro.blog
//
//  Created by Manton Reece on 5/23/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RFFeaturedPhoto.h"

@interface RFFeaturedPhotoCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView* imageView;
@property (strong, nonatomic) IBOutlet UILabel* usernameField;

- (void) setupWithPhoto:(RFFeaturedPhoto *)photo;

@end
