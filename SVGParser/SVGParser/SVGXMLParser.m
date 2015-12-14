//
//  SVGXMLParser.m
//  SVGParser
//
//  Created by Laughing on 15/12/14.
//  Copyright © 2015年 WG. All rights reserved.
//

#import "SVGXMLParser.h"

@implementation SVGXMLNode

- (XMLNode*)rootNode
{
    XMLNode *node=self;
    while (node.parentNode)
    {
        node=node.parentNode;
    }
    return node;
}

@end

@interface SVGXMLParser()
{
    NSXMLParser *_parser;
    NSMutableString *_currentString;
    NSCharacterSet *_trimCharacters;
    SVGXMLNode *_rootNode;
    SVGXMLNode *_currentNode;
}
@end

@implementation SVGXMLParser

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
    _rootNode.CDATA=[[NSString alloc] initWithBytes:CDATABlock.bytes length:CDATABlock.length encoding:NSUTF8StringEncoding];
}

@end
