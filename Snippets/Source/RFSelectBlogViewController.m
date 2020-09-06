//
//  RFSelectBlogViewController.m
//  Micro.blog
//
//  Created by Jonathan Hays on 4/26/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import "RFSelectBlogViewController.h"
#import "RFBlogTableViewCell.h"
#import "RFClient.h"
#import "UUAlert.h"
#import "RFSettings.h"
#import "UIBarButtonItem+Extras.h"

@implementation RFSelectBlogViewController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupTable];
	
	[self fetchBlogs];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self clearSelection];
}

- (void) setupNavigation
{
	if (self.isCancelable) {
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_closeBarButtonWithTarget:self action:@selector(cancel:)];
	}
}

- (void) setupTable
{
	self.tableView.layer.cornerRadius = 8.0;
}

- (void) fetchBlogs
{
	[self.progressSpinner startAnimating];

	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub?q=config"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (response.httpError) {
				[self showError:[response.httpError localizedDescription]];
			}
			else {
				self.blogs = [response.parsedResponse objectForKey:@"destination"];
				[self.tableView reloadData];
			}

			[self.progressSpinner stopAnimating];
		});
	}];
}

- (void) clearSelection
{
	NSIndexPath* index_path = self.tableView.indexPathForSelectedRow;
	if (index_path) {
		[self.tableView deselectRowAtIndexPath:index_path animated:NO];
	}
}

- (void) selectBlog:(NSDictionary*)blogInfo
{
	[RFSettings setSelectedBlogInfo:blogInfo];
	[RFSettings setAccountDefaultSite:[blogInfo objectForKey:@"name"]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kPostToBlogSelectedNotification object:blogInfo];
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) showError:(NSString *)error
{
	[self.progressSpinner stopAnimating];
	[UUAlertViewController uuShowOneButtonAlert:@"Error Creating Microblog" message:error button:@"OK" completionHandler:NULL];
}

- (IBAction) cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.blogs.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFBlogTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"BlogCell"];
	
	NSDictionary* blogInfo = [self.blogs objectAtIndex:indexPath.row];
	NSString* uid = [blogInfo objectForKey:@"uid"];
	NSString* name = [blogInfo objectForKey:@"name"];
	
	cell.nameField.text = name;
	cell.subtitleField.text = uid;
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary* info = [self.blogs objectAtIndex:indexPath.row];
	[self selectBlog:info];
}

@end
