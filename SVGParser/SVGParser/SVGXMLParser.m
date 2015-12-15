//
//  SVGXMLParser.m
//  SVGParser
//
//  Created by Laughing on 15/12/14.
//  Copyright © 2015年 WG. All rights reserved.
//

#import "SVGXMLParser.h"

@interface SVGXMLParser()
@end

@implementation SVGXMLParser

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    XMLNode *node = [XMLNode new];
    node.name = elementName;
    node.attributes = attributeDict;
    if (_currentNode)
    {
        if (_currentNode.childNodes==nil)
        {
            _currentNode.childNodes = [NSArray new];
        }
        
        _currentNode.childNodes = [_currentNode.childNodes arrayByAddingObject:node];
        node.parentNode = _currentNode;
    }else
    {
        _rootNode = node;
    }
    
    _currentNode = node;
    [_currentString replaceCharactersInRange:NSMakeRange(0, _currentString.length) withString:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    _currentNode.value = [_currentString copy];
    if (_CDATA)
    {
        _CDATA.parentNode=_currentNode;
        _currentNode.childNodes=@[_CDATA];
        _currentNode.value=nil;
        _CDATA=nil;
    }
    if (_currentNode.parentNode)
    {
        _currentNode = _currentNode.parentNode;
        [_currentString replaceCharactersInRange:NSMakeRange(0, _currentString.length) withString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
    NSString *str=[[NSString alloc] initWithBytes:CDATABlock.bytes length:CDATABlock.length encoding:NSUTF8StringEncoding];
    NSScanner *scan=[NSScanner scannerWithString:str];
    scan.charactersToBeSkipped=[NSCharacterSet whitespaceAndNewlineCharacterSet];
    [scan scanString:@"*/" intoString:nil];
    NSString *val;
    [scan scanUpToString:@"/*" intoString:&val];
    
    _CDATA=[XMLNode new];
    _CDATA.name=@"CDATA";
    _CDATA.value=val;//(NSString*)[val dataUsingEncoding:NSUTF8StringEncoding];
}

@end
