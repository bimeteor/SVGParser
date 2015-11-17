//
//  UIView+NSLayoutExtension.h
//  QCall
//
//  Created by Laughing on 14/11/5.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView(NSLayoutExtension)

@property (nonatomic) CGFloat top;
@property (nonatomic) CGFloat bottom;
@property (nonatomic) CGFloat left;
@property (nonatomic) CGFloat right;

@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;

@property (nonatomic) CGPoint origin;
@property (nonatomic) CGSize size;

@property (nonatomic) CGFloat centerX;
@property (nonatomic) CGFloat centerY;


+ (void)addConstraints:(NSArray*)constraints toView:(UIView*)view;
+ (void)removeConstraints:(NSArray*)constraints fromView:(UIView*)view;

@end

@interface UIView(SnapShot)
- (UIImage*)snapShot;
@end


@interface UIImage(Blur)
- (UIImage*)blurredImageWithLevel:(float)level;
@end

@interface UIToolbar(BlurEffect)

- (void)blur;

@end

CGPoint point(float x, float y);
CGSize size(float width, float height);
CGRect rect(float x, float y, float width, float height);
