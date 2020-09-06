//
//  RFSearchController.h
//  Micro.blog
//
//  Created by Manton Reece on 9/6/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFTimelineController.h"

NS_ASSUME_NONNULL_BEGIN

@interface RFSearchController : RFTimelineController <UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar* searchBar;

@end

NS_ASSUME_NONNULL_END
