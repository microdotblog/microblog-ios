//
//  RFDiscoverController.m
//  Micro.blog
//
//  Created by Manton Reece on 4/28/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFDiscoverController.h"

#import "RFFeaturedPhoto.h"
#import "RFFeaturedPhotoCell.h"
#import "RFClient.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "NSString+Extras.h"
#import "RFAutoCompleteCache.h"
#import "UIView+Extras.h"
#import "UIFont+Extras.h"

static NSString* const kPhotoCellIdentifier = @"PhotoCell";

@implementation RFDiscoverController

- (instancetype) init
{
    self = [super initWithNibName:@"Discover" bundle:nil];
    if (self) {
        self.endpoint = @"/hybrid/discover";
        self.timelineTitle = @"Discover";
    }
    
    return self;
}

- (instancetype) initWithEndpoint:(NSString *)endpoint title:(NSString *)title
{
    self = [self init];
    if (self) {
        self.endpoint = endpoint;
        self.timelineTitle = title;
    }
    
    return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupNavigation];
	[self setupSearchButton];
    [self setupEmojiPicker];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self setupSearchButton];
}

- (void) setupNavigation
{
	[super setupNavigation];

	self.title = @"Discover";
}

- (void) setupSearchButton
{
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleSearch:)];
}

- (void) setupEmojiPicker
{
    self.stackViewContainerView.hidden = YES;
    self.stackViewContainerView.layer.borderColor = UIColor.lightGrayColor.CGColor;
    self.stackViewContainerView.layer.borderWidth = 0.5;

    int width = self.view.bounds.size.width;
    CGFloat fontsize = [UIFont rf_preferredTimelineFontSize];
    
    RFClient* client = [[RFClient alloc] initWithFormat:@"%@?width=%d&fontsize=%f", @"/posts/discover", width, fontsize];
    [client getWithQueryArguments:nil completion:^(UUHttpResponse *response) {
        NSDictionary* dictionary = response.parsedResponse;
        if (dictionary && [dictionary isKindOfClass:[NSDictionary class]])
        {
            NSDictionary* microblogDictionary = [dictionary objectForKey:@"_microblog"];
            if (microblogDictionary && [microblogDictionary isKindOfClass:[NSDictionary class]])
            {
                NSArray* tagmoji = [microblogDictionary objectForKey:@"tagmoji"];
                if (tagmoji && [tagmoji isKindOfClass:[NSArray class]])
                {
                    self.tagmoji = tagmoji;
                    
                    [[NSUserDefaults standardUserDefaults] setObject:tagmoji forKey:@"Saved::Tagmoji"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self updateTagmoji];
                    });
                }
            }
            
        }
    }];
    
    self.tagmoji = [[NSUserDefaults standardUserDefaults] objectForKey:@"Saved::Tagmoji"];
    [self updateTagmoji];
    
    self.emojiPickerView.clipsToBounds = YES;
    self.emojiPickerView.layer.borderColor = UIColor.lightGrayColor.CGColor;
    self.emojiPickerView.layer.borderWidth = 1.0;
    self.emojiPickerView.layer.cornerRadius = 2.0;
}

- (void) updateTagmoji
{
    if (self.tagmoji)
    {
        self.emojiPickerView.hidden = NO;

        for (UIView* subview  in self.emojiStackView.arrangedSubviews)
        {
            [subview removeFromSuperview];
        }
        
        NSString* emojiList = @"";
        NSMutableArray* featuredEmoji = [NSMutableArray array];
        for (NSDictionary* dictionary in self.tagmoji)
        {
            NSNumber* featured = [dictionary objectForKey:@"is_featured"];
            NSString* emoji = [dictionary objectForKey:@"emoji"];
            if ([featured boolValue] == YES)
            {
                [featuredEmoji addObject:emoji];
            }
            
            NSString* title = [NSString stringWithFormat:@"%@ %@", emoji, [dictionary objectForKey:@"title"]];
            UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.emojiStackView.frame.size.width, 14.0)];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            [button setTitle:title forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:13.0];
            [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
            [button.titleLabel sizeToFit];
            button.tag = [self.tagmoji indexOfObject:dictionary];
            
            [self.emojiStackView addArrangedSubview:button];
            [button addTarget:self action:@selector(onHandleEmojiSelect:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        for (int i = 0; i < 3; i++)
        {
            NSUInteger index = arc4random_uniform((int)featuredEmoji.count);
            NSString* emoji = [featuredEmoji objectAtIndex:index];
            emojiList = [emojiList stringByAppendingString:emoji];
            [featuredEmoji removeObject:emoji];
        }
        
        self.emojiLabel.text = emojiList;
        [self.emojiLabel sizeToFit];
        [self.view layoutIfNeeded];
        
    }
    else {
        self.descriptionLabel.text = @"Some recent posts from the community.";
        self.emojiPickerView.hidden = YES;
    }
    
}

- (void) toggleSearch:(id)sender
{
	if (!self.searchBar) {
		[self showSearch];
	}
	else {
		[self hideSearch];
		
		self.endpoint = @"/hybrid/discover";
		[self refreshTimeline];
	}
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	self.endpoint = [NSString stringWithFormat:@"/hybrid/discover/search?q=%@", [searchBar.text rf_urlEncoded]];
	[self refreshTimeline];
	[self hideSearch];
}

- (UITextField *) findTextFieldInView:(UIView *)v
{
	id result = nil;
	
	for (UIView* sub in v.subviews) {
		if ([sub isKindOfClass:[UITextField class]]) {
			result = sub;
			break;
		}
		else {
			result = [self findTextFieldInView:sub];
		}
	}
	
	return result;
}

- (void) showSearch
{
	CGRect r = self.view.bounds;
	r.origin.y = 44 + [self.view rf_statusBarHeight];
	r.size.height = 44;
	self.searchBar = [[UISearchBar alloc] initWithFrame:r];
	self.searchBar.alpha = 0.0;
	self.searchBar.delegate = self;

	self.backdropView = [[UIView alloc] initWithFrame:self.view.bounds];
	self.backdropView.backgroundColor = [UIColor blackColor];
	self.backdropView.alpha = 0.0;
	
	UITapGestureRecognizer* tap_gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSearch:)];
	[self.backdropView addGestureRecognizer:tap_gesture];

	[self.view addSubview:self.backdropView];
	[self.view addSubview:self.searchBar];

	UITextField* field = [self findTextFieldInView:self.searchBar];
	if (field) {
		// to avoid animation glitch, temporary hide the cursor
		field.tintColor = [UIColor clearColor];
	}

	[UIView animateWithDuration:0.3 animations:^{
		self.searchBar.alpha = 1.0;
		self.backdropView.alpha = 0.15;
	} completion:^(BOOL finished) {
		[self.searchBar becomeFirstResponder];
		
		RFDispatchSeconds (1.0, ^{
			field.tintColor = nil;
		});
	}];
}

