//
//  UIView+NSLayoutExtension.m
//  QCall
//
//  Created by Laughing on 14/11/5.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "UIView+NSLayoutExtension.h"
#import <Accelerate/Accelerate.h>

@implementation UIView(NSLayoutExtension)

- (void)setWidth:(CGFloat)width
{
    self.size = CGSizeMake(width, self.height);
}

- (CGFloat)width
{
    return CGRectGetWidth(self.bounds);
}

- (void)setHeight:(CGFloat)height
{
    self.size = CGSizeMake(self.width, height);
}

- (CGFloat)height
{
    return CGRectGetHeight(self.bounds);
}

- (void)setOrigin:(CGPoint)origin
{
    self.center = CGPointMake(origin.x+self.width/2, origin.y+self.height/2);
}

- (CGPoint)origin
{
    return self.frame.origin;
}

- (void)setSize:(CGSize)size
{
    self.frame=CGRectMake(self.left, self.top, size.width, size.height);
}

- (CGSize)size
{
    return self.bounds.size;
}

- (CGFloat)top
{
    return CGRectGetMinY(self.frame);
}

- (void)setTop:(CGFloat)top
{
    self.centerY = top+self.height/2;
}

- (CGFloat)bottom
{
    return CGRectGetMaxY(self.frame);
}

- (void)setBottom:(CGFloat)bottom
{
    self.centerY = bottom-self.height/2;
}

- (CGFloat)left
{
    return CGRectGetMinX(self.frame);
}

- (void)setLeft:(CGFloat)left
{
    self.centerX = left+self.width/2;
}

- (CGFloat)right
{
    return CGRectGetMaxX(self.frame);
}

- (void)setRight:(CGFloat)right
{
    self.centerX = right-self.width/2;
}

- (CGFloat)centerX
{
    return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX
{
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY
{
    return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY
{
    self.center = CGPointMake(self.center.x, centerY);
}

+ (void)addConstraints:(NSArray*)constraints toView:(UIView*)view
{
    if ([NSLayoutConstraint resolveClassMethod:@selector(activateConstraints:)])
    {
        [NSLayoutConstraint activateConstraints:constraints];
    }else
    {
        [view addConstraints:constraints];
    }
}

+ (void)removeConstraints:(NSArray*)constraints fromView:(UIView*)view
{
    if ([NSLayoutConstraint resolveClassMethod:@selector(deactivateConstraints:)])
    {
        [NSLayoutConstraint deactivateConstraints:constraints];
    }else
    {
        [view removeConstraints:constraints];
    }
}

@end

CGPoint point(float x, float y)
{
    return CGPointMake(x, y);
}

CGSize size(float width, float height)
{
    return CGSizeMake(width, height);
}

CGRect rect(float x, float y, float width, float height)
{
    return CGRectMake(x, y, width, height);
}

@implementation UIView(SnapShot)

- (UIImage*)snapShot
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    //[self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@implementation UIImage(Blur)

- (UIImage*)blurredImageWithLevel:(float)level
{
    if (level < 0.f || level > 1.f) {
        level = 0.5f;
    }
    int boxSize = (int)(level * 100);
    boxSize = boxSize - (boxSize % 2) + 1;
    
    CGImageRef img = self.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    
    vImage_Error error;
    
    void *pixelBuffer;
    
    
    //create vImage_Buffer with data from CGImageRef
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    //create vImage_Buffer for output
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    // Create a third buffer for intermediate processing
    void *pixelBuffer2 = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    vImage_Buffer outBuffer2;
    outBuffer2.data = pixelBuffer2;
    outBuffer2.width = CGImageGetWidth(img);
    outBuffer2.height = CGImageGetHeight(img);
    outBuffer2.rowBytes = CGImageGetBytesPerRow(img);
    
    //perform convolution
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer2, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    error = vImageBoxConvolve_ARGB8888(&outBuffer2, &inBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(pixelBuffer2);
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    CGImageRelease(imageRef);
    
    return returnImage;
}

@end


@implementation UIToolbar(BlurEffect)

- (void)blur
{
    if ([UIDevice currentDevice].systemVersion.floatValue>=7)
    {
        self.translucent = YES;
        self.barStyle = UIBarStyleBlack;
    } else {
        self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
    }
}

@end
