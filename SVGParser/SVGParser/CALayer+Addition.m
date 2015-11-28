//
//  CALayer+CALayer_Addition.m
//  SVGParser
//
//  Created by WG on 15/11/28.
//  Copyright © 2015年 WG. All rights reserved.
//

#import "CALayer+Addition.h"
#import <objc/runtime.h>

@implementation CALayer (Addition)

- (void)setLinearGradientName:(NSString *)linearGradientName
{
    objc_setAssociatedObject(self, (const void*)1, linearGradientName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*)linearGradientName
{
    return objc_getAssociatedObject(self, (const void*)1);
}

@end
