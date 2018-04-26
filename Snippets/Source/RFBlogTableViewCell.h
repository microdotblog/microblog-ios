//
//  RFBlogTableViewCell.h
//  Micro.blog
//
//  Created by Jonathan Hays on 4/26/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RFBlogTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* nameField;
@property (strong, nonatomic) IBOutlet UILabel* subtitleField;

@end
