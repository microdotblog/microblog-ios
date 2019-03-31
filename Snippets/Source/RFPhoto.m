//
//  RFPhoto.m
//  Micro.blog
//
//  Created by Manton Reece on 3/22/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFPhoto.h"
#import "UUImage.h"

@implementation RFPhoto

- (id) initWithAsset:(PHAsset *)asset
{
	self = [super init];
	if (self) {
		self.asset = asset;
		self.altText = @"";
	}
	
	return self;
}

- (id) initWithThumbnail:(UIImage *)image
{
	self = [super init];
	if (self) {
        self.thumbnailImage = [RFPhoto sanitizeImage:image];
        
		self.altText = @"";
	}
	
	return self;
}

- (id) initWithVideo:(NSURL*)url thumbnail:(UIImage*)thumbnail
{
	self = [super init];
	if (self) {
		self.thumbnailImage = thumbnail;
		self.videoURL = url;
		
		self.altText = @"";
	}
		
	return self;
}

	
- (void) generateVideoThumbnail:(void(^)(UIImage* thumbnail))completionBlock
{
	PHImageManager* manager = [PHImageManager defaultManager];
	PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
	options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
	options.resizeMode = PHImageRequestOptionsResizeModeNone;
	options.networkAccessAllowed = YES;
	options.synchronous = NO;
	
	CGSize size = CGSizeMake(240.0, 240.0);
	
	[manager requestImageForAsset:self.asset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage* result, NSDictionary* info)
	{
		completionBlock(result);
	}];
}
	
- (void) generateVideoURL:(void(^)(NSURL* url))completionBlock
{
	PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
	options.networkAccessAllowed = YES;
	options.version = PHVideoRequestOptionsVersionCurrent;
	options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
	
	[[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info)
	{
		NSString* localPath = [RFPhoto localPathForVideoData];
		AVAssetExportSession* exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPreset640x480];
		exportSession.outputURL = [NSURL fileURLWithPath:localPath];
		exportSession.outputFileType = AVFileTypeAppleM4V;
		[exportSession exportAsynchronouslyWithCompletionHandler:^
		 {
			 self.videoURL = exportSession.outputURL;
			 completionBlock(self.videoURL);
		 }];
	}];
}

+ (NSString*) localPathForVideoData
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docs_folder = [paths objectAtIndex:0];
	NSString* images_folder = [docs_folder stringByAppendingPathComponent:@"Videos"];
	[[NSFileManager defaultManager] createDirectoryAtPath:images_folder withIntermediateDirectories:YES attributes:nil error:nil];
		
	CFUUIDRef uuid = CFUUIDCreate (NULL);
	NSString* image_guid = (NSString *) CFBridgingRelease (CFUUIDCreateString (NULL, uuid));
	CFRelease (uuid);
		
	NSString* image_path = [[images_folder stringByAppendingPathComponent:image_guid] stringByAppendingPathExtension:@"mp4"];
		
	return image_path;
}
	
+ (UIImage*) sanitizeImage:(UIImage*)image
{
    UIImage* sanitizedImage = image;
	if (sanitizedImage.size.width > 1800 && sanitizedImage.size.height > 1800)
	{
		sanitizedImage = [image uuScaleSmallestDimensionToSize:1800.0];
	}
	
    sanitizedImage = [sanitizedImage uuRemoveOrientation];
    return sanitizedImage;
}


@end
