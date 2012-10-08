#import "Kiwi.h"
#import "HandlerMock.h"

static NSUInteger callCount = 0;
static id callValue = nil;
static BOOL callOnMainThread = NO;
static id multiplyTransformer(NSNumber* result) {
    callCount += 1;
    callValue = result;
    callOnMainThread = [NSThread isMainThread];
    return [[NSNumber alloc] initWithInteger:result.integerValue * 2];
}

SPEC_BEGIN(TransformSpec)

describe(@"asyncTransform", ^{
    registerMatchers(@"AR");

    __block AsyncResult* result;
    __block HandlerMock* resultCallback;
    __block HandlerMock* multiplyResult;

    void (^assertCallTransformer)(id value, BOOL onMainThread) = ^(id value, BOOL onMainThread){
        [[theValue(callCount) should] equal:theValue(1)];
        [[callValue should] equal:value];
        [[theValue(callOnMainThread) should] equal:theValue(onMainThread)];
    };

    beforeEach(^{
        result = [[AsyncResult alloc] init];
        resultCallback = [[HandlerMock alloc] init];
        multiplyResult = [[HandlerMock alloc] initWithBlock:^NSNumber*(NSNumber* result) {
            return [[NSNumber alloc] initWithInteger:result.integerValue * 2];
        }];
    });

    afterEach(^{
        result = nil;
        resultCallback = [resultCallback clear];
        multiplyResult = [multiplyResult clear];

        callCount = 0;
        callValue = nil;
        callOnMainThread = NO;
    });

    context(@"usingBlock", ^{
        it(@"should perform on success", ^{
            id<AsyncResult> transformedResult = asyncTransform(result, multiplyResult.blockForTransform);
            asyncWait(transformedResult, resultCallback.block);

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
            result.asyncValue = [NSNumber numberWithInteger:1];
            [[multiplyResult should] beCalledWithValue:[NSNumber numberWithInteger:1] onMainThread:YES];
            [[resultCallback should] beCalledWithValue:[NSNumber numberWithInteger:2] result:transformedResult onMainThread:YES];
        });

        it(@"should perform asynchronously on success", ^{
            id<AsyncResult> transformedResult = asyncTransform(result, multiplyResult.blockForTransform);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                result.asyncValue = [NSNumber numberWithInteger:1];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithValue:[NSNumber numberWithInteger:2] result:transformedResult onMainThread:NO];
            [[multiplyResult should] beCalledWithValue:[NSNumber numberWithInteger:1] onMainThread:NO];
        });

        it(@"should not perform on error", ^{
            id<AsyncResult> transformedResult = asyncTransform(result, multiplyResult.blockForTransform);
            asyncWait(transformedResult, resultCallback.block);

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
            result.asyncError = [NSNumber numberWithInteger:4];
            [[multiplyResult shouldNot] beCalled];
            [[resultCallback should] beCalledWithError:[NSNumber numberWithInteger:4] result:transformedResult onMainThread:YES];
        });

        it(@"should not perform asynchronously on error", ^{
            id<AsyncResult> transformedResult = asyncTransform(result, multiplyResult.blockForTransform);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                result.asyncError = [NSNumber numberWithInteger:5];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithError:[NSNumber numberWithInteger:5] result:transformedResult onMainThread:NO];
            [[multiplyResult shouldNot] beCalled];
        });
    });

    context(@"withFunction", ^{
        it(@"should perform on success", ^{
            id<AsyncResult> transformedResult = asyncTransformUsingFunction(result, multiplyTransformer);
            asyncWait(transformedResult, resultCallback.block);

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
            result.asyncValue = [NSNumber numberWithInteger:1];
            assertCallTransformer([NSNumber numberWithInteger:1], YES);
            [[resultCallback should] beCalledWithValue:[NSNumber numberWithInteger:2] result:transformedResult onMainThread:YES];
        });

        it(@"should perform asynchronously on success", ^{
            id<AsyncResult> transformedResult = asyncTransformUsingFunction(result, multiplyTransformer);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                result.asyncValue = [NSNumber numberWithInteger:1];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithValue:[NSNumber numberWithInteger:2] result:transformedResult onMainThread:NO];
            assertCallTransformer([NSNumber numberWithInteger:1], NO);
        });

        it(@"should not perform on error", ^{
            id<AsyncResult> transformedResult = asyncTransformUsingFunction(result, multiplyTransformer);
            asyncWait(transformedResult, resultCallback.block);

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
            result.asyncError = [NSNumber numberWithInteger:4];
            [[theValue(callCount) should] equal:theValue(0)];
            [[resultCallback should] beCalledWithError:[NSNumber numberWithInteger:4] result:transformedResult onMainThread:YES];
        });

        it(@"should not perform asynchronously on error", ^{
            id<AsyncResult> transformedResult = asyncTransformUsingFunction(result, multiplyTransformer);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                result.asyncError = [NSNumber numberWithInteger:5];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithError:[NSNumber numberWithInteger:5] result:transformedResult onMainThread:NO];
            [[theValue(callCount) should] equal:theValue(0)];
        });
    });
});

SPEC_END
