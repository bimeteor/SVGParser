//
//  UIView+Addition.m
//  QCall
//
//  Created by frank on 14-7-7.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "UIView+Addition.h"

const NSRange NSRangeZero = {0, 0};

UIColor *color_rgb(int rgb)
{
    unsigned char *ptr=(unsigned char*)&rgb;
    return [UIColor colorWithRed:1.0*ptr[2]/0xff green:1.0*ptr[1]/0xff blue:1.0*ptr[0]/0xff alpha:1];
}

UIColor *color_rgba(int rgb, float alpha)
{
    unsigned char *ptr=(unsigned char*)&rgb;
    return [UIColor colorWithRed:1.0*ptr[2]/0xff green:1.0*ptr[1]/0xff blue:1.0*ptr[0]/0xff alpha:alpha];
}
