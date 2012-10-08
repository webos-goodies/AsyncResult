//
//  AsyncResultLogicTest.m
//  AsyncResultLogicTest
//
//  Created by Chihiro Ito on 2012/09/29.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import "Kiwi.h"
#import "HandlerMock.h"

SPEC_BEGIN(AsyncResultSpec)

describe(@"AsyncResult", ^{
    __block HandlerMock* resultCallback  = nil;
    __block HandlerMock* resultCallback1 = nil;
    __block HandlerMock* resultCallback2 = nil;
    __block AsyncResult* result = nil;

    beforeEach(^{
        resultCallback  = [[HandlerMock alloc] init];
        resultCallback1 = [[HandlerMock alloc] init];
        resultCallback2 = [[HandlerMock alloc] init];
        result = [[AsyncResult alloc] init];
    });

    afterEach(^{
        resultCallback  = [resultCallback clear];
        resultCallback1 = [resultCallback1 clear];
        resultCallback2 = [resultCallback2 clear];
        result = nil;
    });

    it(@"should call handlers on success", ^{
        [result asyncWait:resultCallback1.block];
        [result asyncWait:resultCallback2.block];

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
        [[theValue(resultCallback1.callCount) should] equal:theValue(0)];
        [[theValue(resultCallback2.callCount) should] equal:theValue(0)];

        result.asyncValue = [[NSNumber alloc] initWithInteger:2];

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:[[NSNumber alloc] initWithInteger:2]];
        [[theValue(resultCallback1.callCount) should] equal:theValue(1)];
        [[theValue(resultCallback2.callCount) should] equal:theValue(1)];

        [[(id)resultCallback1.lastCall.result should] beIdenticalTo:result];
        [[(id)resultCallback2.lastCall.result should] beIdenticalTo:result];
    });

    it(@"should call handlers on error", ^{
        [result asyncWait:resultCallback1.block];
        [result asyncWait:resultCallback2.block];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

        NSString* error   = @"Network Error";
        result.asyncError = error;

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[result.asyncError should] equal:error];
        [[theValue(resultCallback1.callCount) should] equal:theValue(1)];
        [[theValue(resultCallback2.callCount) should] equal:theValue(1)];

        [[(id)resultCallback1.lastCall.result should] beIdenticalTo:result];
        [[(id)resultCallback2.lastCall.result should] beIdenticalTo:result];
    });

    it(@"should be able to attach a handler on a successful result", ^{
        result.asyncValue = [[NSNumber alloc] initWithInteger:2];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:[[NSNumber alloc] initWithInteger:2]];
        // resultCallback should be called immediately on a resolved Result
        [[theValue(resultCallback.callCount) should] equal:theValue(0)];
        
        [result asyncWait:resultCallback.block];
        
        [[theValue(resultCallback.callCount) should] equal:theValue(1)];
        [[(id)resultCallback.lastCall.result should] beIdenticalTo:result];
    });

    it(@"should be able to attach a handler on a successful result", ^{
        NSDictionary* error = @{ @"code":[[NSNumber alloc] initWithInteger:-1], @"errorString":@"Invalid JSON" };
        result.asyncError = error;
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[result.asyncError should] equal:error];
        // resultCallback should be called immediately on a resolved Result
        [[theValue(resultCallback.callCount) should] equal:theValue(0)];

        [result asyncWait:resultCallback.block];

        [[theValue(resultCallback.callCount) should] equal:theValue(1)];
        [[(id)resultCallback.lastCall.result should] beIdenticalTo:result];
    });

    it(@"should throw an exception on multiple successful resolution attempts", ^{
        result.asyncValue = [[NSNumber alloc] initWithInteger:1];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:[[NSNumber alloc] initWithInteger:1]];

        // Try to set the value again
        [[theBlock(^{
            result.asyncValue = [[NSNumber alloc] initWithInteger:4];
        }) should] raise];
    });
    
    it(@"should throw an exception on multiple error resolution attempts", ^{
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

        result.asyncError = [[NSNumber alloc] initWithInteger:5];

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[result.asyncError should] equal:[[NSNumber alloc] initWithInteger:5]];
        // Try to set error again
        [[theBlock(^{
            result.asyncError = [[NSNumber alloc] initWithInteger:4];
        }) should] raise];
    });

    it(@"should throw an exception on success then error resolution attempt", ^{
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

        result.asyncValue = [[NSNumber alloc] initWithInteger:1];

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:[[NSNumber alloc] initWithInteger:1]];

        // Try to set error after setting value
        [[theBlock(^{
            result.asyncError = [[NSNumber alloc] initWithInteger:3];
        }) should] raise];
    });

    it(@"should throw an exception on error then success resolution attempt", ^{
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

        NSString* error = @"fail";
        result.asyncError = error;

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[result.asyncError should] equal:error];
        // Try to set value after setting error
        [[theBlock(^{
            result.asyncValue = [[NSNumber alloc] initWithInteger:1];
        }) should] raise];
    });

    it(@"should success asynchronously", ^{
        __block id value = nil;
        [result asyncWait:^(id<AsyncResult> result) {
            value = result.asyncValue;
        }];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            result.asyncValue = [[NSNumber alloc] initWithInteger:1];
        });

        [[expectFutureValue(value) shouldEventually] equal:[[NSNumber alloc] initWithInteger:1]];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:[[NSNumber alloc] initWithInteger:1]];
    });

    it(@"should error asynchronously", ^{
        __block id error = nil;
        [result asyncWait:^(id<AsyncResult> result) {
            error = result.asyncError;
        }];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            result.asyncError = @"Network failure";
        });

        [[expectFutureValue(error) shouldEventually] equal:@"Network failure"];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[result.asyncError should] equal:@"Network failure"];
    });

    it(@"should be cancelable", ^{
        [[theValue(result.asyncIsCanceled) should] beNo];
        BOOL canceled = [result asyncCancel];
        [[theValue(result.asyncIsCanceled) should] beYes];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[theValue(canceled) should] beYes];
    });

    it(@"should fire error handlers on cancel", ^{
        [result asyncWait:resultCallback.block];
        [result asyncCancel];

        [[theValue(resultCallback.callCount) should] equal:theValue(1)];
        id<AsyncResult> res = resultCallback.lastCall.result;
        [[theValue(res.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[theValue(res.asyncIsCanceled) should] beYes];
    });

    it(@"should be cancelable after a value is set", ^{
        // cancel after setAsyncValue / setAsyncError => no-op
        [result asyncWait:resultCallback.block];
        result.asyncValue = [[NSNumber alloc] initWithInteger:1];

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:[[NSNumber alloc] initWithInteger:1]];
        [[theValue(resultCallback.callCount) should] equal:theValue(1)];

        [result asyncCancel];

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:[[NSNumber alloc] initWithInteger:1]];
        [[theValue(resultCallback.callCount) should] equal:theValue(1)];
    });

    it(@"should ignore values after cancel", ^{
        [result asyncWait:resultCallback.block];
        [result.asyncValue shouldBeNil];

        [result asyncCancel];
        [[theValue(result.asyncIsCanceled) should] beYes];

        result.asyncValue = [[NSNumber alloc] initWithInteger:1];
        [[theValue(result.asyncIsCanceled) should] beYes];
        [result.asyncValue shouldBeNil];

        result.asyncError = [[NSNumber alloc] initWithInteger:3];
        [[theValue(result.asyncIsCanceled) should] beYes];
    });

    it(@"should be no memory leaks", ^{
        __weak AsyncResult* weakPtr;
        result = [[AsyncResult alloc] init];
        weakPtr = result;
        result = nil;
        [[expectFutureValue(weakPtr) shouldEventually] beNil];

        result  = [[AsyncResult alloc] init];
        weakPtr = result;
        [result asyncWait:^(id<AsyncResult> result) {
            [result asyncIsCanceled];
        }];
        result.asyncValue = nil;
        result = nil;
        [[expectFutureValue(weakPtr) shouldEventually] beNil];
    });
});

SPEC_END
