#import "Kiwi.h"
#import "HandlerMock.h"

SPEC_BEGIN(WaitSpec)

describe(@"Wait", ^{
    registerMatchers(@"AR");

    __block AsyncResult* result = nil;
    __block HandlerMock* waitCallback          = nil;
    __block HandlerMock* waitOnSuccessCallback = nil;
    __block HandlerMock* waitOnErrorCallback   = nil;

    beforeEach(^{
        result = [[AsyncResult alloc] init];
        waitCallback          = [[HandlerMock alloc] init];
        waitOnSuccessCallback = [[HandlerMock alloc] init];
        waitOnErrorCallback   = [[HandlerMock alloc] init];
    });

    afterEach(^{
        result = nil;
        waitCallback          = [waitCallback clear];
        waitOnSuccessCallback = [waitOnSuccessCallback clear];
        waitOnErrorCallback   = [waitOnErrorCallback clear];
    });

    it(@"should success synchronously", ^{
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
        [result.asyncValue shouldBeNil];

        asyncWait(result, waitCallback.block);
        asyncWaitSuccess(result, waitOnSuccessCallback.blockWithValue);
        asyncWaitError(result, waitOnErrorCallback.block);

        NSNumber* value = [[NSNumber alloc] initWithInteger:1];
        result.asyncValue = value;

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:[[NSNumber alloc] initWithInteger:1]];

        [[waitCallback should] beCalledWithResult:result onMainThread:YES];
        [[waitOnSuccessCallback should] beCalledWithValue:value result:result onMainThread:YES];
        [[waitOnErrorCallback shouldNot] beCalled];
    });

    it(@"should success asynchronously", ^{
        asyncWait(result, waitCallback.block);
        asyncWaitSuccess(result, waitOnSuccessCallback.blockWithValue);
        asyncWaitError(result, waitOnErrorCallback.block);

        NSNumber* value = [[NSNumber alloc] initWithInteger:1];
        @synchronized(result) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @synchronized(result) {
                    result.asyncValue = value;
                }
            });

            [result.asyncValue shouldBeNil];
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            [[waitCallback shouldNot] beCalled];
            [[waitOnSuccessCallback shouldNot] beCalled];
            [[waitOnErrorCallback shouldNot] beCalled];
        }

        [[expectFutureValue(waitCallback) shouldEventually] beCalledWithResult:result onMainThread:NO];
        @synchronized(result) {
            [[waitOnSuccessCallback should] beCalledWithValue:value result:result onMainThread:NO];
            [[waitOnErrorCallback shouldNot] beCalled];
        }
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:value];
    });

    it(@"should success then dispatch handlers to main thread", ^{
        asyncWaitOnMainThread(result, waitCallback.block);
        asyncWaitSuccessOnMainThread(result, waitOnSuccessCallback.blockWithValue);
        asyncWaitErrorOnMainThread(result, waitOnErrorCallback.block);

        NSNumber* value = [[NSNumber alloc] initWithInteger:1];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            result.asyncValue = value;
        });

        [[expectFutureValue(waitCallback) shouldEventually] beCalledWithResult:result onMainThread:YES];
        [[expectFutureValue(waitOnSuccessCallback) shouldEventually] beCalledWithValue:value result:result onMainThread:YES];
        [[waitOnErrorCallback shouldNot] beCalled];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:value];
    });
    
    it(@"should fail synchronously", ^{
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
        [result.asyncValue shouldBeNil];

        asyncWait(result, waitCallback.block);
        asyncWaitSuccess(result, waitOnSuccessCallback.blockWithValue);
        asyncWaitError(result, waitOnErrorCallback.block);

        result.asyncError = @"failed";

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [result.asyncValue shouldBeNil];
        [[result.asyncError should] equal:@"failed"];

        [[waitCallback should] beCalledWithResult:result onMainThread:YES];
        [[waitOnSuccessCallback shouldNot] beCalled];
        [[waitOnErrorCallback should] beCalledWithResult:result onMainThread:YES];
    });

    it(@"should fail asynchronously", ^{
        asyncWait(result, waitCallback.block);
        asyncWaitSuccess(result, waitOnSuccessCallback.blockWithValue);
        asyncWaitError(result, waitOnErrorCallback.block);

        @synchronized(result) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @synchronized(result) {
                    result.asyncError = @"failed";
                }
            });

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
            [result.asyncValue shouldBeNil];

            [[waitCallback shouldNot] beCalled];
            [[waitOnSuccessCallback shouldNot] beCalled];
            [[waitOnErrorCallback shouldNot] beCalled];
        }

        [[expectFutureValue(waitCallback) shouldEventually] beCalledWithResult:result onMainThread:NO];
        @synchronized(result) { // wait for the finish of state change.
            [[waitOnSuccessCallback shouldNot] beCalled];
            [[waitOnErrorCallback should] beCalledWithResult:result onMainThread:NO];
        }
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [result.asyncValue shouldBeNil];
        [[result.asyncError should] equal:@"failed"];
    });

    it(@"should fail then dispatch handlers to main thread", ^{
        asyncWaitOnMainThread(result, waitCallback.block);
        asyncWaitSuccessOnMainThread(result, waitOnSuccessCallback.blockWithValue);
        asyncWaitErrorOnMainThread(result, waitOnErrorCallback.block);

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            result.asyncError = @"failed";
        });

        [[expectFutureValue(waitCallback) shouldEventually] beCalledWithResult:result onMainThread:YES];
        [[expectFutureValue(waitOnErrorCallback) shouldEventually] beCalledWithResult:result onMainThread:YES];
        [[waitOnSuccessCallback shouldNot] beCalled];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [result.asyncValue shouldBeNil];
        [[result.asyncError should] equal:@"failed"];
    });
});

SPEC_END
