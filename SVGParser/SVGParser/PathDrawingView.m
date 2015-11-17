//
//  PathDrawingView.m
//  Drag
//
//  Created by frankgwang on 13-9-9.
//  Copyright (c) 2013年  WG. All rights reserved.
//

#import "PathDrawingView.h"
#import <QuartzCore/QuartzCore.h>

@interface PathDrawingView()
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@end

@implementation PathDrawingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _shapeLayer=[CAShapeLayer layer];
		[self.layer addSublayer:_shapeLayer];
		_shapeLayer.backgroundColor=[UIColor clearColor].CGColor;
		
		_shapeLayer.strokeColor=[[UIColor blueColor] CGColor];
		_shapeLayer.fillColor=[[UIColor redColor] CGColor];
		_shapeLayer.lineWidth=1.5;
		
		_duration=2;
    }
    return self;
}

- (void)setFillColor:(UIColor *)fillColor
{
    _fillColor = fillColor;
    _shapeLayer.fillColor=fillColor.CGColor;
}

- (void)setStrokeColor:(UIColor *)strokeColor
{
	_strokeColor=strokeColor;
	_shapeLayer.strokeColor=strokeColor.CGColor;
}

- (void)setLineWidth:(float)lineWidth
{
	_lineWidth=lineWidth;
	_shapeLayer.lineWidth=lineWidth;
}

- (void)setBezierPath:(UIBezierPath *)bezierPath
{
	_bezierPath=bezierPath;
	_shapeLayer.frame=CGRectMake(0, 0, bezierPath.bounds.size.width, bezierPath.bounds.size.height);
	_shapeLayer.path=bezierPath.CGPath;
}

- (void)startAnimation
{
	if (_bezierPath==nil)
		return;
	
	[_shapeLayer removeAllAnimations];
	
	CABasicAnimation *anim=[CABasicAnimation animationWithKeyPath:@"strokeEnd"];
	anim.fromValue=@0, anim.toValue=@1;
	anim.duration=_duration;
	[_shapeLayer addAnimation:anim forKey:@"strokeEnd"];
}

- (void)stopAnimation
{
	[_shapeLayer removeAllAnimations];
}

@end
