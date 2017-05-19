//
//  RFFilter.m
//  Micro.blog
//
//  Created by Manton Reece on 3/26/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFFilter.h"

#define RFSuppressPerformSelectorLeakWarning(Stuff) \
    do { \
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
        Stuff; \
        _Pragma("clang diagnostic pop") \
    } while (0)


@implementation RFFilter

+ (RFFilter*) filterFromDictionary:(NSDictionary*)filterDictionary
{
    RFFilter* filter = [RFFilter new];
    filter.name = filterDictionary[@"name"];
    filter.ciFilter = [CIFilter filterWithName:filterDictionary[@"ciFilter"]];
    
    if ([filterDictionary objectForKey:@"imagemap"])
    {
        NSString* imageMapName = filterDictionary[@"imagemap"];
        
        UIImage* imageMap = [UIImage imageNamed:imageMapName];
        CIImage* ciImageMap = [CIImage imageWithCGImage:imageMap.CGImage];
        SEL selector = NSSelectorFromString(@"setInputColorLookupTable:");
        if ([filter.ciFilter respondsToSelector:selector])
        {
            RFSuppressPerformSelectorLeakWarning(
                [filter.ciFilter performSelector:selector withObject:ciImageMap];
            );
        }
    }

    if ([filterDictionary objectForKey:@"intensity"])
    {
        NSNumber* intensity = filterDictionary[@"intensity"];
        SEL selector = NSSelectorFromString(@"setInputIntensity:");
        if ([filter.ciFilter respondsToSelector:selector])
        {
            RFSuppressPerformSelectorLeakWarning(
                [filter.ciFilter performSelector:selector withObject:intensity];
            );
        }
    }
    
    return filter;
}

+ (CIContext*) sharedContext
{
    static CIContext* theContext = nil;
    
    if (!theContext)
    {
        theContext = [CIContext context];
    }
        
    return theContext;
}


- (UIImage *) filterImage:(UIImage *)image
{
    CIContext *context = [RFFilter sharedContext];
    
    CIImage* ci_image = [CIImage imageWithCGImage:image.CGImage];
    [self.ciFilter setValue:ci_image forKey:kCIInputImageKey];
            
    CIImage* filtered_ci_image = [self.ciFilter valueForKey:kCIOutputImageKey];
    
    CGImageRef cgImage = [context createCGImage:filtered_ci_image fromRect:[ci_image extent]];
  
    UIImage* filteredImage = [UIImage imageWithCGImage:cgImage scale:[[UIScreen mainScreen] scale] orientation:image.imageOrientation];
    CGImageRelease(cgImage);

    return filteredImage;
}

@end
