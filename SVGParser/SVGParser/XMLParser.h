//
//  XMLParser.h
//  QCall
//
//  Created by frank on 15/3/19.
//  Copyright (c) 2015年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLNode : NSObject
@property (nonatomic) NSString *name;
@property (nonatomic) NSDictionary *attributes;
@property (nonatomic) NSString *value;
@property (nonatomic) NSArray *childNodes;
@property (weak, nonatomic) XMLNode *parentNode;
- (XMLNode*)nodeForName:(NSString*)name; //深度优先
- (XMLNode*)nodeForAttributeKey:(NSString*)key value:(NSString*)value; //深度优先
- (XMLNode*)nodeForKeyPath:(NSString*)keyPath;
@end

@interface XMLParser : NSObject
+ (XMLNode*)nodeWithString:(NSString*)string;
+ (NSString*)stringWithNode:(XMLNode*)node;
@end
