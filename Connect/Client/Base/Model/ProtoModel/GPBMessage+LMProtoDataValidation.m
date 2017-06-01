//
//  GPBMessage+LMProtoDataValidation.m
//  Connect
//
//  Created by MoHuilin on 2017/3/6.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "GPBMessage+LMProtoDataValidation.h"
#import "Protofile.pbobjc.h"
#import "NSObject+Swing.h"
#import "XMLReader.h"
#import "NSObject+MJProperty.h"

#define CASE(str)                       if ([__s__ isEqualToString:(str)])
#define SWITCH(s)                       for (NSString *__s__ = (s); ; )
#define DEFAULT

static NSDictionary *pbRuleDict;

@implementation GPBMessage (LMProtoDataValidation)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self gl_swizzleClassMethod:@selector(parseFromData:error:) withMethod:@selector(parseFromValidationData:error:)];
    });
}

+ (nullable instancetype)parseFromValidationData:(NSData *)data error:(NSError **)errorPtr{
    
    GPBMessage *message = [self parseFromData:data extensionRegistry:nil error:errorPtr];
    if (!pbRuleDict) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"pbrule.xml" ofType:nil];
        NSURL *url = [NSURL fileURLWithPath:path];
        NSData *xmlData = [NSData dataWithContentsOfURL:url];
        NSError *error;
        NSDictionary *pbDict = [XMLReader dictionaryForXMLData:xmlData error:&error];
        pbRuleDict = [pbDict valueForKey:@"PBRule"];
    }
    NSString *modelClassName = NSStringFromClass([message class]);
    NSDictionary *rule = [pbRuleDict valueForKey:modelClassName];
    if (rule) {
        NSDictionary *keyValues = [message mj_keyValues];
        id attrRule = [rule valueForKey:@"attr"];
        if ([attrRule isKindOfClass:[NSDictionary class]]) { //one attr check
            NSString *name = [attrRule valueForKey:@"name"];
            if ([keyValues.allKeys containsObject:name]) {
                NSString *type = [attrRule valueForKey:@"type"];
                NSString *text = [attrRule valueForKey:@"text"];
                BOOL result = [self checkAttrWithTypeString:type checkValue:[keyValues valueForKey:name] reg:text];
                if (!result) {
                    return nil;
                }
            }
        } else if ([attrRule isKindOfClass:[NSArray class]]){ //more attr check
            NSArray *array = [NSArray arrayWithArray:attrRule];
            for (NSDictionary *attrRuleDict in array) {
                NSString *name = [attrRuleDict valueForKey:@"name"];
                if ([keyValues.allKeys containsObject:name]) {
                    NSString *type = [attrRuleDict valueForKey:@"type"];
                    NSString *text = [attrRuleDict valueForKey:@"text"];
                    BOOL result = [self checkAttrWithTypeString:type checkValue:[keyValues valueForKey:name] reg:text];
                    if (!result) {
                        return nil;
                    }
                }
            }
        }
    }
    return message;
    
}


#pragma mark - private method
+ (BOOL)checkAttrWithTypeString:(NSString *)type checkValue:(id)value reg:(NSString *)reg{
    SWITCH (type) {
        CASE (@"string") {
            NSString *checkString = (NSString *)value;
            return checkString && checkString.length;
            break;
        }
        CASE(@"gcmdata") {
            return [self validationGcmdata:value];
            break;
        }
        CASE(@"byte") {
            NSData *data = (NSData *)value;
            return data.length == reg.integerValue;
            break;
        }
        DEFAULT {
            return NO;
            break;
        }
    }
}

+ (BOOL)validationGcmdata:(NSDictionary *)gcdDataDict{
    if (![gcdDataDict valueForKey:@"aad"]) {
        return NO;
    }
    if (![gcdDataDict valueForKey:@"iv"]) {
        return NO;
    }
    if (![gcdDataDict valueForKey:@"tag"]) {
        return NO;
    }
    if (![gcdDataDict valueForKey:@"ciphertext"]) {
        return NO;
    }
    return YES;
}

@end
