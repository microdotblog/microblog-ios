//
//  RFUserController.m
//  Snippets
//
//  Created by Manton Reece on 11/15/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFUserController.h"

#import "RFClient.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "UIFont+Extras.h"
#import "UIView+Extras.h"
#import "UUDataCache.h"
#import "RFAutoCompleteCache.h"
#import "RFUserCache.h"
#import "RFAutoCompleteCache.h"
#import "UITraitCollection+Extras.h"
#import <SafariServices/SafariServices.h>

@interface RFUserController()<UIScrollViewDelegate>
    @property (nonatomic, strong) NSString* pathToBlog;
@end

@implementation RFUserController

- (instancetype) initWithEndpoint:(NSString *)endpoint username:(NSString *)username
{
    self = [super initWithNibName:@"User" endPoint:endpoint title:username];
    if (self)
    {
        self.username = username;
    }
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupFont];
	
	self.followingView.hidden = YES;
	
	self.navigationItem.rightBarButtonItem = nil;
	
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBlogAddressTapped:)];
    [self.blogAddressLabel addGestureRecognizer:tapGesture];
    self.blogAddressLabel.userInteractionEnabled = YES;
    
    self.fullNameLabel.text = self.username;
    self.bioLabel.text = @"";
    self.blogAddressLabel.text = @"";

	self.avatar.layer.cornerRadius = self.avatar.bounds.size.width / 2.0;
	
    [self fetchUserInfo];
}

- (void) setupRefresh
{
	self.webView.scrollView.showsHorizontalScrollIndicator = NO;
}

- (void) setupSpacing
{
	self.verticalOffsetConstraint.constant = 44 + [self.view rf_statusBarHeight];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self setupSpacing];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	self.navigationItem.rightBarButtonItem = nil;
	[self checkFollowing];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.moreButton.hidden = ![self hasMoreBioToShow];
}

- (void) setupNavigation
{
	[super setupNavigation];

	self.title = [NSString stringWithFormat:@"@%@", self.username];
}

- (void) setupFont
{
	CGFloat fontsize = [UIFont rf_preferredTimelineFontSize];
	self.fullNameLabel.font = [UIFont fontWithName:@"Avenir-Book" size:fontsize];
	self.blogAddressLabel.font = [UIFont fontWithName:@"Avenir-Book" size:fontsize];
	self.bioLabel.font = [UIFont fontWithName:@"Avenir-Book" size:fontsize];
	self.moreButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Book" size:fontsize];
}

- (void) checkFollowing
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/users/is_following"];
	NSDictionary* args = @{
		@"username": self.username
	};
	[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
		if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			BOOL is_following = [[response.parsedResponse objectForKey:@"is_following"] boolValue];
			BOOL is_you = [[response.parsedResponse objectForKey:@"is_you"] boolValue];
			RFDispatchMain (^{
				if (is_you) {
					self.navigationItem.rightBarButtonItem = nil;
				}
				else {
					[self setupFollowing:is_following];
				}
			});
		}
	}];
}

- (void) setupFollowing:(BOOL)isFollowing
{
	if (isFollowing) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Unfollow" style:UIBarButtonItemStylePlain target:self action:@selector(unfollow:)];
	}
	else {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Follow" style:UIBarButtonItemStylePlain target:self action:@selector(follow:)];
	}

	if ([UITraitCollection rf_isDarkMode]) {
		self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
	}
}

- (void) follow:(id)sender
{
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityView startAnimating];
    activityView.frame = CGRectMake(0, 0, 60, 40);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    
	RFClient* client = [[RFClient alloc] initWithPath:@"/users/follow"];
	NSDictionary* args = @{
		@"username": self.username
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMain (^{
			[self setupFollowing:YES];
		});
	}];
}

- (void) unfollow:(id)sender
{
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    [activityView startAnimating];
    activityView.frame = CGRectMake(0, 0, 60, 40);

	RFClient* client = [[RFClient alloc] initWithPath:@"/users/unfollow"];
	NSDictionary* args = @{
		@"username": self.username
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMain (^{
			[self setupFollowing:NO];
		});
	}];
}

- (IBAction) onShowMore:(id)sender
{
    NSInteger constraint = 250.0;
    if (self.maxHeaderHeightConstraint.constant <= 250.0)
    {
        NSInteger height = [self fullSizeOfBio];
        constraint = height + 25.0;
        
        [self.moreButton setTitle:@"less" forState:UIControlStateNormal];
    }
    else
    {
        [self.view setNeedsLayout];
        [self.moreButton setTitle:@"more" forState:UIControlStateNormal];
    }
    
    [UIView animateWithDuration:0.3 animations:^
    {
        self.maxHeaderHeightConstraint.constant = constraint;
        [self.view layoutIfNeeded];
    }];
}

