//
//  UIImage+extension.m
//  WaterRipple
//
//  Created by ikuo on 2014/09/02.
//  Copyright (c) 2014年 aquaware. All rights reserved.
//

#import "UIImage+extension.h"
#import <CoreVideo/CVOpenGLESTextureCache.h>

@implementation UIImage (UIImage_extension)

+(CVPixelBufferRef) getPixelBuffer: (CGImageRef) image
{
    
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height,  kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (CGImageRef) rotateWithAngle: (CGFloat) angle;
{
    CGImageRef imageRef = self.CGImage;
    
    CGFloat angleInRadians = angle * (M_PI / 180);
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    
    CGRect imgRect = CGRectMake(0, 0, width, height);
    CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
    CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate( NULL,
                                                    rotatedRect.size.width,
                                                    rotatedRect.size.height,
                                                    8,
                                                    0,
                                                    colorSpace,
                                                    kCGImageAlphaPremultipliedFirst);
    CGContextSetAllowsAntialiasing(bmContext, YES);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    CGColorSpaceRelease(colorSpace);
    CGContextTranslateCTM(bmContext, +(rotatedRect.size.width/2), +(rotatedRect.size.height/2));
    CGContextRotateCTM(bmContext, angleInRadians);
    CGContextDrawImage(bmContext, CGRectMake(-width/2, -height/2, width, height),imageRef);
    CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
    CFRelease(bmContext);

    return rotatedImage;
}


@end