- (void) hideSearch
{
	[UIView animateWithDuration:0.3 animations:^{
		self.searchBar.alpha = 0.0;
		self.backdropView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[self.searchBar removeFromSuperview];
		[self.backdropView removeFromSuperview];
		self.searchBar = nil;
		self.backdropView = nil;
	}];
}

- (void) showPhotos
{
	UICollectionViewFlowLayout* flow_layout = [[UICollectionViewFlowLayout alloc] init];

	CGRect r = self.view.bounds;
	r.origin.y += (44 + [self.view rf_statusBarHeight]);
	r.size.height -= (44 + [self.view rf_statusBarHeight]);

	self.photosCollectionView = [[UICollectionView alloc] initWithFrame:r collectionViewLayout:flow_layout];
	self.photosCollectionView.delegate = self;
	self.photosCollectionView.dataSource = self;
	self.photosCollectionView.alpha = 0.0;
	self.photosCollectionView.backgroundColor = [UIColor whiteColor];
	
	[self.photosCollectionView registerNib:[UINib nibWithNibName:@"FeaturedPhotoCell" bundle:nil] forCellWithReuseIdentifier:kPhotoCellIdentifier];
	
	[self.view addSubview:self.photosCollectionView];
	
	RFClient* client = [[RFClient alloc] initWithPath:@"/discover/photos"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		NSMutableArray* featured_photos = [NSMutableArray array];
		if (response.parsedResponse) {
			for (NSDictionary* info in response.parsedResponse) {
				RFFeaturedPhoto* photo = [[RFFeaturedPhoto alloc] init];
				photo.username = info[@"username"];
				photo.imageURL = info[@"image_url"];
				[featured_photos addObject:photo];
				
				[RFAutoCompleteCache addAutoCompleteString:info[@"username"]];
			}
			
			RFDispatchMain (^{
				self.featuredPhotos = featured_photos;
				[self.photosCollectionView reloadData];
			});
		}
	}];
	
	[UIView animateWithDuration:0.3 animations:^{
		self.photosCollectionView.alpha = 1.0;
	}];
}

- (void) hidePhotos
{
	[UIView animateWithDuration:0.3 animations:^{
		self.photosCollectionView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[self.photosCollectionView removeFromSuperview];
		self.photosCollectionView = nil;
		self.featuredPhotos = @[];
	}];
}

- (IBAction) onSelectEmoji:(UIButton*)sender
{
    self.stackViewContainerView.hidden = !self.stackViewContainerView.hidden;
}

- (IBAction) onHandleEmojiSelect:(UIButton*)sender
{
    NSInteger index = sender.tag;
    NSDictionary* dictionary = [self.tagmoji objectAtIndex:index];
    NSString* name = [dictionary objectForKey:@"name"];
    NSString* description = [NSString stringWithFormat:@"Some %@ posts from the community.", [sender titleForState:UIControlStateNormal]];
    self.descriptionLabel.text = description;
    self.endpoint = [NSString stringWithFormat:@"/hybrid/discover/%@", name];
    self.stackViewContainerView.hidden = YES;
    [self refreshTimelineShowingSpinner:YES];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.featuredPhotos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFFeaturedPhotoCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellIdentifier forIndexPath:indexPath];

	RFFeaturedPhoto* photo = [self.featuredPhotos objectAtIndex:indexPath.item];
	[cell setupWithPhoto:photo];
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFFeaturedPhoto* photo = [self.featuredPhotos objectAtIndex:indexPath.item];
	NSString* username = photo.username;
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowUserProfileNotification object:self userInfo:@{ kShowUserProfileUsernameKey: username }];
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return CGSizeMake (100, 130);
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
	return UIEdgeInsetsMake (8, 5, 5, 5);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return 5;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
	return 0;
}

@end
