//
//  SVGXMLParser.h
//  SVGParser
//
//  Created by Laughing on 15/12/14.
//  Copyright © 2015年 WG. All rights reserved.
//

#import "XMLParser.h"

@interface SVGXMLNode : XMLNode

@property (nonatomic) NSString *CDATA;
- (SVGXMLNode*)rootNode;

@end

@interface SVGXMLParser : XMLParser

@end
