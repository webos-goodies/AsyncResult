//
//  AsyncResult.m
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/09/29.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import "AsyncResult.h"


#pragma mark - AsyncResultCancel

@implementation AsyncResultCancel
@end


#pragma mark - AsyncResult

@implementation AsyncResult {
    NSMutableArray* _handlers;
}

@synthesize asyncValue = _asyncValue;
@synthesize asyncError = _asyncError;
@synthesize asyncState = _asyncState;

- (id)init
{
    self = [super init];
    if (self) {
        _asyncState = AsyncResultStatePending;
        _asyncValue = nil;
        _asyncError = nil;
        _handlers   = [[NSMutableArray alloc] initWithCapacity:4];
    }
    return self;
}

- (void)setAsyncValue:(id)value
{
    BOOL shouldCall = NO;
    @synchronized(self) {
        if([self isPending]) {
            _asyncValue = value;
            _asyncState = AsyncResultStateSuccess;
            shouldCall  = YES;
        } else if(!self.asyncIsCanceled) {
            NSAssert(NO, @"Multiple attempts to set the state of this Result");
        }
    }
    if(shouldCall) {
        [self callHandlers];
    }
}

- (void)setAsyncError:(id)error
{
    BOOL shouldCall = NO;
    @synchronized(self) {
        if([self isPending]) {
            _asyncError = error;
            _asyncState = AsyncResultStateError;
            shouldCall  = YES;
        } else if(!self.asyncIsCanceled) {
            NSAssert(NO, @"Multiple attempts to set the state of this Result");
        }
    }
    if(shouldCall) {
        [self callHandlers];
    }
}

- (BOOL)asyncIsCanceled
{
    return _asyncState == AsyncResultStateError && [self.asyncError isKindOfClass:[AsyncResultCancel class]];
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


#pragma mark - Utility functions

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
                    returnedResult.asyncValue = dependentResult.asyncValue;
                } else {
                    returnedResult.asyncError = dependentResult.asyncError;
                }
            });
        } else {
            // First action failed, the returned result should also fail.
            returnedResult.asyncError = result.asyncError;
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
                        combinedResult.asyncValue = results;
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
            combinedResult.asyncValue = results;
        } else {
            combinedResult.asyncError = results;
        }
    });
    
    return combinedResult;
}

id<AsyncResult> asyncTransform(id<AsyncResult> result, id(^transformer)(id))
{
    AsyncResult* returnedResult = [[AsyncResult alloc] init];

    asyncWait(result, ^(id<AsyncResult> res) {
        if(res.asyncState == AsyncResultStateSuccess) {
            returnedResult.asyncValue = transformer(res.asyncValue);
        } else {
            returnedResult.asyncError = res.asyncError;
        }
    });

    return returnedResult;
}

id<AsyncResult> asyncTransformUsingFunction(id<AsyncResult> result, id (*transformer)(id value))
{
    AsyncResult* returnedResult = [[AsyncResult alloc] init];

    asyncWait(result, ^(id<AsyncResult> res) {
        if(res.asyncState == AsyncResultStateSuccess) {
            returnedResult.asyncValue = transformer(res.asyncValue);
        } else {
            returnedResult.asyncError = res.asyncError;
        }
    });

    return returnedResult;
}
