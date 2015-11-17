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

@interface ViewController ()
{
    NSMutableDictionary *_dict;
}
@end

@implementation ViewController

CAShapeLayer *layer_from_node_atts(NSDictionary *dict)
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    for (NSString *key in dict)
    {
        if ([key isEqualToString:@"path"])
        {
            layer.path=[dict[key] CGPath];
        }else
        {
            [layer setValue:dict[key] forKey:key];
        }
    }
    return layer;
}

NSDictionary *atts_from_dict(NSDictionary *dict)
{
    NSMutableDictionary *dic=[NSMutableDictionary new];
    NSString *str;
    for (NSString *key in dict)
    {
        str = dict[key];
        if ([key isEqualToString:@"opacity"])
        {
            dic[@"opacity"]=dict[key];
        }else if ([key isEqualToString:@"fill"])
        {
            if ([str isEqualToString:@"none"])
            {
                dic[@"fillColor"]=(id)[UIColor clearColor].CGColor;
            }else
            {
                NSScanner *scan=[NSScanner scannerWithString:[str substringFromIndex:1]];
                unsigned val;
                [scan scanHexInt:&val];
                dic[@"fillColor"]=(id)color_rgb(val).CGColor;
            }
        }else if ([key isEqualToString:@"fill-rule"])
        {
            if ([str isEqualToString:@"evenodd"])
            {
                dic[@"fillRule"]=@"even-odd";
            }
        }else if ([key isEqualToString:@"stroke"])
        {
            if ([str isEqualToString:@"none"])
            {
                dic[@"strokeColor"]=(id)[UIColor clearColor].CGColor;
            }else
            {
                NSScanner *scan=[NSScanner scannerWithString:[str substringFromIndex:1]];
                unsigned val;
                [scan scanHexInt:&val];
                dic[@"strokeColor"]=(id)color_rgb(val).CGColor;
            }
        }else if ([key isEqualToString:@"stroke-width"])
        {
            dic[@"lineWidth"]=dict[key];
        }else if ([key isEqualToString:@"stroke-linecap"])
        {
            dic[@"lineCap"]=dict[key];
        }else if ([key isEqualToString:@"stroke-linejoin"])
        {
            dic[@"lineJoin"]=dict[key];
        }else if ([key isEqualToString:@"stroke-miterlimit"])
        {
            dic[@"miterLimit"]=dict[key];
        }else if ([key isEqualToString:@"d"])
        {
            dic[@"path"]=path_from_str(dict[key]);
        }else
        {
            //NSLog(@"%@ = %@", key, dict[key]);
        }
    }
    return dic;
}

UIBezierPath *path_from_str(NSString *str)
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
        CAShapeLayer *layer1=layer_from_node_atts(atts_from_dict(node1.attributes));
        [layer addSublayer:layer1];
        layer1.frame=CGRectMake(0, 0, 200, 200);
        _dict[str]=layer1;
        layer1.hidden = YES;
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