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

static NSString *graphs_names[]={@"path", @"line", @"rect", @"circle", @"ellipse", @"polyline", @"polygon"};
static NSCharacterSet *scanSkipCharacters;
NSString *fillLinearGradientName=@"fillLinearGradientName";
NSString *strokeLinearGradientName=@"strokeLinearGradientName";

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
    }else if ([str isEqualToString:@"white"])
    {
        return [UIColor whiteColor];
    }
    return nil;
}

static UIColor *color_from_color_str(NSString *str)
{
    UIColor *color=nil;
    if ([str hasPrefix:@"rgb"])
    {
        NSScanner *scan=[NSScanner scannerWithString:str];
        scan.charactersToBeSkipped=scanSkipCharacters;
        scan.scanLocation=4;
        int r,g,b;
        [scan scanInt:&r];
        [scan scanInt:&g];
        [scan scanInt:&b];
        color=[UIColor colorWithRed:1.0*r/255 green:1.0*g/255 blue:1.0*b/255 alpha:1];
    }else
    {
        color=color_from_name(str);
        if (!color)
        {
            if ([str hasPrefix:@"#"])
            {
                NSScanner *scan=[NSScanner scannerWithString:str];
                scan.scanLocation=1;
                unsigned num;
                [scan scanHexInt:&num];
                if (num<=0xfff&&num>1)
                {
                    num=((0xf00&num)<<12)+((0xf00&num)<<8)+((0xf0&num)<<8)+((0xf0&num)<<4)+((0xf&num)<<4)+(0xf&num);
                }
                color=color_rgb(num);
            }else
            {
                color=[UIColor blueColor];
            }
        }
    }
    
    return color;
}

static void add_ellipse_arc_path(CGMutablePathRef path, float rx, float ry, float angle, bool big, bool clock, float x, float y)
{
    if (rx == 0 || ry == 0)
    {
        CGPathAddLineToPoint(path, NULL, x, y);
        return;
    }
    CGFloat cosPhi = cos(angle);
    CGFloat sinPhi = sin(angle);
    CGPoint curr_point=CGPathGetCurrentPoint(path);
    CGFloat	x1p = cosPhi * (curr_point.x-x)/2 + sinPhi * (curr_point.y-y)/2;
    CGFloat	y1p = -sinPhi * (curr_point.x-x)/2 + cosPhi * (curr_point.y-y)/2;
    
    CGFloat lhs;
    {
        CGFloat rx_2 = rx * rx;
        CGFloat ry_2 = ry * ry;
        CGFloat xp_2 = x1p * x1p;
        CGFloat yp_2 = y1p * y1p;
        CGFloat delta = xp_2/rx_2 + yp_2/ry_2;
        if (delta > 1.0)
        {
            rx *= sqrt(delta);
            ry *= sqrt(delta);
            rx_2 = rx * rx;
            ry_2 = ry * ry;
        }
        CGFloat sign = (big == clock) ? -1 : 1;
        CGFloat numerator = rx_2 * ry_2 - rx_2 * yp_2 - ry_2 * xp_2;
        CGFloat denom = rx_2 * yp_2 + ry_2 * xp_2;
        numerator = MAX(0, numerator);
        lhs = sign * sqrt(numerator/denom);
    }
    
    CGFloat cxp = lhs * (rx*y1p)/ry;
    CGFloat cyp = lhs * -((ry * x1p)/rx);
    CGFloat cx = cosPhi * cxp + -sinPhi * cyp + (curr_point.x+x)/2;
    CGFloat cy = cxp * sinPhi + cyp * cosPhi + (curr_point.y+y)/2;
    
    // transform our ellipse into the unit circle
    CGAffineTransform t = CGAffineTransformMakeScale(1.0/rx, 1.0/ry);
    t = CGAffineTransformRotate(t, -angle);
    t = CGAffineTransformTranslate(t, -cx, -cy);
    
    CGPoint arcPt1 = CGPointApplyAffineTransform(CGPointMake(curr_point.x, curr_point.y), t);
    CGPoint arcPt2 = CGPointApplyAffineTransform(CGPointMake(x, y), t);
    
    CGFloat startAngle = atan2(arcPt1.y, arcPt1.x);
    CGFloat endAngle = atan2(arcPt2.y, arcPt2.x);
    CGFloat angleDelta = endAngle - startAngle;;
    
    if (clock)
    {
        if (angleDelta < 0)
        {
            angleDelta += 2. * M_PI;
        }
    }
    else
    {
        if (angleDelta > 0)
        {
            angleDelta = angleDelta - 2 * M_PI;
        }
    }
    // construct the inverse transform
    CGAffineTransform inv = CGAffineTransformMakeTranslation(cx, cy);
    inv = CGAffineTransformRotate(inv, angle);
    inv = CGAffineTransformScale(inv, rx, ry);
    // add a inversely transformed circular arc to the current path
    CGPathAddRelativeArc(path, &inv, 0, 0, 1, startAngle, angleDelta);
}

