//
//  RadialView.h
//  SVGParser
//
//  Created by Laughing on 15/12/18.
//  Copyright © 2015年 WG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RadialView : UIView

@property (nonatomic) CGPoint startPoint;
@property (nonatomic) CGPoint endPoint;
@property (nonatomic) NSArray *colors;
@property (nonatomic) NSArray *locations;
@property (nonatomic) float radius;

@end
