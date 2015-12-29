//
//  RadialView.m
//  SVGParser
//
//  Created by Laughing on 15/12/18.
//  Copyright © 2015年 WG. All rights reserved.
//

#import "RadialView.h"

@interface RadialView()
{
    
}

@end

@implementation RadialView

- (instancetype)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if (self)
    {
        //self.backgroundColor=[UIColor whiteColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx= UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
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
        CGContextSetAlpha(ctx, self.alpha);
        CGContextDrawRadialGradient(ctx, gradient, self.startPoint, 10, self.endPoint, 30, kCGGradientDrawsBeforeStartLocation);
        CGGradientRelease(gradient);
    }

    CGContextRestoreGState(ctx);
}

@end
