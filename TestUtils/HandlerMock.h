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
