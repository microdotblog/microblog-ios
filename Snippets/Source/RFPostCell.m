//
//  RFPostCell.m
//  Micro.blog
//
//  Created by Manton Reece on 3/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFPostCell.h"

#import "RFPost.h"
#import "RFPhoto.h"
#import "RFPhotoCell.h"
#import "UUDate.h"
#import "UUHttpSession.h"
#import "HTMLParser.h"
#import "RFMacros.h"

// https://github.com/zootreeves/Objective-C-HMTL-Parser (comments say it's MIT)

@implementation RFPostCell

- (void) awakeFromNib
{
	[super awakeFromNib];

	[self setupSelectionBackground];
}

- (void) setupSelectionBackground
{
	UIView* selected_view = [[UIView alloc] initWithFrame:self.bounds];
	selected_view.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.1];
	self.selectedBackgroundView = selected_view;
}

- (void) setupWithPost:(RFPost *)post
{
	self.titleField.text = post.title;
	self.textField.text = [post summary];
	self.dateField.text = [post.postedAt uuIso8601DateString];
	self.draftField.hidden = !post.isDraft;
	
	if (post.title.length == 0) {
		self.textTopConstraint.constant = 20;
	}
	else {
		self.textTopConstraint.constant = 53;
	}
	
	if ([post.text containsString:@"<img"]) {
		self.dateTopConstraint.constant = 77;
		self.photosCollectionView.hidden = NO;
	}
	else {
		self.dateTopConstraint.constant = 10;
		self.photosCollectionView.hidden = YES;
	}

	NSError* error = nil;
	HTMLParser* p = [[HTMLParser alloc] initWithString:post.text error:&error];
	if (error == nil) {
		NSMutableArray* new_photos = [NSMutableArray array];
		
		HTMLNode* body = [p body];
		NSArray* img_tags = [body findChildTags:@"img"];
		for (HTMLNode* img_tag in img_tags) {
			RFPhoto* photo = [[RFPhoto alloc] init];
			photo.publishedURL = [img_tag getAttributeNamed:@"src"];
			[new_photos addObject:photo];
		}

		NSArray* video_tags = [body findChildTags:@"video"];
		for (HTMLNode* video_tag in video_tags) {
			NSString* poster_url = [video_tag getAttributeNamed:@"poster"];
			if ([poster_url length] > 0) {
				RFPhoto* photo = [[RFPhoto alloc] init];
				photo.publishedURL = poster_url;
				[new_photos addObject:photo];
			}
		}

		self.photos = new_photos;
	}
	
	[self.photosCollectionView reloadData];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.photos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFPhotoCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];

	RFPhoto* photo = [self.photos objectAtIndex:indexPath.item];
	cell.thumbnailView.image = photo.thumbnailImage;
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath;
{
	RFPhoto* photo = [self.photos objectAtIndex:indexPath.item];
	RFPhotoCell* photo_cell = (RFPhotoCell *)cell;

	if (photo.thumbnailImage == nil) {
		NSString* url = [NSString stringWithFormat:@"https://photos.micro.blog/200/%@", photo.publishedURL];

		[UUHttpSession get:url queryArguments:nil completionHandler:^(UUHttpResponse* response) {
			if ([response.parsedResponse isKindOfClass:[UIImage class]]) {
				UIImage* img = response.parsedResponse;
				RFDispatchMain(^{
					photo.thumbnailImage = img;
					photo_cell.thumbnailView.image = img;
//					[collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
				});
			}
		}];
	}
}

@end
