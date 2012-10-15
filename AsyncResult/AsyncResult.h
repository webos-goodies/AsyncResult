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

typedef enum _AsyncResultState {
    AsyncResultStateSuccess = 0,
    AsyncResultStateError,
    AsyncResultStatePending
} AsyncResultState;

@protocol AsyncResult <NSObject>
@property (nonatomic, readonly) id asyncValue;
@property (nonatomic, readonly) id asyncError;
@property (nonatomic, readonly) NSDictionary* asyncMetadata;
@property (nonatomic, readonly) NSInteger asyncState;
@property (nonatomic, readonly) BOOL asyncIsSuccess;
@property (nonatomic, readonly) BOOL asyncIsCanceled;
- (BOOL)asyncCancel;
- (void)asyncWait:(void(^)(id<AsyncResult> result))handler;
@end

@interface AsyncResultCancel : NSObject
@end

@interface AsyncResultUndefined : NSObject
+ (AsyncResultUndefined*)sharedUndefined;
+ (BOOL)isUndefined:(id)object;
@end

@interface AsyncResult : NSObject<AsyncResult>
- (void)setAsyncValue:(id)value withMetadata:(NSDictionary*)metadata;
- (void)setAsyncError:(id)error withMetadata:(NSDictionary*)metadata;
@end

extern void asyncWait(id<AsyncResult> result, void(^handler)(id<AsyncResult> result));
extern void asyncWaitOnMainThread(id<AsyncResult> result, void(^handler)(id<AsyncResult> result));
extern void asyncWaitSuccess(id<AsyncResult> result, void(^handler)(id value, id<AsyncResult> result));
extern void asyncWaitSuccessOnMainThread(id<AsyncResult> result, void(^handler)(id value, id<AsyncResult> result));
extern void asyncWaitError(id<AsyncResult> result, void(^handler)(id<AsyncResult> result));
extern void asyncWaitErrorOnMainThread(id<AsyncResult> result, void(^handler)(id<AsyncResult> result));
extern id<AsyncResult> asyncChain(id<AsyncResult> result, id<AsyncResult>(^actionCallback)(id<AsyncResult> result));
extern id<AsyncResult> asyncChainOnMainThread(id<AsyncResult> result, id<AsyncResult>(^actionCallback)(id<AsyncResult> result));
extern id<AsyncResult> asyncChainUsingFunction(id<AsyncResult> result, id<AsyncResult>(*actionCallback)(id<AsyncResult> result));
extern id<AsyncResult> asyncChainOnMainThreadUsingFunction(id<AsyncResult> result, id<AsyncResult>(*actionCallback)(id<AsyncResult> result));
extern id<AsyncResult> asyncCombine(NSArray* results);
extern id<AsyncResult> asyncCombineSuccess(NSArray* results);
extern id<AsyncResult> asyncTransform(id<AsyncResult> result, id(^transformer)(id value, NSDictionary* metadata));
extern id<AsyncResult> asyncTransformOnMainThread(id<AsyncResult> result, id(^transformer)(id value, NSDictionary* metadata));
extern id<AsyncResult> asyncTransformUsingFunction(id<AsyncResult> result, id (*transformer)(id value, NSDictionary* metadata));
extern id<AsyncResult> asyncTransformOnMainThreadUsingFunction(id<AsyncResult> result, id (*transformer)(id value, NSDictionary* metadata));
