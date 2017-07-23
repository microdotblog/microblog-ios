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
#import "UUDataCache.h"
#import <SafariServices/SafariServices.h>

@interface RFUserCache : NSObject

    + (NSDictionary*) user:(NSString*)user;
    + (void) setCache:(NSDictionary*)userInfo forUser:(NSString*)user;

    + (UIImage*) avatar:(NSURL*)url;
    + (void) cacheAvatar:(UIImage*)image forURL:(NSURL*)url;

@end

@implementation RFUserCache

+ (UIImage*) avatar:(NSURL*)url
{
    NSData* cachedData = [UUDataCache uuDataForURL:url];
    UIImage* image = [UIImage imageWithData:cachedData];
    return image;
}

+ (void) cacheAvatar:(UIImage*)image forURL:(NSURL*)url
{
    NSData* data = UIImagePNGRepresentation(image);
    [UUDataCache uuCacheData:data forURL:url];
}

+ (NSDictionary*) user:(NSString*)user
{
    NSDictionary* dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:user];
    return dictionary;
}

+ (void) setCache:(NSDictionary*)userInfo forUser:(NSString*)user
{
    [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:user];
}

@end


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
	self.navigationItem.rightBarButtonItem = nil;
    self.webView.scrollView.delegate = self;
    self.webView.scrollView.contentOffset = CGPointMake(0, 0);
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBlogAddressTapped:)];
    [self.blogAddressLabel addGestureRecognizer:tapGesture];
    self.blogAddressLabel.userInteractionEnabled = YES;
    
    self.fullNameLabel.text = self.username;
    self.bioLabel.text = @"";
    self.blogAddressLabel.text = @"";

	self.avatar.layer.cornerRadius = self.avatar.bounds.size.width / 2.0;
	
    [self fetchUserInfo];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	self.navigationItem.rightBarButtonItem = nil;
	[self checkFollowing];
}

- (void) setupNavigation
{
	[super setupNavigation];

	self.title = [NSString stringWithFormat:@"@%@", self.username];
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - User Info
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) fetchUserInfo
{
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
    
    self.pathToBlog = [authorInfo objectForKey:@"url"];
    
    NSString* avatarURL = [authorInfo objectForKey:@"avatar"];
    UIImage* image = [RFUserCache avatar:[NSURL URLWithString:avatarURL]];
    if (image)
    {
        self.avatar.image = image;
    }
    
    [UUHttpSession get:avatarURL queryArguments:nil completionHandler:^(UUHttpResponse *response)
    {
        if (response && !response.httpError)
        {
            NSData* imageData = response.rawResponse;
            UIImage* image = [UIImage imageWithData:imageData];
            [RFUserCache cacheAvatar:image forURL:[NSURL URLWithString:avatarURL]];

            dispatch_async(dispatch_get_main_queue(), ^
            {
                self.avatar.image = image;
            });
        }
    }];
    
    [RFUserCache setCache:userInfo forUser:self.username];
}

- (void) handleBlogAddressTapped:(id)sender
{
	SFSafariViewController* safari_controller = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:self.pathToBlog]];
	[self presentViewController:safari_controller animated:YES completion:NULL];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIScrollViewDelegate
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger offset = scrollView.contentOffset.y;
    
    //offset = 200 - offset;
    //if (offset < 0)
    //    offset = 0;
    
    self.verticalOffsetConstraint.constant = -offset;
    //self.headerHeightConstraint.constant = offset;
    [self.view setNeedsLayout];
}

@end
