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

#import "AsyncResult.h"


#pragma mark - AsyncResultCancel

@implementation AsyncResultCancel
@end


#pragma mark - AsyncResultUndefined
static AsyncResultUndefined* singletonUndefined = nil;

@implementation AsyncResultUndefined

+ (AsyncResultUndefined*)sharedUndefined
{
    // Though this method possibly returns a different object in a strict sense, it should not be a problem.
    if(!singletonUndefined) {
        singletonUndefined = [[AsyncResultUndefined alloc] init];
    }
    return singletonUndefined;
}

+ (BOOL)isUndefined:(id)object
{
    return [object isMemberOfClass:[AsyncResultUndefined class]];
}

@end


#pragma mark - AsyncResult

@implementation AsyncResult {
    NSMutableArray* _handlers;
}

@synthesize asyncValue    = _asyncValue;
@synthesize asyncError    = _asyncError;
@synthesize asyncMetadata = _asyncMetadata;
@synthesize asyncState    = _asyncState;

- (id)init
{
    self = [super init];
    if (self) {
        _asyncState    = AsyncResultStatePending;
        _asyncValue    = [AsyncResultUndefined sharedUndefined];
        _asyncError    = [AsyncResultUndefined sharedUndefined];
        _asyncMetadata = nil;
        _handlers      = [[NSMutableArray alloc] initWithCapacity:4];
    }
    return self;
}

- (void)setAsyncValue:(id)value withMetadata:(NSDictionary *)metadata
{
    BOOL shouldCall = NO;
    @synchronized(self) {
        if([self isPending]) {
            _asyncValue    = value;
            _asyncMetadata = [metadata isMemberOfClass:[NSDictionary class]] ? metadata : [metadata copy];
            _asyncState    = AsyncResultStateSuccess;
            shouldCall     = YES;
        } else if(!self.asyncIsCanceled) {
            NSAssert(NO, @"Multiple attempts to set the state of this Result");
        }
    }
    if(shouldCall) {
        [self callHandlers];
    }
}

- (void)setAsyncError:(id)error withMetadata:(NSDictionary *)metadata
{
    BOOL shouldCall = NO;
    @synchronized(self) {
        if([self isPending]) {
            _asyncError    = error;
            _asyncMetadata = [metadata isMemberOfClass:[NSDictionary class]] ? metadata : [metadata copy];
            _asyncState    = AsyncResultStateError;
            shouldCall     = YES;
        } else if(!self.asyncIsCanceled) {
            NSAssert(NO, @"Multiple attempts to set the state of this Result");
        }
    }
    if(shouldCall) {
        [self callHandlers];
    }
}

- (BOOL)asyncIsSuccess
{
    return _asyncState == AsyncResultStateSuccess;
}

- (BOOL)asyncIsCanceled
{
    return _asyncState == AsyncResultStateError && [self.asyncError isMemberOfClass:[AsyncResultCancel class]];
}

- (BOOL)asyncCancel
{
    BOOL shouldCall = NO;
    @synchronized(self) {
        if ([self isPending]) {
            _asyncError = [[AsyncResultCancel alloc] init];
            _asyncState = AsyncResultStateError;
            shouldCall  = YES;
        }
    }
    if(shouldCall) {
        [self callHandlers];
    }
    return shouldCall;
}

- (void)asyncWait:(void (^)(id<AsyncResult> result))handler
{
    BOOL shouldCall = YES;
    @synchronized(self) {
        if([self isPending]) {
            shouldCall = NO;
            [_handlers addObject:handler];
        }
    }
    if(shouldCall) {
        handler(self);
    }
}

// private methods

- (BOOL)isPending
{
    return _asyncState == AsyncResultStatePending;
}

- (void)callHandlers
{
    NSArray* handlers = _handlers;
    _handlers = nil;
    for(void(^handler)(id<AsyncResult> result) in handlers) {
        handler(self);
    }
}

@end


#pragma mark - asyncWait and variants

