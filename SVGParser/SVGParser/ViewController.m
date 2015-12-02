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

// svg : [A | a] (rx ry x-axis-rotation large-arc-flag sweep-flag x y)+

/* x1 y1 x2 y2 fA fS rx ry φ */
static float radian(float ux, float uy, float vx, float vy)
{
    float  dot = ux * vx + uy * vy;
    float  mod = sqrtf((ux * ux + uy * uy ) * ( vx * vx + vy * vy ) );
    float  rad = acosf( dot / mod );
    if( ux * vy - uy * vx < 0.0 ) rad = -rad;
    return  rad;
}

//sample :  convert(200,200,300,200,1,1,50,50,0,{})
static void convert(float x1, float y1, float x2, float y2, float fA, float fS, float rx, float ry, float phi, float *cx, float *cy, float *startAngle, float *angle)
{
    float cx1,cy1,theta1,delta_theta;
    
    if( rx == 0.0 || ry == 0.0 ) return;  // invalid arguments
    
    float  s_phi = sinf( phi );
    float  c_phi = cosf( phi );
    float  hd_x = ( x1 - x2 ) / 2.0;   // half diff of x
    float  hd_y = ( y1 - y2 ) / 2.0;   // half diff of y
    float  hs_x = ( x1 + x2 ) / 2.0;   // half sum of x
    float  hs_y = ( y1 + y2 ) / 2.0;   // half sum of y
    
    float  x1_ = c_phi * hd_x + s_phi * hd_y;
    float  y1_ = c_phi * hd_y - s_phi * hd_x;
    
    float  rxry = rx * ry;
    float  rxy1_ = rx * y1_;
    float  ryx1_ = ry * x1_;
    float  sum_of_sq = rxy1_ * rxy1_ + ryx1_ * ryx1_;   // sum of square
    float  coe = sqrtf( ( rxry * rxry - sum_of_sq ) / sum_of_sq );
    if( fA == fS ) coe = -coe;
    
    float  cx_ = coe * rxy1_ / ry;
    float  cy_ = -coe * ryx1_ / rx;
    
    cx1 = c_phi * cx_ - s_phi * cy_ + hs_x;
    cy1 = s_phi * cx_ + c_phi * cy_ + hs_y;
    
    float  xcr1 = ( x1_ - cx_ ) / rx;
    float  xcr2 = ( x1_ + cx_ ) / rx;
    float  ycr1 = ( y1_ - cy_ ) / ry;
    float  ycr2 = ( y1_ + cy_ ) / ry;
    
    theta1 = radian( 1.0, 0.0, xcr1, ycr1 );
    
    delta_theta = radian( xcr1, ycr1, -xcr2, -ycr2 );
    float  PIx2 = M_PI * 2.0;
    while( delta_theta > PIx2 ) delta_theta -= PIx2;
    while( delta_theta < 0.0 ) delta_theta += PIx2;
    if( fS == false ) delta_theta -= PIx2;
    *cx=cx1, *cy=cy1, *startAngle=theta1, *angle=delta_theta;
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    long index=ceilf(scrollView.contentOffset.x/scrollView.width);
    NSLog(@"%li", index);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    NSScanner *scan=[NSScanner scannerWithString:@"A30,30 0 0,1 30,30"];
    scan.charactersToBeSkipped=[NSCharacterSet characterSetWithCharactersInString:@", "];
    float rx, ry, angle, big, clock, x, y;
    scan.scanLocation=1;
    [scan scanFloat:&rx];
    [scan scanFloat:&ry];
    [scan scanFloat:&angle];
    [scan scanFloat:&big];
    [scan scanFloat:&clock];
    [scan scanFloat:&x];
    [scan scanFloat:&y];
    float cx, cy, startAngle, deltaAngle;
    convert(0, 0, x, y, big, clock, rx, ry, angle, &cx, &cy, &startAngle, &deltaAngle);
    
    UIBezierPath *path1=[UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointMake(0, 0)];
    if (rx==ry)
    {
        [path1 addArcWithCenter:CGPointMake(cx, cy) radius:rx startAngle:startAngle endAngle:startAngle+deltaAngle clockwise:clock];
    }
    
    //return;
    CAShapeLayer *l=[CAShapeLayer layer];
    l.backgroundColor=[UIColor clearColor].CGColor;
    //
    l.frame=CGRectMake(0, 0, 300, 300);
    //UIBezierPath *path=[UIBezierPath bezierPathWithRect:CGRectMake(20, 30, 100, 300)];
    l.path=path1.CGPath;
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