//
//  SVGParser.m
//  SVGParser
//
//  Created by Laughing on 15/11/28.
//  Copyright © 2015年 WG. All rights reserved.
//

#import "SVGParser.h"
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

#pragma mark - attrs from string

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
    }else if ([str isEqualToString:@"purple"])
    {
        return [UIColor purpleColor];
    }
    return nil;
}

static UIColor *color_from_color_str(NSString *str)
{
    UIColor *color=color_from_name(str);
    if (!color)
    {
        NSScanner *scan=[NSScanner scannerWithString:str];
        [scan scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:nil];
        if (!scan.isAtEnd)
        {
            unsigned num;
            [scan scanHexInt:&num];
            color=color_rgb(num);
        }
    }
    if (!color)
    {
        color=[UIColor blueColor];
    }
    return color;
}

static UIBezierPath *path_from_d_str(NSString *str)
{
    NSScanner *scan=[NSScanner scannerWithString:str];
    UIBezierPath *path = [UIBezierPath bezierPath];
    float last_anchor_x=0, last_anchor_y=0;
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
                [path moveToPoint:CGPointMake(x, y)];
            }else if ([ch1 isEqualToString:@"m"])
            {
                float x, y;
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                [path moveToPoint:CGPointMake(x+path.currentPoint.x, y+path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"L"])
            {
                float x, y;
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                [path addLineToPoint:CGPointMake(x, y)];
            }else if ([ch1 isEqualToString:@"l"])
            {
                float x, y;
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                [path addLineToPoint:CGPointMake(x+path.currentPoint.x, y+path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"H"])
            {
                float x;
                [scan scanFloat:&x];
                [path addLineToPoint:CGPointMake(x, path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"h"])
            {
                float x;
                [scan scanFloat:&x];
                [path addLineToPoint:CGPointMake(x+path.currentPoint.x, path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"V"])
            {
                float y;
                [scan scanFloat:&y];
                [path addLineToPoint:CGPointMake(path.currentPoint.x, y)];
            }else if ([ch1 isEqualToString:@"v"])
            {
                float y;
                [scan scanFloat:&y];
                [path addLineToPoint:CGPointMake(path.currentPoint.x, y+path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"C"])
            {
                float x1, y1, x2, y2, x, y;
                [scan scanFloat:&x1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                last_anchor_x=x2, last_anchor_y=y2;
                [path addCurveToPoint:CGPointMake(x, y) controlPoint1:CGPointMake(x1, y1) controlPoint2:CGPointMake(x2, y2)];
            }else if ([ch1 isEqualToString:@"c"])
            {
                float x1, y1, x2, y2, x, y;
                [scan scanFloat:&x1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                last_anchor_x=x2+path.currentPoint.x, last_anchor_y=y2+path.currentPoint.y;
                [path addCurveToPoint:CGPointMake(x+path.currentPoint.x, y+path.currentPoint.y) controlPoint1:CGPointMake(x1+path.currentPoint.x, y1+path.currentPoint.y) controlPoint2:CGPointMake(x2+path.currentPoint.x, y2+path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"S"])
            {
                float x2, y2, x, y;
                [scan scanFloat:&x2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                float tmp_x=last_anchor_x, tmp_y=last_anchor_y;
                last_anchor_x=x2, last_anchor_y=y2;
                [path addCurveToPoint:CGPointMake(x, y) controlPoint1:CGPointMake(2*path.currentPoint.x-tmp_x, 2*path.currentPoint.y-tmp_y) controlPoint2:CGPointMake(x2, y2)];
            }else if ([ch1 isEqualToString:@"s"])
            {
                float x2, y2, x, y;
                [scan scanFloat:&x2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y2];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                float tmp_x=last_anchor_x, tmp_y=last_anchor_y;
                last_anchor_x=x2+path.currentPoint.x, last_anchor_y=y2+path.currentPoint.y;
                [path addCurveToPoint:CGPointMake(x+path.currentPoint.x, y+path.currentPoint.y) controlPoint1:CGPointMake(2*path.currentPoint.x-tmp_x, 2*path.currentPoint.y-tmp_y) controlPoint2:CGPointMake(x2+path.currentPoint.x, y2+path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"Q"])
            {
                float x1, y1, x, y;
                [scan scanFloat:&x1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                last_anchor_x=x1, last_anchor_y=y1;
                [path addQuadCurveToPoint:CGPointMake(x, y) controlPoint:CGPointMake(x1, y1)];
            }else if ([ch1 isEqualToString:@"q"])
            {
                float x1, y1, x, y;
                [scan scanFloat:&x1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y1];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                last_anchor_x=x1+path.currentPoint.x, last_anchor_y=y1+path.currentPoint.y;
                [path addQuadCurveToPoint:CGPointMake(x+path.currentPoint.x, y+path.currentPoint.y) controlPoint:CGPointMake(x1+path.currentPoint.x, y1+path.currentPoint.y)];
            }else if ([ch1 isEqualToString:@"T"])
            {
                float x, y;
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                float tmp_x=last_anchor_x, tmp_y=last_anchor_y;
                last_anchor_x=x, last_anchor_y=y;
                [path addQuadCurveToPoint:CGPointMake(x, y) controlPoint:CGPointMake(2*path.currentPoint.x-tmp_x, 2*path.currentPoint.y-tmp_y)];
            }else if ([ch1 isEqualToString:@"t"])
            {
                float x, y;
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                float tmp_x=last_anchor_x, tmp_y=last_anchor_y;
                last_anchor_x=x+path.currentPoint.x, last_anchor_y=y+path.currentPoint.y;
                [path addQuadCurveToPoint:CGPointMake(x+path.currentPoint.x, y+path.currentPoint.y) controlPoint:CGPointMake(2*path.currentPoint.x-tmp_x, 2*path.currentPoint.y-tmp_y)];
            }/*else if ([ch1 isEqualToString:@"A"])
            {
                float rx, ry, big, clock, x, y;
                [scan scanFloat:&rx];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&ry];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:NULL];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&big];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&clock];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                float cx=path.currentPoint.x+(((y<=path.currentPoint.y?clock:!clock)?big:!big)?1:-1)*(rx+ry)/2*fabs(x-path.currentPoint.x)/sqrtf(powf(x-path.currentPoint.x, 2)+powf(y-path.currentPoint.y, 2));
                float cy=path.currentPoint.y+(y-path.currentPoint.y)*(cx-path.currentPoint.x)/(x-path.currentPoint.x);
                [path addArcWithCenter:CGPointMake(cx, cy) radius:(rx+ry)/2 startAngle:atanf((path.currentPoint.y-cy)/(path.currentPoint.x-cx)) endAngle:atanf((y-cy)/(x-cx)) clockwise:clock];
            }else if ([ch1 isEqualToString:@"a"])
            {
                float rx, ry, big, clock, x, y;
                [scan scanFloat:&rx];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&ry];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:NULL];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&big];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&clock];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&x];
                [scan scanString:@"," intoString:nil];
                [scan scanFloat:&y];
                float cx=path.currentPoint.x+(((y<=0?clock:!clock)?big:!big)?1:-1)*(rx+ry)/2*fabs(x)/sqrtf(powf(x, 2)+powf(y, 2));
                float cy=path.currentPoint.y+y*(cx-path.currentPoint.x)/x;
                [path addArcWithCenter:CGPointMake(cx, cy) radius:(rx+ry)/2 startAngle:atanf((path.currentPoint.y-cy)/(path.currentPoint.x-cx)) endAngle:atanf((y+path.currentPoint.y-cy)/(x+path.currentPoint.x-cx)) clockwise:clock];
            }*/else if ([ch1 isEqualToString:@"Z"]||[ch1 isEqualToString:@"z"])
            {
                [path closePath];
            }
        }else
        {
            break;
        }
    }
    return path;
}

static CATransform3D trans_from_trans_str(NSString *str)
{
    CATransform3D t=CATransform3DIdentity;
    NSScanner *scan=[NSScanner scannerWithString:str];
    while (!scan.isAtEnd)
    {
        NSString *tmp;
        BOOL flag=[scan scanUpToString:@"(" intoString:&tmp];
        if (flag)
        {
            scan.scanLocation+=1;
            if ([tmp isEqualToString:@"rotate"])
            {
                float r;
                [scan scanFloat:&r];
                t=CATransform3DRotate(t, M_PI*r/180, 0, 0, 1);
            }else if ([tmp isEqualToString:@"translate"])
            {
                float x, y=0;
                [scan scanFloat:&x];
                scan.scanLocation+=1;
                [scan scanFloat:&y];
                t=CATransform3DTranslate(t, x, y, 0);
            }else if ([tmp isEqualToString:@"scale"])
            {
                float x, y;
                [scan scanFloat:&x];
                scan.scanLocation+=1;
                BOOL flag=[scan scanFloat:&y];
                if (!flag)
                {
                    y=x;
                }
                t=CATransform3DScale(t, x, y, 1);
            }else if ([tmp isEqualToString:@"skewX"])
            {
                float x;
                [scan scanFloat:&x];
                CATransform3D tt=CATransform3DIdentity;
                tt.m21=tanf(x*M_PI/180);
                t=CATransform3DConcat(tt, t);
            }else if ([tmp isEqualToString:@"skewY"])
            {
                float y;
                [scan scanFloat:&y];
                CATransform3D tt=CATransform3DIdentity;
                tt.m12=tanf(y*M_PI/180);
                t=CATransform3DConcat(tt, t);
            }else if ([tmp isEqualToString:@"matrix"])
            {
                CATransform3D tt=CATransform3DIdentity;
                [scan scanDouble:&tt.m11];
                scan.scanLocation+=1;
                [scan scanDouble:&tt.m12];
                scan.scanLocation+=1;
                [scan scanDouble:&tt.m21];
                scan.scanLocation+=1;
                [scan scanDouble:&tt.m22];
                scan.scanLocation+=1;
                [scan scanDouble:&tt.m41];
                scan.scanLocation+=1;
                [scan scanDouble:&tt.m42];
                t=CATransform3DConcat(tt, t);
            }
            [scan scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:nil];
        }else
        {
            break;
        }
    }
    return t;
}

static void attr_from_raw_couple_str(NSString *key1, NSString *val1, NSString **key2, NSObject **val2)
{
    *key2=nil,*val2=nil;
    //path
    if ([key1 isEqualToString:@"id"]||[key1 isEqualToString:@"tag"]||[key1 isEqualToString:@"name"])
    {
        *key2=@"name",*val2=val1;
    }else if ([key1 isEqualToString:@"transform"])
    {
        *key2=@"transform",*val2=[NSValue valueWithCATransform3D:trans_from_trans_str(val1)];
    }else if ([key1 isEqualToString:@"opacity"])
    {
        *key2=@"opacity",*val2=val1;
    }else if ([key1 isEqualToString:@"fill"])
    {
        *key2=@"fillColor";
        *val2=(__bridge id)color_from_color_str(val1).CGColor;
    }else if ([key1 isEqualToString:@"stroke"])
    {
        *key2=@"strokeColor";
        *val2=(__bridge id)color_from_color_str(val1).CGColor;
    }else if ([key1 isEqualToString:@"fill-rule"])
    {
        if ([val1 isEqualToString:@"evenodd"])
        {
            *key2=@"fillRule",*val2=@"even-odd";
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


static NSDictionary *attrs_from_style_str(NSString *str)
{
    NSScanner *scan=[NSScanner scannerWithString:str];
    NSString *key, *val;
    NSMutableDictionary *dict=[NSMutableDictionary new];
    while (!scan.isAtEnd)
    {
        [scan scanUpToCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:nil];
        BOOL flag=[scan scanUpToString:@":" intoString:&key];
        if (flag)
        {
            scan.scanLocation+=1;
            [scan scanUpToString:@";" intoString:&val];
            dict[key]=val;
        }
    }
    return dict;
}

#pragma mark - shape

static void shape_by_raw_couple_str(CALayer *layer, NSString *key, NSString *val, NSMutableArray *trans)
{
    NSString *key1, *val1;
    attr_from_raw_couple_str(key, val, &key1, &val1);
    if (key1)
    {
        if ([key1 isEqualToString:@"transform"])
        {
            [trans addObject:val1];
        }else
        {
            [layer setValue:val1 forKey:key1];
        }
    }
}

static void shape_by_raw_couple_strs(CALayer *layer, NSDictionary *dict, NSMutableArray *trans)
{
    for (NSString *key in dict)
    {
        if ([key isEqualToString:@"style"])
        {
            NSDictionary *dict1=attrs_from_style_str(dict[@"style"]);
            for (NSString *key1 in dict1)
            {
                shape_by_raw_couple_str(layer, key1, dict1[key1], trans);
            }
        }else
        {
            shape_by_raw_couple_str(layer, key, dict[key], trans);
        }
    }
}

static void shape_by_node(CAShapeLayer *layer, XMLNode *node)
{
    NSMutableArray *trans=[NSMutableArray new];
    shape_by_raw_couple_strs(layer, node.attributes, trans);
    
    while (node.parentNode)
    {
        if ([node.parentNode.name isEqualToString:@"g"])
        {
            shape_by_raw_couple_strs(layer, node.parentNode.attributes, trans);
        }else if ([node.parentNode.name isEqualToString:@"svg"])
        {
            NSString *str=node.parentNode.attributes[@"viewBox"];
            if (str.length>0)
            {
                NSScanner *scan=[NSScanner scannerWithString:str];
                CGRect rect;
                [scan scanDouble:&rect.origin.x];
                scan.scanLocation+=1;
                [scan scanDouble:&rect.origin.y];
                scan.scanLocation+=1;
                [scan scanDouble:&rect.size.width];
                scan.scanLocation+=1;
                [scan scanDouble:&rect.size.height];
                layer.frame=rect;//TODO:frank
            }
        }
        node=node.parentNode;
    }
    CATransform3D t=CATransform3DIdentity;
    for (NSValue *val in trans)
    {
        t=CATransform3DConcat(t, val.CATransform3DValue);
    }
    layer.transform=t;
}

#pragma mark - layer from node

CAShapeLayer *layer_from_path_node(XMLNode *node)
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.anchorPoint=CGPointZero;
    layer.position=CGPointZero;
    layer.path=path_from_d_str(node.attributes[@"d"]).CGPath;
    shape_by_node(layer, node);
    return layer;
}

CAShapeLayer *layer_from_line_node(XMLNode *node)
{
    UIBezierPath *path=[UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake([node.attributes[@"x1"] floatValue], [node.attributes[@"y1"] floatValue])];
    [path addLineToPoint:CGPointMake([node.attributes[@"x2"] floatValue], [node.attributes[@"y2"] floatValue])];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.anchorPoint=CGPointZero;
    layer.position=CGPointZero;
    layer.path=path.CGPath;
    shape_by_node(layer, node);
    return layer;
}

CAShapeLayer *layer_from_rect_node(XMLNode *node)
{
    UIBezierPath *path=[UIBezierPath bezierPathWithRoundedRect:CGRectMake([node.attributes[@"x"] floatValue], [node.attributes[@"y"] floatValue], [node.attributes[@"width"] floatValue], [node.attributes[@"height"] floatValue]) cornerRadius:[node.attributes[@"rx"] floatValue]];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.anchorPoint=CGPointZero;
    layer.position=CGPointZero;
    layer.path=path.CGPath;
    shape_by_node(layer, node);
    return layer;
}

CAShapeLayer *layer_from_circle_node(XMLNode *node)
{
    UIBezierPath *path=[UIBezierPath bezierPathWithArcCenter:CGPointMake([node.attributes[@"cx"] floatValue], [node.attributes[@"cy"] floatValue]) radius:[node.attributes[@"r"] floatValue] startAngle:0 endAngle:M_PI*2 clockwise:YES];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.anchorPoint=CGPointZero;
    layer.position=CGPointZero;
    layer.path=path.CGPath;
    shape_by_node(layer, node);
    return layer;
}

CAShapeLayer *layer_from_ellipse_node(XMLNode *node)
{
    UIBezierPath *path=[UIBezierPath bezierPathWithOvalInRect:CGRectMake([node.attributes[@"cx"] floatValue]-[node.attributes[@"rx"] floatValue], [node.attributes[@"cy"] floatValue]-[node.attributes[@"ry"] floatValue], [node.attributes[@"rx"] floatValue]*2, [node.attributes[@"ry"] floatValue]*2)];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.anchorPoint=CGPointZero;
    layer.position=CGPointZero;
    layer.path=path.CGPath;
    shape_by_node(layer, node);
    return layer;
}

CAShapeLayer *layer_from_polyline_node(XMLNode *node)
{
    NSScanner *scan=[NSScanner scannerWithString:node.attributes[@"points"]];
    CGPoint point;
    [scan scanDouble:&point.x];
    scan.scanLocation+=1;
    [scan scanDouble:&point.y];
    UIBezierPath *path=[UIBezierPath bezierPath];
    [path moveToPoint:point];
    while (!scan.atEnd)
    {
        [scan scanDouble:&point.x];
        scan.scanLocation+=1;
        [scan scanDouble:&point.y];
        [path addLineToPoint:point];
    }
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.anchorPoint=CGPointZero;
    layer.position=CGPointZero;
    layer.path=path.CGPath;
    shape_by_node(layer, node);
    return layer;
}

CAShapeLayer *layer_from_polygon_node(XMLNode *node)
{
    NSScanner *scan=[NSScanner scannerWithString:node.attributes[@"points"]];
    CGPoint point;
    [scan scanDouble:&point.x];
    scan.scanLocation+=1;
    [scan scanDouble:&point.y];
    UIBezierPath *path=[UIBezierPath bezierPath];
    [path moveToPoint:point];
    while (!scan.atEnd)
    {
        [scan scanDouble:&point.x];
        scan.scanLocation+=1;
        [scan scanDouble:&point.y];
        [path addLineToPoint:point];
    }
    [path closePath];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.anchorPoint=CGPointZero;
    layer.position=CGPointZero;
    layer.path=path.CGPath;
    shape_by_node(layer, node);
    return layer;
}

CATextLayer *layer_from_text_node(XMLNode *node)
{
    CATextLayer *layer=[CATextLayer layer];
    layer.anchorPoint=CGPointZero;
    layer.position=CGPointZero;
    layer.contentsScale=[UIScreen mainScreen].scale;
    layer.string=node.value;
    layer.frame=CGRectMake([node.attributes[@"x"] floatValue], [node.attributes[@"y"] floatValue], [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);//TODO:frank
    //shape_by_attrs(layer, node);//TODO:frank
    return layer;
}

CALayer *layer_from_node(XMLNode *node)
{
    CALayer *layer = nil;
    if ([node.name isEqualToString:@"path"])
    {
        layer=layer_from_path_node(node);
    }else if ([node.name isEqualToString:@"line"])
    {
        layer=layer_from_line_node(node);
    }else if ([node.name isEqualToString:@"rect"])
    {
        layer=layer_from_rect_node(node);
    }else if ([node.name isEqualToString:@"circle"])
    {
        layer=layer_from_circle_node(node);
    }else if ([node.name isEqualToString:@"ellipse"])
    {
        layer=layer_from_ellipse_node(node);
    }else if ([node.name isEqualToString:@"polyline"])
    {
        layer=layer_from_polyline_node(node);
    }else if ([node.name isEqualToString:@"polygon"])
    {
        layer=layer_from_polygon_node(node);
    }else if ([node.name isEqualToString:@"text"])
    {
        layer=layer_from_text_node(node);
    }
    return layer;
}

static void add_layers_from_node(XMLNode *node, NSMutableArray *arr)
{
    if ([node.name isEqualToString:@"path"])
    {
        [arr addObject:layer_from_path_node(node)];
    }else if ([node.name isEqualToString:@"line"])
    {
        [arr addObject:layer_from_line_node(node)];
    }else if ([node.name isEqualToString:@"rect"])
    {
        [arr addObject:layer_from_rect_node(node)];
    }else if ([node.name isEqualToString:@"circle"])
    {
        [arr addObject:layer_from_circle_node(node)];
    }else if ([node.name isEqualToString:@"ellipse"])
    {
        [arr addObject:layer_from_ellipse_node(node)];
    }else if ([node.name isEqualToString:@"polyline"])
    {
        [arr addObject:layer_from_polyline_node(node)];
    }else if ([node.name isEqualToString:@"polygon"])
    {
        [arr addObject:layer_from_polygon_node(node)];
    }else if ([node.name isEqualToString:@"text"])
    {
        [arr addObject:layer_from_text_node(node)];
    }else if ([node.name isEqualToString:@"svg"]||[node.name isEqualToString:@"g"])
    {
        for (XMLNode *tmp in node.childNodes)
        {
            add_layers_from_node(tmp, arr);
        }
    }
}

NSArray *layers_from_node(XMLNode *node)
{
    NSMutableArray *arr=[NSMutableArray new];
    add_layers_from_node(node, arr);
    return arr.count>0? arr:nil;
}