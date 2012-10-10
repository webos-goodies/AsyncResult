//
//  AsyncResult.h
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/09/29.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

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
@property (nonatomic, readonly) BOOL asyncIsCanceled;
- (BOOL)asyncCancel;
- (void)asyncWait:(void(^)(id<AsyncResult> result))handler;
@end

@interface AsyncResultCancel : NSObject
@end

@interface AsyncResult : NSObject<AsyncResult>
@property (nonatomic) id asyncValue;
@property (nonatomic) id asyncError;
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
