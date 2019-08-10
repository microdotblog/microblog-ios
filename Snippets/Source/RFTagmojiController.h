//
//  RFTagmojiController.h
//  Micro.blog
//
//  Created by Manton Reece on 8/9/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RFTagmojiController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) NSArray* tagmoji;

- (id) initWithTagmoji:(NSArray *)tagmoji;

@end

NS_ASSUME_NONNULL_END
