//
//  CAGradientLayer+Radial.m
//  SVGParser
//
//  Created by Laughing on 15/12/16.
//  Copyright © 2015年 WG. All rights reserved.
//

#import "CAGradientLayer+Radial.h"

NSString *kCAGradientLayerRadial=@"kCAGradientLayerRadial";

@implementation CAGradientLayer (Radial)

- (void)drawInContext:(CGContextRef)ctx
{
    [super drawInContext:ctx];
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
            CGContextDrawRadialGradient(ctx, gradient, self.startPoint, [[self valueForKey:@"startRadius"] floatValue], self.endPoint, [[self valueForKey:@"endRadius"] floatValue], kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
            
        }
    }else if (!CGRectIsEmpty(self.bounds))
    {
        [super drawInContext:ctx];
    }
}

@end
