//
//  ViewController.m
//  RichText
//
//  Created by Laughing on 15/11/9.
//  Copyright © 2015年 frank. All rights reserved.
//

#import "ViewController.h"
#import "SVGParser.h"
#import "UIView+NSLayoutExtension.h"
#import "PathDrawingView.h"
#import "XMLParser.h"
#import "UIView+Addition.h"

@interface ViewController ()<UIScrollViewDelegate>
{
    NSMutableDictionary *_dict;
    UIScrollView *_scroll;
}
@end

@implementation ViewController
/*
static void convert(x1, y1, x2, y2, fA, fS, rx, ry, phi)
{
    var cx,cy,theta1,delta_theta;
    
    if( rx == 0.0 || ry == 0.0 ) return -1;  // invalid arguments
    
    var  s_phi = Math.sin( phi );
    var  c_phi = Math.cos( phi );
    var  hd_x = ( x1 - x2 ) / 2.0;   // half diff of x
    var  hd_y = ( y1 - y2 ) / 2.0;   // half diff of y
    var  hs_x = ( x1 + x2 ) / 2.0;   // half sum of x
    var  hs_y = ( y1 + y2 ) / 2.0;   // half sum of y
    
    // F6.5.1
    var  x1_ = c_phi * hd_x + s_phi * hd_y;
    var  y1_ = c_phi * hd_y - s_phi * hd_x;
    
    var  rxry = rx * ry;
    var  rxy1_ = rx * y1_;
    var  ryx1_ = ry * x1_;
    var  sum_of_sq = rxy1_ * rxy1_ + ryx1_ * ryx1_;   // sum of square
    var  coe = Math.sqrt( ( rxry * rxry - sum_of_sq ) / sum_of_sq );
    if( fA == fS ) coe = -coe;
    
    // F6.5.2
    var  cx_ = coe * rxy1_ / ry;
    var  cy_ = -coe * ryx1_ / rx;
    
    // F6.5.3
    cx = c_phi * cx_ - s_phi * cy_ + hs_x;
    cy = s_phi * cx_ + c_phi * cy_ + hs_y;
    
    var  xcr1 = ( x1_ - cx_ ) / rx;
    var  xcr2 = ( x1_ + cx_ ) / rx;
    var  ycr1 = ( y1_ - cy_ ) / ry;
    var  ycr2 = ( y1_ + cy_ ) / ry;
    
    // F6.5.5
    theta1 = radian( 1.0, 0.0, xcr1, ycr1 );
    
    // F6.5.6
    delta_theta = radian( xcr1, ycr1, -xcr2, -ycr2 );
    var  PIx2 = Math.PI * 2.0;
    while( delta_theta > PIx2 ) delta_theta -= PIx2;
    while( delta_theta < 0.0 ) delta_theta += PIx2;
    if( fS == false ) delta_theta -= PIx2;
    
    var outputObj = { // cx, cy, theta1, delta_theta
        cx : cx,
        cy : cy,
        theta1 : theta1,
        delta_theta : delta_theta
    }
    console.dir(outputObj);
    
    return outputObj;
}
*/
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    long index=ceilf(scrollView.contentOffset.x/scrollView.width);
    NSLog(@"%li", index);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSScanner *scan=[NSScanner scannerWithString:@"a b c"];
    NSString *ch1;
    scan.charactersToBeSkipped=[NSCharacterSet characterSetWithCharactersInString:@", "];
    BOOL flag=[scan scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&ch1];
    
    _scroll=[[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_scroll];
    _scroll.pagingEnabled=YES;
    _scroll.delegate=self;
    const long count=8;
    _scroll.contentSize=CGSizeMake(self.view.width*(count+1), self.view.height);
    for (long i=count; i>=0; --i)
    {
        UIView *view=[[UIView alloc] initWithFrame:self.view.bounds];
        [_scroll addSubview:view];
        view.left=self.view.width*(count-i);
        
        NSString *path=[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"basic%li", i] ofType:@"svg"];
        XMLNode *node=[XMLParser nodeWithString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]];
        NSArray *arr=layers_from_node(node);NSLog(@"%li",i);
        for (CALayer *layer in arr)
        {
            [view.layer addSublayer:layer];
        }
    }
    //return;
    CAShapeLayer *l=[CAShapeLayer layer];
    l.backgroundColor=[UIColor clearColor].CGColor;
    //
    l.frame=CGRectMake(0, 0, 300, 300);
    UIBezierPath *path=[UIBezierPath bezierPathWithRect:CGRectMake(20, 30, 100, 300)];
    l.path=path.CGPath;
    l.strokeColor=[UIColor greenColor].CGColor;
    l.fillColor=[UIColor purpleColor].CGColor;
    l.lineWidth=2;
    
    CAGradientLayer *gradient=[CAGradientLayer layer];
    gradient.frame=CGRectMake(0, 0, 300, 300);
    gradient.locations=@[@0.2, @0.8];
    gradient.startPoint=CGPointMake(0, 0);
    gradient.endPoint=CGPointMake(0, 1);
    gradient.colors=@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor];
    [self.view.layer addSublayer:gradient];
    //[self.view.layer addSublayer:l];
    gradient.mask=l;
}

- (void)viewDidLoad1
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
    XMLNode *node=[XMLParser nodeWithString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]];
    _dict=[NSMutableDictionary new];
    for (int i=0; i<7; ++i)
    {/*
        NSString *str=[NSString stringWithFormat:@"XMLID_%i_", i+1];
        XMLNode *node1=[node nodeForAttributeKey:@"id" value:str];
        if ([node1.name isEqualToString:@"path"])
        {
            CAShapeLayer *layer1=layer_from_path_node(node1);
            [layer addSublayer:layer1];
            layer1.frame=CGRectMake(0, 0, 200, 200);
            _dict[str]=layer1;
            layer1.hidden = YES;
        }*/
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