void asyncWait(id<AsyncResult> result, void(^handler)(id<AsyncResult> result))
{
    [result asyncWait:handler];
}

void asyncWaitOnMainThread(id<AsyncResult> result, void(^handler)(id<AsyncResult> result))
{
    [result asyncWait:^(id<AsyncResult> result) {
        if([NSThread isMainThread]) {
            handler(result);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{ handler(result); });
        }
    }];
}

void asyncWaitSuccess(id<AsyncResult> result, void(^handler)(id value, id<AsyncResult> result))
{
    [result asyncWait:^(id<AsyncResult> result) {
        if(result.asyncState == AsyncResultStateSuccess) {
            handler(result.asyncValue, result);
        }
    }];
}

void asyncWaitSuccessOnMainThread(id<AsyncResult> result, void(^handler)(id value, id<AsyncResult> result))
{
    [result asyncWait:^(id<AsyncResult> result) {
        if(result.asyncState == AsyncResultStateSuccess) {
            if([NSThread isMainThread]) {
                handler(result.asyncValue, result);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{ handler(result.asyncValue, result); });
            }
        }
    }];
}

void asyncWaitError(id<AsyncResult> result, void(^handler)(id<AsyncResult> result))
{
    [result asyncWait:^(id<AsyncResult> result) {
        if(result.asyncState == AsyncResultStateError) {
            handler(result);
        }
    }];
}

void asyncWaitErrorOnMainThread(id<AsyncResult> result, void(^handler)(id<AsyncResult> result))
{
    [result asyncWait:^(id<AsyncResult> result) {
        if(result.asyncState == AsyncResultStateError) {
            if([NSThread isMainThread]) {
                handler(result);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{ handler(result); });
            }
        }
    }];
}


#pragma mark - asyncChain and variants

static id<AsyncResult>
asyncChainInternal(id<AsyncResult> result,
                   id<AsyncResult>(^actionCallback)(id<AsyncResult>),
                   void (*firstWait)(id<AsyncResult>, void(^)(id<AsyncResult>)))
{
    AsyncResult* returnedResult = [[AsyncResult alloc] init];

    // Wait for first action.
    firstWait(result, ^(id<AsyncResult> result) {
        if(result.asyncState == AsyncResultStateSuccess) {

            // The first action scceeded. Chain the dependent action.
            id<AsyncResult> dependentResult = actionCallback(result);
            asyncWait(dependentResult, ^(id<AsyncResult> dependentResult) {

                // The dependent action completed. Set the returned result based on the dependent action's outcome.
                if(dependentResult.asyncState == AsyncResultStateSuccess) {
                    [returnedResult setAsyncValue:dependentResult.asyncValue withMetadata:dependentResult.asyncMetadata];
                } else {
                    [returnedResult setAsyncError:dependentResult.asyncError withMetadata:dependentResult.asyncMetadata];
                }
            });
        } else {
            // First action failed, the returned result should also fail.
            [returnedResult setAsyncError:result.asyncError withMetadata:result.asyncMetadata];
        }
    });

    return returnedResult;
}


id<AsyncResult> asyncChain(id<AsyncResult> result, id<AsyncResult>(^actionCallback)(id<AsyncResult> result))
{
    return asyncChainInternal(result, actionCallback, asyncWait);
}

id<AsyncResult> asyncChainOnMainThread(id<AsyncResult> result, id<AsyncResult>(^actionCallback)(id<AsyncResult> result))
{
    return asyncChainInternal(result, actionCallback, asyncWaitOnMainThread);
}

id<AsyncResult> asyncChainUsingFunction(id<AsyncResult> result, id<AsyncResult>(*actionCallback)(id<AsyncResult> result))
{
    return asyncChainInternal(result, ^id<AsyncResult>(id<AsyncResult>result) {
        return actionCallback(result);
    }, asyncWait);
}

