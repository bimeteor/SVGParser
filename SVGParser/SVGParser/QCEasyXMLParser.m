//
//  QCEasyXMLParser.m
//  QCall
//
//  Created by frank on 15/3/19.
//  Copyright (c) 2015年 Tencent. All rights reserved.
//

#import "QCEasyXMLParser.h"

@implementation XMLNode

- (XMLNode*)nodeForName:(NSString *)name
{
    if ([_name isEqualToString:name])
    {
        return self;
    }else
    {
        for (XMLNode *node in _childNodes)
        {
            XMLNode *tmpNode = [node nodeForName:name];
            if (tmpNode)
            {
                return tmpNode;
            }
        }
        return nil;
    }
}

- (XMLNode*)nodeForAttributeKey:(NSString *)key value:(NSString *)value
{
    if ([self.attributes[key] isEqualToString:value])
    {
        return self;
    }else
    {
        for (XMLNode *node in _childNodes)
        {
            XMLNode *tmpNode = [node nodeForAttributeKey:key value:value];
            if (tmpNode)
            {
                return tmpNode;
            }
        }
        return nil;
    }
}

static bool is_node_str_match(XMLNode *node, NSString *str)
{
    if (![str hasSuffix:@"]"])
    {
        return [str isEqualToString:node.name];
    }else
    {
        NSRange range = [str rangeOfString:@"["];
        if (range.location>0)
        {
            if ([[str substringToIndex:range.location] isEqualToString:node.name])
            {
                NSArray *arr = [[str substringWithRange:NSMakeRange(range.location+1, str.length-1-range.location-1)] componentsSeparatedByString:@"="];
                if (arr.count>1)
                {
                    return [node.attributes[arr.firstObject] isEqualToString:arr.lastObject];
                }
            }
        }
        return 0;
    }
}

- (XMLNode*)nodeForKeyPath:(NSString*)keyPath
{
    NSArray *array = [keyPath componentsSeparatedByString:@"."];
    int depth = 0;
    bool match = 1;
    XMLNode *node = self;
    while (1)
    {
        if (match)
        {
            if (is_node_str_match(node, array[depth]))
            {
                if (depth+1>=array.count)
                {
                    return node;
                }else
                {
                    if (node.childNodes.count==0)
                    {
                        match = 0;
                    }else
                    {
                        node = node.childNodes[0];
                        depth += 1;
                    }
                }
            }else
            {
                match = 0;
            }
        }else
        {
            if (node.parentNode==nil)
            {
                return nil;
            }else
            {
                NSArray *arr = node.parentNode.childNodes;
                long index = [arr indexOfObject:node];
                if (index>=arr.count-1)
                {
                    node = node.parentNode;
                    depth -= 1;
                }else
                {
                    node = arr[index+1];
                    match = 1;
                }
            }
        }
    }
    return nil;
}

- (NSString*)description
{
    return [QCEasyXMLParser stringWithNode:self];
}

@end


@interface QCEasyXMLParser()<NSXMLParserDelegate>
{
    NSXMLParser *_parser;
    NSMutableString *_currentString;
    NSCharacterSet *_trimCharacters;
}
@property (nonatomic) XMLNode *currentNode;
@end

@implementation QCEasyXMLParser

+ (XMLNode*)nodeWithData:(NSData*)data
{
    return [[[self alloc] initWithData:data] node];
}

- (instancetype)init
{
    return nil;
}

static NSString *str_from_node(XMLNode *node, int depth)
{
    NSMutableString *string = [NSMutableString new];
    if (depth>0)
    {
        [string appendFormat:@"\n"];
        XMLNode *tempNode = node;
        for (int i=0; i<depth; ++i)
        {
            [string appendFormat:@"   "];
            tempNode=tempNode.parentNode;
        }
    }
    
    [string appendFormat:@"<%@", node.name];
    for (NSString *key in node.attributes.allKeys)
    {
        [string appendFormat:@" %@=\"%@\"", key, node.attributes[key]];
    }
    [string appendString:@">"];
    
    if (node.childNodes.count==0)
    {
        [string appendFormat:@"%@</%@>", node.value, node.name];
    }else
    {
        for (XMLNode *sub in node.childNodes)
        {
            [string appendString:str_from_node(sub, depth+1)];
        }
        [string appendFormat:@"\n"];
        for (int i=0; i<depth; ++i)
        {
            [string appendFormat:@"   "];
        }
        [string appendFormat:@"</%@>", node.name];
    }
    return string;
}

+ (NSString*)stringWithNode:(XMLNode*)node
{
    return str_from_node(node, 0);
}

- (void)dealloc
{
    _parser.delegate = nil;
}

- (instancetype)initWithData:(NSData*)data
{
    self = [super init];
    if (self)
    {
        _parser = [[NSXMLParser alloc] initWithData:data];
        _parser.delegate = self;
        _currentString = [NSMutableString new];
        _trimCharacters = [NSMutableCharacterSet controlCharacterSet];
        [(NSMutableCharacterSet*)_trimCharacters formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
    }
    return self;
}

- (XMLNode*)node
{
    BOOL flag = [_parser parse];
    if (flag)
    {
        return _currentNode;
    }else
    {
        return nil;
    }
}

#pragma mark - NSXMLParserDelegate

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    _currentNode = nil;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    _currentNode = nil;
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    _currentNode = nil;
}

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
    }
    
    _currentNode = node;
    [_currentString replaceCharactersInRange:NSMakeRange(0, _currentString.length) withString:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    _currentNode.value = [_currentString copy];
    if (_currentNode.parentNode)
    {
        _currentNode = _currentNode.parentNode;
        [_currentString replaceCharactersInRange:NSMakeRange(0, _currentString.length) withString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [_currentString appendString:[string stringByTrimmingCharactersInSet:_trimCharacters]];
}
@end