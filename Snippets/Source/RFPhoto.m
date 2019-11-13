//
//  RFPhoto.m
//  Micro.blog
//
//  Created by Manton Reece on 3/22/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFPhoto.h"
#import "UUImage.h"
#import "UUAlert.h"
#import "SDAVAssetExportSession.h"
#import "RFMacros.h"

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

- (id) initWithVideo:(NSURL*)url asset:(PHAsset*)asset
{
	self = [super init];
	if (self) {
		self.videoURL = url;
		self.asset = asset;
		self.altText = @"";
	}
	
	return self;
}
	
- (void) generateVideoThumbnail:(void(^)(UIImage* thumbnail))completionBlock
{
	PHImageManager* manager = [PHImageManager defaultManager];
	PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
	options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
	options.resizeMode = PHImageRequestOptionsResizeModeExact;
	options.networkAccessAllowed = YES;
	options.synchronous = NO;
	
	CGSize size = CGSizeMake(320.0, 320.0);
	
	[manager requestImageForAsset:self.asset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage* result, NSDictionary* info)
	{
		self.thumbnailImage = result;
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
		NSArray* videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
		AVAssetTrack* videoTrack = [videoTracks objectAtIndex:0];
		CGSize size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
		size.width = fabs(size.width);
		size.height = fabs(size.height);

		NSString* localPath = [RFPhoto localPathForVideoData];
		SDAVAssetExportSession* exportSession = [[SDAVAssetExportSession alloc] initWithAsset:asset];
		exportSession.outputURL = [NSURL fileURLWithPath:localPath];
		exportSession.outputFileType = AVFileTypeAppleM4V;
		exportSession.videoSettings = [RFPhoto videoSettingsForSize:size];
		exportSession.audioSettings = [RFPhoto audioSettings];

		[exportSession exportAsynchronouslyWithCompletionHandler:^{
			RFDispatchMain (^{
				NSURL* file_url = exportSession.outputURL;
				NSDictionary* file_info = [[NSFileManager defaultManager] attributesOfItemAtPath:file_url.path error:NULL];
				NSNumber* file_size = [file_info objectForKey:NSFileSize];
				if ([file_size integerValue] > 45000000) { // 45 MB
					NSString* msg = @"Micro.blog is designed for short videos. File uploads should be 45 MB or less. (Usually about 2 minutes of video.)";
					[UUAlertViewController uuShowOneButtonAlert:@"Video Can't Be Uploaded" message:msg button:@"OK" completionHandler:NULL];
				}
				else {
					self.videoURL = file_url;
					completionBlock(self.videoURL);
				}
			});
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

+ (NSDictionary *) videoSettingsForSize:(CGSize)size
{
	NSInteger new_width;
	NSInteger new_height;

	if ((size.width == 0) || (size.height == 0)) {
		new_width = 640;
		new_height = 480;
	}
	else if ((size.width > 640) && (size.height > 640)) {
		if (size.width > size.height) {
			new_width = 640;
			new_height = size.height * (new_width / size.width);
		}
		else {
			new_height = 640;
			new_width = size.width * (new_height / size.height);
		}
	}
	else {
		new_width = size.width;
		new_height = size.height;
	}

	if (@available(iOS 11.0, *)) {
		return @{
				 AVVideoCodecKey: AVVideoCodecTypeH264,
				 AVVideoWidthKey: @(new_width),
				 AVVideoHeightKey: @(new_height),
				 AVVideoCompressionPropertiesKey: @{
						 AVVideoAverageBitRateKey: @3000000,
						 AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
						 }
				 };
	} else {
		return @{
				 AVVideoCodecKey: AVVideoCodecH264,
				 AVVideoWidthKey: @(new_width),
				 AVVideoHeightKey: @(new_height),
				 AVVideoCompressionPropertiesKey: @{
						 AVVideoAverageBitRateKey: @3000000,
						 AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
						 }
				 };
	}
}

+ (NSDictionary *) audioSettings
{
	return @{
		AVFormatIDKey: @(kAudioFormatMPEG4AAC),
		AVNumberOfChannelsKey: @1,
		AVSampleRateKey: @44100,
		AVEncoderBitRateKey: @128000,
	};
}

@end
