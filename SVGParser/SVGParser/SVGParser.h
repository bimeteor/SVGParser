//
//  SVGParser.h
//  SVGParser
//
//  Created by Laughing on 15/11/28.
//  Copyright © 2015年 WG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "XMLParser.h"

extern NSString *fillLinearGradientName;
extern NSString *strokeLinearGradientName;

#ifdef __cplusplus
extern "C" {
#endif
    NSArray *layers_from_node(XMLNode *node);
#ifdef __cplusplus
}
#endif