- (IBAction) onFollowing:(id)sender
{
	if (self.isYou) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kShowUserFollowingNotification object:nil userInfo:@{ kShowUserFollowingUsernameKey : self.username } ];
	}
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName:kShowUserDiscoverNotification object:nil userInfo:@{ kShowUserDiscoverUsernameKey : self.username } ];
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - User Info
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) fetchUserInfo
{
	// Add this user to the autocomplete cache...
	[RFAutoCompleteCache addAutoCompleteString:self.username];

    NSDictionary* cachedUserInfo = [RFUserCache user:self.username];
    if (cachedUserInfo)
    {
        [self updateAppearanceFromDictionary:cachedUserInfo];
    }
    
    RFClient* client = [[RFClient alloc] initWithPath:[NSString stringWithFormat:@"/posts/%@", self.username]];
    [client getWithQueryArguments:nil completion:^(UUHttpResponse *response)
    {
		if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]])
        {
            NSDictionary* userInfo = response.parsedResponse;
            if (userInfo)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self updateAppearanceFromDictionary:userInfo];
                });
            }
        }
    }];
}

- (void) updateAppearanceFromDictionary:(NSDictionary*)userInfo
{
    NSDictionary* microBlogInfo = [userInfo objectForKey:@"_microblog"];
    NSDictionary* authorInfo = [userInfo objectForKey:@"author"];
    self.fullNameLabel.text = [authorInfo objectForKey:@"name"];
    self.bioLabel.text = [microBlogInfo objectForKey:@"bio"];
    self.blogAddressLabel.text = [authorInfo objectForKey:@"url"];
    self.isYou = [[microBlogInfo objectForKey:@"is_you"] boolValue];

    self.pathToBlog = [authorInfo objectForKey:@"url"];
	
	NSString* followingCountString = @"";
	if (microBlogInfo)
	{
		NSNumber* followingCountNumber;
		if (self.isYou) {
			followingCountNumber = [microBlogInfo objectForKey:@"following_count"];
		}
		else {
			followingCountNumber = [microBlogInfo objectForKey:@"discover_count"];
		}
		
		if (followingCountNumber)
		{
			followingCountString = followingCountNumber.stringValue;
		}
	}
	
	if (followingCountString.length > 0) {
		NSString* titleText;
		if (self.isYou) {
			titleText = [NSString stringWithFormat:@"Following %@", followingCountString];
		}
		else {
			titleText = [NSString stringWithFormat:@"Following %@ users you aren't following", followingCountString];
		}

		[self.followingButton setTitle:titleText forState:UIControlStateNormal];
		RFDispatchSeconds (0.1, ^{
			self.followingView.hidden = NO;
		});
	}
	
    NSString* avatarURL = [authorInfo objectForKey:@"avatar"];
    UIImage* image = [RFUserCache avatar:[NSURL URLWithString:avatarURL] completionHandler:^(UIImage * _Nonnull image)
    {
		self.avatar.image = image;
	}];

	self.avatar.image = image;
    
	
    [RFUserCache setCache:userInfo forUser:self.username];
    
    self.moreButton.hidden = ![self hasMoreBioToShow];
}

- (void) handleBlogAddressTapped:(id)sender
{
	@try {
		SFSafariViewController* safari_controller = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:self.pathToBlog]];
		[self presentViewController:safari_controller animated:YES completion:NULL];
	}
	@catch (NSException* e) {
	}
}

- (NSInteger) fullSizeOfBio
{
    UIFont* font = self.bioLabel.font;
    NSString* bio = self.bioLabel.text;
    NSInteger bioWidth = self.bioLabel.bounds.size.width;
    CGSize size = CGSizeMake(bioWidth, CGFLOAT_MAX);
    
    NSDictionary* attributes = @{ NSFontAttributeName : font };
    NSInteger bioHeight = [bio boundingRectWithSize:size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributes context:nil].size.height;
    NSInteger userViewInfoHeight = self.userInfoView.bounds.size.height;
    
    NSInteger height = userViewInfoHeight + 16.0 + bioHeight + 21.0;
    return height;
}

- (BOOL) hasMoreBioToShow
{
    return ([self fullSizeOfBio] > 250.0);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIScrollViewDelegate
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//- (void) scrollViewDidScroll:(UIScrollView *)scrollView
//{
//	NSInteger offset = scrollView.contentOffset.y;	
//	self.verticalOffsetConstraint.constant = -offset;
//	[self.view setNeedsLayout];
//}

@end
