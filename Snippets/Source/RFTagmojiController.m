//
//  RFTagmojiController.m
//  Micro.blog
//
//  Created by Manton Reece on 8/9/19.
//  Copyright © 2019 Riverfold Software. All rights reserved.
//

#import "RFTagmojiController.h"

#import "RFTagmojiCell.h"
#import "UIBarButtonItem+Extras.h"
#import "RFConstants.h"

static NSString* const kTagmojiCellIdentifier = @"TagmojiCell";

@implementation RFTagmojiController

- (id) initWithTagmoji:(NSArray *)tagmoji
{
	self = [super initWithNibName:@"Tagmoji" bundle:nil];
	if (self) {
		self.tagmoji = tagmoji;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupNavigation];
	[self setupCollectionView];
}

- (void) setupNavigation
{
	self.title = @"Topics";

	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"close_button" target:self action:@selector(close:)];
}

- (void) setupCollectionView
{
	[self.collectionView registerNib:[UINib nibWithNibName:@"TagmojiCell" bundle:nil] forCellWithReuseIdentifier:kTagmojiCellIdentifier];
}

- (IBAction) close:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.tagmoji.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFTagmojiCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTagmojiCellIdentifier forIndexPath:indexPath];

	NSDictionary* info = [self.tagmoji objectAtIndex:indexPath.item];
	cell.emojiField.text = [info objectForKey:@"emoji"];
	cell.titleField.text = [info objectForKey:@"title"];
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary* info = [self.tagmoji objectAtIndex:indexPath.item];
	
	[self dismissViewControllerAnimated:YES completion:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kSelectTagmojiNotification object:self userInfo:@{ kSelectTagmojiInfoKey: info }];
	}];
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat inset = 20;
	CGFloat w = ([UIScreen mainScreen].bounds.size.width / 2.0) - inset;
	CGFloat h = 30;
	
	return CGSizeMake (w, h);
}

@end
