// Copyright 2012 Chihiro Ito. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS-IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