id<AsyncResult> asyncChainOnMainThreadUsingFunction(id<AsyncResult> result, id<AsyncResult>(*actionCallback)(id<AsyncResult> result))
{
    return asyncChainInternal(result, ^id<AsyncResult>(id<AsyncResult>result) {
        return actionCallback(result);
    }, asyncWaitOnMainThread);
}


#pragma mark - asyncCombine and variants

id<AsyncResult> asyncCombine(NSArray* results)
{
    results = [results copy];
    AsyncResult* combinedResult = [[AsyncResult alloc] init];
    
    for(id<AsyncResult> result in results) {
        asyncWait(result, ^(id<AsyncResult> result) {
            BOOL resolved = YES;
            for(id<AsyncResult> result in results) {
                resolved = (result.asyncState != AsyncResultStatePending) && resolved;
            }
            if(resolved) {
                @synchronized(combinedResult) {
                    if(combinedResult.asyncState == AsyncResultStatePending) {
                        [combinedResult setAsyncValue:results withMetadata:nil];
                    }
                }
            }
        });
    }
    
    return combinedResult;
}

id<AsyncResult> asyncCombineSuccess(NSArray* results)
{
    AsyncResult* combinedResult = [[AsyncResult alloc] init];
    
    asyncWait(asyncCombine(results), ^(id<AsyncResult> res) {
        NSArray* results   = res.asyncValue;
        BOOL     succeeded = YES;
        for(id<AsyncResult>result in results) {
            succeeded = (result.asyncState == AsyncResultStateSuccess) && succeeded;
        }
        if(succeeded) {
            [combinedResult setAsyncValue:results withMetadata:nil];
        } else {
            [combinedResult setAsyncError:results withMetadata:nil];
        }
    });
    
    return combinedResult;
}


#pragma mark - asyncTransform and variants

static id<AsyncResult> asyncTransformInternal(id<AsyncResult> result,
                                              id(^transformBlock)(id value, NSDictionary* metadata),
                                              id(*transformFunction)(id value, NSDictionary* metadata),
                                              BOOL onMainThread)
{
    AsyncResult* returnedResult = [[AsyncResult alloc] init];

    asyncWait(result, ^(id<AsyncResult> res) {
        if(res.asyncState == AsyncResultStateSuccess) {
            id            value    = res.asyncValue;
            NSDictionary* metadata = res.asyncMetadata;
            if(transformBlock) {
                if(onMainThread) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [returnedResult setAsyncValue:transformBlock(value, metadata) withMetadata:metadata];
                    });
                } else {
                    [returnedResult setAsyncValue:transformBlock(value, metadata) withMetadata:metadata];
                }
            } else if(transformFunction) {
                if(onMainThread) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [returnedResult setAsyncValue:transformFunction(value, metadata) withMetadata:metadata];
                    });
                } else {
                    [returnedResult setAsyncValue:transformFunction(value, metadata) withMetadata:metadata];
                }
            } else {
                [returnedResult setAsyncValue:value withMetadata:metadata];
            }
        } else {
            [returnedResult setAsyncError:res.asyncError withMetadata:res.asyncMetadata];
        }
    });

    return returnedResult;
}

id<AsyncResult> asyncTransform(id<AsyncResult> result, id(^transformer)(id, NSDictionary*))
{
    return asyncTransformInternal(result, transformer, NULL, NO);
}

id<AsyncResult> asyncTransformOnMainThread(id<AsyncResult> result, id(^transformer)(id, NSDictionary*))
{
    return asyncTransformInternal(result, transformer, NULL, YES);
}

id<AsyncResult> asyncTransformUsingFunction(id<AsyncResult> result, id (*transformer)(id, NSDictionary*))
{
    return asyncTransformInternal(result, nil, transformer, NO);
}

id<AsyncResult> asyncTransformOnMainThreadUsingFunction(id<AsyncResult> result, id (*transformer)(id, NSDictionary*))
{
    return asyncTransformInternal(result, nil, transformer, YES);
}
