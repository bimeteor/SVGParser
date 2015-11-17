//
//  PathDrawingView.h
//  Drag
//
//  Created by frankgwang on 13-9-9.
//  Copyright (c) 2013年  WG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PathDrawingView : UIView
@property (nonatomic) UIBezierPath *bezierPath;
@property (nonatomic) UIColor *strokeColor;
@property (nonatomic) UIColor *fillColor;
@property (nonatomic) float lineWidth;
@property (nonatomic) float duration;
- (void)startAnimation;
- (void)stopAnimation;
@end
