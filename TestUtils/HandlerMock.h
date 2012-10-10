//
//  HandlerMock.h
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/09/30.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KiwiConfiguration.h"
#import "KWMatcher.h"
#import "AsyncResult.h"

@interface HandlerMock : NSObject

@property (nonatomic, readonly) void (^block)(id<AsyncResult> result);
@property (nonatomic, readonly) void (^blockWithValue)(id value, id<AsyncResult> result);
@property (nonatomic, readonly) id<AsyncResult> (^blockForChain)(id<AsyncResult> result);
@property (nonatomic, readonly) id (^blockForTransform)(id value, NSDictionary* metadata);
@property (nonatomic, readonly) NSInteger callCount;
@property (nonatomic, readonly) NSArray* calls;
@property (nonatomic, readonly) HandlerMock* lastCall;
@property (nonatomic, readonly) id value;
@property (nonatomic, readonly) NSDictionary* metadata;
@property (nonatomic, readonly) id<AsyncResult> result;
@property (nonatomic, readonly) BOOL onMainThread;

- (id)initWithBlock:(id(^)(id result))block;
- (id)clear;

@end

@interface ARHandlerMatcher : KWMatcher

- (void)beCalled;
- (void)beCalledWithValue:(id)value onMainThread:(BOOL)onMainThread;
- (void)beCalledWithResult:(id<AsyncResult>)result onMainThread:(BOOL)onMainThread;
- (void)beCalledWithValue:(id)value result:(id<AsyncResult>)result onMainThread:(BOOL)onMainThread;
- (void)beCalledWithError:(id)error result:(id<AsyncResult>)result onMainThread:(BOOL)onMainThread;

@end
