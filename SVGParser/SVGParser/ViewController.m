//
//  ViewController.m
//  RichText
//
//  Created by Laughing on 15/11/9.
//  Copyright © 2015年 frank. All rights reserved.
//

#import "ViewController.h"
#import "UIView+NSLayoutExtension.h"
#import "PathDrawingView.h"
#import "QCEasyXMLParser.h"
#import "UIView+Addition.h"

typedef NS_ENUM(NSUInteger, SVGNodeType)
{
    SVGSVGNodeType,
    SVGGroupNodeType,
    SVGDefineNodeType,
    SVGEffectNodeType,
    SVGGraphNodeType,
    SVGTextNodeType,
    SVGViewNodeType,
};

NSString *graphs_names[]={@"path", @"line", @"rect", @"circle", @"ellipse", @"polyline", @"polygon"};

@interface ViewController ()
{
    NSMutableDictionary *_dict;
}
@end

@implementation ViewController

static UIColor *color_from_name(NSString *str)
{
    if ([str isEqualToString:@"none"]||[str isEqualToString:@"transparent"])
    {
        return [UIColor clearColor];
    }else if ([str isEqualToString:@"red"])
    {
        return [UIColor redColor];
    }else if ([str isEqualToString:@"blue"])
    {
        return [UIColor blueColor];
    }else if ([str isEqualToString:@"green"])
    {
        return [UIColor greenColor];
    }else if ([str isEqualToString:@"yellow"])
    {
        return [UIColor yellowColor];
    }else if ([str isEqualToString:@"orange"])
    {
        return [UIColor orangeColor];
    }else if ([str isEqualToString:@"black"])
    {
        return [UIColor blackColor];
    }
    return nil;
}