static UIBezierPath *path_from_d_str(NSString *str)
{
    NSScanner *scan=[NSScanner scannerWithString:str];
    scan.charactersToBeSkipped=scanSkipCharacters;
    CGMutablePathRef path=CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, 0);
    float last_anchor_x=0, last_anchor_y=0;
    CGPoint curr_point;
    NSString *last_cmd, *cmd;
    BOOL flag=[scan scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&cmd];
    while (!scan.atEnd || flag)
    {
        if (!flag)
        {
            if ([last_cmd isEqualToString:@"M"])
            {
                cmd=@"L";
            }else if ([last_cmd isEqualToString:@"m"])
            {
                cmd=@"l";
            }else
            {
                cmd=last_cmd;
            }
        }
        curr_point=CGPathGetCurrentPoint(path);
        if ([cmd isEqualToString:@"M"])
        {
            float x, y;
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            CGPathMoveToPoint(path, NULL, x, y);
        }else if ([cmd isEqualToString:@"m"])
        {
            float x, y;
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            CGPathMoveToPoint(path, NULL, x+curr_point.x, y+curr_point.y);
        }else if ([cmd isEqualToString:@"L"])
        {
            float x, y;
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            CGPathAddLineToPoint(path, NULL, x, y);
        }else if ([cmd isEqualToString:@"l"])
        {
            float x, y;
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            CGPathAddLineToPoint(path, NULL, x+curr_point.x, y+curr_point.y);
        }else if ([cmd isEqualToString:@"H"])
        {
            float x;
            [scan scanFloat:&x];
            CGPathAddLineToPoint(path, NULL, x, curr_point.y);
        }else if ([cmd isEqualToString:@"h"])
        {
            float x;
            [scan scanFloat:&x];
            CGPathAddLineToPoint(path, NULL, x+curr_point.x, curr_point.y);
        }else if ([cmd isEqualToString:@"V"])
        {
            float y;
            [scan scanFloat:&y];
            CGPathAddLineToPoint(path, NULL, curr_point.x, y);
        }else if ([cmd isEqualToString:@"v"])
        {
            float y;
            [scan scanFloat:&y];
            CGPathAddLineToPoint(path, NULL, curr_point.x, y+curr_point.y);
        }else if ([cmd isEqualToString:@"C"])
        {
            float x1, y1, x2, y2, x, y;
            [scan scanFloat:&x1];
            [scan scanFloat:&y1];
            [scan scanFloat:&x2];
            [scan scanFloat:&y2];
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            last_anchor_x=x2, last_anchor_y=y2;
            CGPathAddCurveToPoint(path, NULL, x1, y1, x2, y2, x, y);
        }else if ([cmd isEqualToString:@"c"])
        {
            float x1, y1, x2, y2, x, y;
            [scan scanFloat:&x1];
            [scan scanFloat:&y1];
            [scan scanFloat:&x2];
            [scan scanFloat:&y2];
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            last_anchor_x=x2+curr_point.x, last_anchor_y=y2+curr_point.y;
            CGPathAddCurveToPoint(path, NULL, x1+curr_point.x, y1+curr_point.y, x2+curr_point.x, y2+curr_point.y, x+curr_point.x, y+curr_point.y);
        }else if ([cmd isEqualToString:@"S"])
        {
            float x2, y2, x, y;
            [scan scanFloat:&x2];
            [scan scanFloat:&y2];
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            float tmp_x=last_anchor_x, tmp_y=last_anchor_y;
            last_anchor_x=x2, last_anchor_y=y2;
            CGPathAddCurveToPoint(path, NULL, 2*curr_point.x-tmp_x, 2*curr_point.y-tmp_y, x2, y2, x, y);
        }else if ([cmd isEqualToString:@"s"])
        {
            float x2, y2, x, y;
            [scan scanFloat:&x2];
            [scan scanFloat:&y2];
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            float tmp_x=last_anchor_x, tmp_y=last_anchor_y;
            last_anchor_x=x2+curr_point.x, last_anchor_y=y2+curr_point.y;
            CGPathAddCurveToPoint(path, NULL, 2*curr_point.x-tmp_x, 2*curr_point.y-tmp_y, x2+curr_point.x, y2+curr_point.y, x+curr_point.x, y+curr_point.y);
        }else if ([cmd isEqualToString:@"Q"])
        {
            float x1, y1, x, y;
            [scan scanFloat:&x1];
            [scan scanFloat:&y1];
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            last_anchor_x=x1, last_anchor_y=y1;
            CGPathAddQuadCurveToPoint(path, NULL, x1, y1, x, y);
        }else if ([cmd isEqualToString:@"q"])
        {
            float x1, y1, x, y;
            [scan scanFloat:&x1];
            [scan scanFloat:&y1];
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            last_anchor_x=x1+curr_point.x, last_anchor_y=y1+curr_point.y;
            CGPathAddQuadCurveToPoint(path, NULL, x1+curr_point.x, y1+curr_point.y, x+curr_point.x, y+curr_point.y);
        }else if ([cmd isEqualToString:@"T"])
        {
            float x, y;
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            float tmp_x=last_anchor_x, tmp_y=last_anchor_y;
            last_anchor_x=x, last_anchor_y=y;
            CGPathAddQuadCurveToPoint(path, NULL, 2*curr_point.x-tmp_x, 2*curr_point.y-tmp_y, x, y);
        }else if ([cmd isEqualToString:@"t"])
        {
            float x, y;
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            float tmp_x=last_anchor_x, tmp_y=last_anchor_y;
            last_anchor_x=x+curr_point.x, last_anchor_y=y+curr_point.y;
            CGPathAddQuadCurveToPoint(path, NULL, x+curr_point.x, y+curr_point.y, 2*curr_point.x-tmp_x, 2*curr_point.y-tmp_y);
        }else if ([cmd isEqualToString:@"A"])
        {
            float rx, ry, angle, x, y;
            int big, clock;
            [scan scanFloat:&rx];
            [scan scanFloat:&ry];
            [scan scanFloat:&angle];
            [scan scanInt:&big];
            [scan scanInt:&clock];
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            add_ellipse_arc_path(path, rx, ry, 1.0*angle*M_PI/180, big, clock, x, y);
        }else if ([cmd isEqualToString:@"a"])
        {
            float rx, ry, angle, x, y;
            int big, clock;
            [scan scanFloat:&rx];
            [scan scanFloat:&ry];
            [scan scanFloat:&angle];
            [scan scanInt:&big];
            [scan scanInt:&clock];
            [scan scanFloat:&x];
            [scan scanFloat:&y];
            add_ellipse_arc_path(path, rx, ry, 1.0*angle*M_PI/180, big, clock, x+curr_point.x, y+curr_point.y);
        }else if ([cmd isEqualToString:@"Z"]||[cmd isEqualToString:@"z"])
        {
            CGPathCloseSubpath(path);
        }
        last_cmd=cmd;
        flag=[scan scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&cmd];
    }
    UIBezierPath *path1=[UIBezierPath bezierPathWithCGPath:path];
    CGPathRelease(path);
    return path1;
}

