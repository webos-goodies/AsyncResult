//
//  AsyncResultInjector.m
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/10/04.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import "AsyncResultInjector.h"
#import <objc/message.h>

static char ASSOCIATED_KEY;

@implementation AsyncResultInjector

+ (id)getValueForKey:(NSString*)key from:(id)object
{
    NSMutableDictionary* values = [self dictionaryFromObject:object];
    return values ? [values objectForKey:key] : nil;
}

+ (void)setValue:(id)value forKey:(NSString*)key to:(id)object
{
    NSMutableDictionary* values = [self dictionaryFromObject:object];
    if(!values) {
        values = [[NSMutableDictionary alloc] initWithCapacity:4];
        objc_setAssociatedObject(object, &ASSOCIATED_KEY, values, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [values setObject:value forKey:key];
}

+ (NSMutableDictionary*)dictionaryFromObject:(id)object
{
    return (NSMutableDictionary*)objc_getAssociatedObject(object, &ASSOCIATED_KEY);
}

@end