static UIBezierPath *path_from_d(NSString *str)
{
    NSScanner *scan=[NSScanner scannerWithString:str];
    UIBezierPath *path = [UIBezierPath bezierPath];
    while (!scan.atEnd)
    {
        NSString *ch1;
        BOOL flag=[scan scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&ch1];
        if (flag)
        {
            if ([ch1 isEqualToString:@"M"])
            {
                float x, y;
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                [path moveToPoint:point(x, y)];
            }else if ([ch1 isEqualToString:@"m"])
            {
                float x, y;
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                [path moveToPoint:point(x+path.currentPoint.x, y+path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"L"])
            {
                float x, y;
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                [path addLineToPoint:point(x, y)];
            }else if ([ch1 isEqualToString:@"l"])
            {
                float x, y;
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                [path addLineToPoint:point(x+path.currentPoint.x, y+path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"H"])
            {
                float x;
                [scan scanFloat:&x];
                [path addLineToPoint:point(x, path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"h"])
            {
                float x;
                [scan scanFloat:&x];
                [path addLineToPoint:point(x+path.currentPoint.x, path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"V"])
            {
                float y;
                [scan scanFloat:&y];
                [path addLineToPoint:point(path.currentPoint.x, y)];
            }else if ([ch1 isEqualToString:@"v"])
            {
                float y;
                [scan scanFloat:&y];
                [path addLineToPoint:point(path.currentPoint.x, y+path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"C"])
            {
                float x1, y1, x2, y2, x3, y3;
                [scan scanFloat:&x1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x3];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y3];
                [path addCurveToPoint:point(x3, y3) controlPoint1:point(x1, y1) controlPoint2:point(x2, y2)];
            }else if ([ch1 isEqualToString:@"c"])
            {
                float x1, y1, x2, y2, x3, y3;
                [scan scanFloat:&x1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x3];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y3];
                [path addCurveToPoint:point(x3+path.currentPoint.x, y3+path.currentPoint.y) controlPoint1:point(x1+path.currentPoint.x, y1+path.currentPoint.y) controlPoint2:point(x2+path.currentPoint.x, y2+path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"Z"]||[ch1 isEqualToString:@"z"])
            {
                [path closePath];
            }
        }else
        {
            break;
        }
    }
    NSLog(@"%@", [NSValue valueWithCGRect:path.bounds]);
    return path;
}

static void attr_from_raw_couple(NSString *key1, NSString *val1, NSString **key2, NSString **val2)
{
    *key2=nil,*val2=nil;
    //path
    if ([key1 isEqualToString:@"opacity"])
    {
        *key2=@"opacity",*val2=val1;
    }else if ([key1 isEqualToString:@"fill"])
    {
        if ([val1 isEqualToString:@"none"])
        {
            *key2=@"fillColor",*val2=(__bridge id)[UIColor clearColor].CGColor;
        }else
        {
            NSScanner *scan=[NSScanner scannerWithString:[val1 substringFromIndex:1]];
            unsigned num;
            [scan scanHexInt:&num];
            *key2=@"fillColor",*val2=(__bridge id)color_rgb(num).CGColor;
        }
    }else if ([key1 isEqualToString:@"fill-rule"])
    {
        if ([val1 isEqualToString:@"evenodd"])
        {
            *key2=@"fillRule",*val2=@"even-odd";
        }
    }else if ([key1 isEqualToString:@"stroke"])
    {
        if ([val1 isEqualToString:@"none"])
        {
            *key2=@"strokeColor",*val2=(__bridge id)[UIColor clearColor].CGColor;
        }else
        {
            NSScanner *scan=[NSScanner scannerWithString:[val1 substringFromIndex:1]];
            unsigned num;
            [scan scanHexInt:&num];
            *key2=@"strokeColor",*val2=(__bridge id)color_rgb(num).CGColor;
        }
    }else if ([key1 isEqualToString:@"stroke-width"])
    {
        *key2=@"lineWidth",*val2=val1;
    }else if ([key1 isEqualToString:@"stroke-linecap"])
    {
        *key2=@"lineCap",*val2=val1;
    }else if ([key1 isEqualToString:@"stroke-linejoin"])
    {
        *key2=@"lineJoin",*val2=val1;
    }else if ([key1 isEqualToString:@"stroke-miterlimit"])
    {
        *key2=@"miterLimit",*val2=val1;
    }
    //font
    else if ([key1 isEqualToString:@"font-size"])
    {
        *key2=@"fontSize",*val2=val1;
    }else if ([key1 isEqualToString:@"font-family"])
    {
        *key2=@"font",*val2=val1;
    }
}

static void shape_by_attrs(CAShapeLayer *layer, XMLNode *node)
{
    NSString *key, *val;
    for (NSString *tmp in node.attributes)
    {
        attr_from_raw_couple(tmp, node.attributes[tmp], &key, &val);
        if (key)
        {NSLog(@"%s %@ %@", __func__, key, val);
            [layer setValue:val forKey:key];
        }
    }
    while (node.parentNode)
    {
        if ([node.parentNode.name isEqualToString:@"g"])
        {
            for (NSString *tmp in node.parentNode.attributes)
            {
                attr_from_raw_couple(tmp, node.attributes[tmp], &key, &val);
                if (key)
                {NSLog(@"%s %@ %@", __func__, key, val);
                    [layer setValue:val forKey:key];
                }
            }
        }
        node=node.parentNode;
    }
}

CAShapeLayer *layer_from_path_node(XMLNode *node)
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path=path_from_d(node.attributes[@"d"]).CGPath;
    shape_by_attrs(layer, node);
    return layer;
}

CAShapeLayer *layer_from_line_node(XMLNode *node)
{
    UIBezierPath *path=[UIBezierPath bezierPath];
    [path moveToPoint:point([node.attributes[@"x1"] floatValue], [node.attributes[@"y1"] floatValue])];
    [path addLineToPoint:point([node.attributes[@"x2"] floatValue], [node.attributes[@"y2"] floatValue])];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path=path.CGPath;
    shape_by_attrs(layer, node);
    return layer;
}

CAShapeLayer *layer_from_rect_node(XMLNode *node)
{
    UIBezierPath *path=[UIBezierPath bezierPathWithRoundedRect:rect([node.attributes[@"x"] floatValue], [node.attributes[@"t"] floatValue], [node.attributes[@"width"] floatValue], [node.attributes[@"height"] floatValue]) cornerRadius:[node.attributes[@"rx"] floatValue]];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path=path.CGPath;
    shape_by_attrs(layer, node);
    return layer;
}

CAShapeLayer *layer_from_circle_node(XMLNode *node)
{
    UIBezierPath *path=[UIBezierPath bezierPathWithOvalInRect:rect([node.attributes[@"cx"] floatValue]-[node.attributes[@"rx"] floatValue], [node.attributes[@"cy"] floatValue]-[node.attributes[@"ry"] floatValue], [node.attributes[@"r"] floatValue]*2, [node.attributes[@"r"] floatValue]*2)];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path=path.CGPath;
    shape_by_attrs(layer, node);
    return layer;
}

CAShapeLayer *layer_from_ellipse_node(XMLNode *node)
{
    UIBezierPath *path=[UIBezierPath bezierPathWithOvalInRect:rect([node.attributes[@"cx"] floatValue]-[node.attributes[@"rx"] floatValue], [node.attributes[@"cy"] floatValue]-[node.attributes[@"ry"] floatValue], [node.attributes[@"rx"] floatValue]*2, [node.attributes[@"ry"] floatValue]*2)];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path=path.CGPath;
    shape_by_attrs(layer, node);
    return layer;
}

CAShapeLayer *layer_from_polyline_node(XMLNode *node)
{
    NSScanner *scan=[NSScanner scannerWithString:node.attributes[@"points"]];
    CGPoint point;
    [scan scanDouble:&point.x];
    [scan scanDouble:&point.y];
    UIBezierPath *path=[UIBezierPath bezierPath];
    [path moveToPoint:point];
    while (!scan.atEnd)
    {
        [scan scanDouble:&point.x];
        [scan scanDouble:&point.y];
        [path moveToPoint:point];
    }
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path=path.CGPath;
    shape_by_attrs(layer, node);
    return layer;
}

CAShapeLayer *layer_from_polygon_node(XMLNode *node)
{
    NSScanner *scan=[NSScanner scannerWithString:node.attributes[@"points"]];
    CGPoint point;
    [scan scanDouble:&point.x];
    [scan scanDouble:&point.y];
    UIBezierPath *path=[UIBezierPath bezierPath];
    [path moveToPoint:point];
    while (!scan.atEnd)
    {
        [scan scanDouble:&point.x];
        [scan scanDouble:&point.y];
        [path moveToPoint:point];
    }
    [path closePath];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path=path.CGPath;
    shape_by_attrs(layer, node);
    return layer;
}

CATextLayer *layer_from_text_node(XMLNode *node)
{
    CATextLayer *layer=[CATextLayer layer];
    layer.contentsScale=[UIScreen mainScreen].scale;
    layer.string=node.value;
    layer.frame=rect([node.attributes[@"x"] floatValue], [node.attributes[@"y"] floatValue], [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);//TODO:frank
    //shape_by_attrs(layer, node);//TODO:frank
    return layer;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (flag)
    {
        void (^result)(void) = [anim valueForKey:@"result"];
        if (result)
        {
            result();
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CATextLayer *lay=[CATextLayer layer];
    [self.view.layer addSublayer:lay];
    lay.contentsScale=[UIScreen mainScreen].scale;
    lay.frame=rect(10, 20, 200, 70);
    lay.string=@"qrqwerq";
    lay.foregroundColor=[UIColor redColor].CGColor;
    lay.font=(__bridge_retained CFTypeRef)@"Verdana";
    
    CALayer *layer=[CALayer layer];
    layer.frame=CGRectMake(50, 90, 200, 200);
    [self.view.layer addSublayer:layer];
    layer.transform=CATransform3DMakeScale(0.5, 0.5, 1);
    
    NSString *path=[[NSBundle mainBundle] pathForResource:@" dov_all_loading" ofType:@"svg"];
    XMLNode *node=[QCEasyXMLParser nodeWithData:[NSData dataWithContentsOfFile:path]];
    _dict=[NSMutableDictionary new];
    for (int i=0; i<7; ++i)
    {
        NSString *str=[NSString stringWithFormat:@"XMLID_%i_", i+1];
        XMLNode *node1=[node nodeForAttributeKey:@"id" value:str];
        if ([node1.name isEqualToString:@"path"])
        {
            CAShapeLayer *layer1=layer_from_path_node(node1);
            [layer addSublayer:layer1];
            layer1.frame=CGRectMake(0, 0, 200, 200);
            _dict[str]=layer1;
            layer1.hidden = YES;
        }
    }
    //outline
    [_dict[@"XMLID_7_"] setHidden:NO];
    [(CALayer*)_dict[@"XMLID_7_"] setTransform:CATransform3DMakeScale(-1, 1, 1)];
    CABasicAnimation *anim=[CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    anim.fromValue=@0;
    anim.duration=1;
    anim.delegate = self;
    void (^result)(void)=^(){
        //nose
        [_dict[@"XMLID_3_"] setHidden:NO];
        //mouse
        [_dict[@"XMLID_4_"] setHidden:NO];
        //hand
        [_dict[@"XMLID_5_"] setHidden:NO];
        [(CALayer*)_dict[@"XMLID_5_"] setTransform:CATransform3DMakeScale(-1, 1, 1)];
        //unknown
        [_dict[@"XMLID_6_"] setHidden:NO];
        //eye
        [_dict[@"XMLID_1_"] setHidden:NO];
        [_dict[@"XMLID_2_"] setHidden:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CATransaction setDisableActions:YES];
            UIBezierPath *path1=[UIBezierPath bezierPathWithCGPath:[_dict[@"XMLID_1_"] path]];
            CGPoint center=point(path1.bounds.origin.x+path1.bounds.size.width/2, path1.bounds.origin.y+path1.bounds.size.height/2);
            [_dict[@"XMLID_1_"] setAnchorPoint:point(center.x/200, center.y/200)];
            [_dict[@"XMLID_1_"] setPosition:center];
            
            path1=[UIBezierPath bezierPathWithCGPath:[_dict[@"XMLID_2_"] path]];
            center=point(path1.bounds.origin.x+path1.bounds.size.width/2, path1.bounds.origin.y+path1.bounds.size.height/2);
            [_dict[@"XMLID_2_"] setAnchorPoint:point(center.x/200, center.y/200)];
            [_dict[@"XMLID_2_"] setPosition:center];
            CABasicAnimation *anim=[CABasicAnimation animationWithKeyPath:@"transform"];
            anim.toValue=[NSValue valueWithCATransform3D:CATransform3DMakeScale(1, 0.25, 1)];
            anim.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            anim.duration=0.2;
            anim.autoreverses=YES;
            anim.repeatCount=2;
            [_dict[@"XMLID_1_"] addAnimation:anim forKey:@"strokeEnd"];
            [_dict[@"XMLID_2_"] addAnimation:anim forKey:@"strokeEnd"];
        });
    };
    [anim setValue:result forKey:@"result"];
    [_dict[@"XMLID_7_"] addAnimation:anim forKey:@"strokeEnd"];
}

@end