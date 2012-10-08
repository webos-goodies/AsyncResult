//
//  AsyncResultInjector.h
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/10/04.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AsyncResultInjector : NSObject

+ (id)getValueForKey:(NSString*)key from:(id)object;
+ (void)setValue:(id)value forKey:(NSString*)key to:(id)object;

@end
