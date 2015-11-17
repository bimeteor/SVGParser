//
//  UIView+Addition.h
//  QCall
//
//  Created by frank on 14-7-7.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern const NSRange NSRangeZero;

#ifdef __cplusplus
extern "C"
{
#endif
    
    UIColor *color_rgb(int rgb);
    UIColor *color_rgba(int rgb, float alpha);
    
#ifdef __cplusplus
}
#endif
