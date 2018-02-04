//
//  RFFeedCell.h
//  Micro.blog
//
//  Created by Manton Reece on 2/2/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFFeedCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* urlField;
@property (strong, nonatomic) IBOutlet UILabel* usernamesField;
@property (strong, nonatomic) IBOutlet UIImageView* checkmarkView;

@end
