//
//  CAGradientLayer+Radial.m
//  SVGParser
//
//  Created by Laughing on 15/12/16.
//  Copyright © 2015年 WG. All rights reserved.
//

#import "CAGradientLayer+Radial.h"
#import <objc/runtime.h>

NSString *kCAGradientLayerRadial=@"kCAGradientLayerRadial";

@implementation CAGradientLayer (Radial)

- (void)setRadius:(float)radius
{
    objc_setAssociatedObject(self, (void*)1, @(radius), OBJC_ASSOCIATION_RETAIN);
}

- (float)radius
{
    return [objc_getAssociatedObject(self, (void*)1) floatValue];
}

- (void)drawInContext:(CGContextRef)ctx
{
    CGContextSaveGState(ctx);
    if ([self.type isEqualToString:kCAGradientLayerRadial])
    {
        size_t count = self.locations.count;
        CGColorSpaceRef colorSpace = NULL;
        if (self.colors.count>0)
        {
            CGColorRef colorRef = (__bridge CGColorRef)self.colors.firstObject;
            colorSpace = CGColorGetColorSpace(colorRef);
            CGFloat locs[count];
            for (int i = 0; i < count; ++i)
            {
                locs[i] = [self.locations[i] floatValue];
            }
            CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) self.colors, locs);
            CGContextSetAlpha(ctx, self.opacity);
            CGContextDrawRadialGradient(ctx, gradient, self.startPoint, 0, self.endPoint, 20, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
        }
    }else if (!CGRectIsEmpty(self.bounds))
    {
        [super drawInContext:ctx];
    }
    CGContextRestoreGState(ctx);
}

@end