static CATransform3D trans_from_trans_str(NSString *str)
{
    str=[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    CATransform3D t=CATransform3DIdentity;
    NSScanner *scan=[NSScanner scannerWithString:str];
    scan.charactersToBeSkipped=scanSkipCharacters;
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
                [scan scanFloat:&y];
                t=CATransform3DTranslate(t, x, y, 0);
            }else if ([tmp isEqualToString:@"scale"])
            {
                float x, y;
                [scan scanFloat:&x];
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
                [scan scanDouble:&tt.m12];
                [scan scanDouble:&tt.m21];
                [scan scanDouble:&tt.m22];
                [scan scanDouble:&tt.m41];
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
    }else if ([key1 isEqualToString:@"fill"]||[key1 isEqualToString:@"stroke"])
    {
        if ([val1 hasPrefix:@"url"])
        {
            NSScanner *scan=[NSScanner scannerWithString:val1];
            [scan scanUpToString:@"#" intoString:nil];
            scan.scanLocation+=1;
            [scan scanUpToString:@")" intoString:(NSString**)val2];
            *key2=[key1 stringByAppendingString:@"LinearGradientName"];
        }else
        {
            *key2=[key1 stringByAppendingString:@"Color"];
            *val2=(__bridge id)color_from_color_str(val1).CGColor;
        }
    }else if ([key1 isEqualToString:@"stroke-dasharray"])
    {
        if ([val1 isEqualToString:@"none"])
        {
            *val2=@[@(HUGE_VALF)];
        }else
        {
            NSMutableArray *arr=[NSMutableArray new];
            NSScanner *scan=[NSScanner scannerWithString:val1];
            scan.charactersToBeSkipped=scanSkipCharacters;
            int val;
            BOOL flag;
            while (!scan.isAtEnd)
            {
                flag=[scan scanInt:&val];
                if (flag)
                {
                    [arr addObject:@(val)];
                }
            }
            *val2=arr;
        }
        *key2=@"lineDashPattern";
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
                scan.charactersToBeSkipped=scanSkipCharacters;
                CGRect rect;
                [scan scanDouble:&rect.origin.x];
                [scan scanDouble:&rect.origin.y];
                [scan scanDouble:&rect.size.width];
                [scan scanDouble:&rect.size.height];
                //layer.frame=rect;//TODO:frank
            }
        }
        node=node.parentNode;
    }
    if ([layer isKindOfClass:[CAShapeLayer class]])
    {
        UIBezierPath *path=[UIBezierPath bezierPathWithCGPath:layer.path];
        CGRect rect=path.bounds;
        //line 出现0的情况
        if (rect.size.width<0.5)
        {
            rect.size.width=0.5;
        }
        if (rect.size.height<0.5)
        {
            rect.size.height=0.5;
        }
        layer.frame=rect;
        [path applyTransform:CGAffineTransformMakeTranslation(-rect.origin.x, -rect.origin.y)];
        layer.path=path.CGPath;
        layer.anchorPoint=CGPointMake(-layer.frame.origin.x/layer.frame.size.width, -layer.frame.origin.y/layer.frame.size.height);
        layer.position=CGPointZero;
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
    scan.charactersToBeSkipped=scanSkipCharacters;
    CGPoint point;
    [scan scanDouble:&point.x];
    [scan scanDouble:&point.y];
    UIBezierPath *path=[UIBezierPath bezierPath];
    [path moveToPoint:point];
    while (!scan.atEnd)
    {
        [scan scanDouble:&point.x];
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
    scan.charactersToBeSkipped=scanSkipCharacters;
    CGPoint point;
    [scan scanDouble:&point.x];
    [scan scanDouble:&point.y];
    UIBezierPath *path=[UIBezierPath bezierPath];
    [path moveToPoint:point];
    while (!scan.atEnd)
    {
        [scan scanDouble:&point.x];
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

static CAGradientLayer *layer_from_linear_gradient_node(XMLNode*node)
{
    CAGradientLayer *layer=[CAGradientLayer layer];
    layer.anchorPoint=CGPointZero;
    layer.position=CGPointZero;
    layer.name=node.attributes[@"id"];
    layer.startPoint=CGPointMake([node.attributes[@"x1"] floatValue]/100, [node.attributes[@"y1"] floatValue]/100);
    layer.endPoint=node.attributes[@"x2"]? CGPointMake([node.attributes[@"x2"] floatValue]/100, [node.attributes[@"y2"] floatValue]/100): CGPointMake(1, 0);
    NSMutableArray *colors=[NSMutableArray new];
    NSMutableArray *locs=[NSMutableArray new];
    for (XMLNode *chd in node.childNodes)
    {
        NSString *offset=chd.attributes[@"offset"];
        if (offset)
        {
            [locs addObject:@(offset.floatValue/100)];
        }
        NSString *color=chd.attributes[@"stop-color"];
        if (color)
        {
            UIColor *color=color_from_color_str(chd.attributes[@"stop-color"]);
            if (color)
            {
                [colors addObject:(__bridge id)color.CGColor];
            }
        }else
        {
            NSString *style=chd.attributes[@"style"];//TODO:frank
            if (style)
            {
                NSDictionary *dict=attrs_from_style_str(style);
                if (dict[@"stop-color"])
                {
                    UIColor *color=color_from_color_str(dict[@"stop-color"]);
                    if (color)
                    {
                        [colors addObject:(__bridge id)color.CGColor];
                    }
                }
            }
        }
    }
    if (colors.count>0)
    {
        layer.colors=colors;
    }
    if (locs.count>0)
    {
        layer.locations=locs;
    }
    return layer;
}

static CAGradientLayer *copied_linear_gradient_layer(CAGradientLayer* layer)
{
    CAGradientLayer *l=[CAGradientLayer layer];
    l.name=layer.name;
    l.anchorPoint=layer.anchorPoint,l.position=layer.position;
    l.startPoint=layer.startPoint,l.endPoint=layer.endPoint;
    l.colors=layer.colors,l.locations=layer.locations;
    return l;
}

CATextLayer *layer_from_text_node(XMLNode *node)
{
    CATextLayer *layer=[CATextLayer layer];
    layer.contentsScale=[UIScreen mainScreen].scale;
    layer.string=node.value;
    CGRect rect = [node.value boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, HUGE_VALF) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:nil context:nil];
    layer.frame=CGRectMake([node.attributes[@"x"] floatValue], [node.attributes[@"y"] floatValue], rect.size.width, rect.size.height);//TODO:frank
    layer.anchorPoint=CGPointMake(-layer.frame.origin.x/layer.frame.size.width, -layer.frame.origin.y/layer.frame.size.height);
    layer.position=CGPointZero;
    shape_by_node((CAShapeLayer*)layer, node);
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
        //[arr addObject:layer_from_text_node(node)];
    }else if ([node.name isEqualToString:@"linearGradient"])
    {
        [arr addObject:layer_from_linear_gradient_node(node)];
    }else if ([node.name isEqualToString:@"svg"]||[node.name isEqualToString:@"g"]||[node.name isEqualToString:@"defs"])
    {
        for (XMLNode *tmp in node.childNodes)
        {
            add_layers_from_node(tmp, arr);
        }
    }
}

NSArray *layers_from_node(XMLNode *node)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scanSkipCharacters=[NSCharacterSet characterSetWithCharactersInString:@", "];
    });
    NSMutableArray *arr=[NSMutableArray new];
    add_layers_from_node(node, arr);
    NSIndexSet *idxs=[arr indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isKindOfClass:[CAGradientLayer class]];
    }];
    NSArray *grads=[arr objectsAtIndexes:idxs];
    [arr removeObjectsAtIndexes:idxs];
    [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj valueForKey:fillLinearGradientName])
        {
            [grads enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx1, BOOL *stop1) {
                if ([[obj1 name] isEqualToString:[obj valueForKey:fillLinearGradientName]])
                {
                    CAGradientLayer *grad=copied_linear_gradient_layer(obj1);
                    CAShapeLayer *shape=(CAShapeLayer*)obj;
                    shape.strokeColor=[UIColor clearColor].CGColor;
                    UIBezierPath *path=[UIBezierPath bezierPathWithCGPath:shape.path];
                    grad.frame=path.bounds;
                    grad.transform=shape.transform;
                    shape.transform=CATransform3DIdentity;
                    grad.mask=shape;
                    [arr replaceObjectAtIndex:idx withObject:grad];
                }
            }];
        }else if ([obj valueForKey:strokeLinearGradientName])
        {
            [grads enumerateObjectsUsingBlock:^(id obj1, NSUInteger idx1, BOOL *stop1) {
                if ([[obj1 name] isEqualToString:[obj valueForKey:strokeLinearGradientName]])
                {
                    CAGradientLayer *grad=copied_linear_gradient_layer(obj1);
                    CAShapeLayer *shape=(CAShapeLayer*)obj;
                    shape.fillColor=[UIColor clearColor].CGColor;
                    UIBezierPath *path=[UIBezierPath bezierPathWithCGPath:shape.path];
                    grad.frame=path.bounds;
                    grad.transform=shape.transform;
                    shape.transform=CATransform3DIdentity;
                    grad.mask=shape;
                    [arr replaceObjectAtIndex:idx withObject:grad];
                }
            }];
        }
    }];
    return arr.count>0? arr:nil;
}