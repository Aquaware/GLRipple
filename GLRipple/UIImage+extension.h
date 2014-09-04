//
//  UIImage+extension.h
//  WaterRipple
//
//  Created by ikuo on 2014/09/02.
//  Copyright (c) 2014年 aquaware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface UIImage (UIImage_extension)

+ (CVPixelBufferRef) getPixelBuffer: (CGImageRef) image;
- (CGImageRef) rotateWithAngle: (CGFloat) angle;
@end
