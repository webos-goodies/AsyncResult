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

#import "Kiwi.h"
#import "HandlerMock.h"

static NSUInteger callCount = 0;
static id callValue = nil;
static BOOL callOnMainThread = NO;
static id multiplyTransformer(NSNumber* result, NSDictionary* metadata) {
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
            [result setAsyncValue:@1 withMetadata:@{ @"test":@"test" }];
            [[multiplyResult should] beCalledWithValue:[NSNumber numberWithInteger:1] onMainThread:YES];
            [[resultCallback should] beCalledWithValue:[NSNumber numberWithInteger:2] result:transformedResult onMainThread:YES];
            [[resultCallback.lastCall.metadata should] equal:@{ @"test":@"test" }];
        });

        it(@"should perform asynchronously on success", ^{
            id<AsyncResult> transformedResult = asyncTransform(result, multiplyResult.blockForTransform);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [result setAsyncValue:[NSNumber numberWithInteger:1] withMetadata:nil];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithValue:[NSNumber numberWithInteger:2] result:transformedResult onMainThread:NO];
            [[multiplyResult should] beCalledWithValue:[NSNumber numberWithInteger:1] onMainThread:NO];
        });

        it(@"should not perform on error", ^{
            id<AsyncResult> transformedResult = asyncTransform(result, multiplyResult.blockForTransform);
            asyncWait(transformedResult, resultCallback.block);

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
            [result setAsyncError:[NSNumber numberWithInteger:4] withMetadata:nil];
            [[multiplyResult shouldNot] beCalled];
            [[resultCallback should] beCalledWithError:[NSNumber numberWithInteger:4] result:transformedResult onMainThread:YES];
        });

        it(@"should not perform asynchronously on error", ^{
            id<AsyncResult> transformedResult = asyncTransform(result, multiplyResult.blockForTransform);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [result setAsyncError:[NSNumber numberWithInteger:5] withMetadata:nil];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithError:[NSNumber numberWithInteger:5] result:transformedResult onMainThread:NO];
            [[multiplyResult shouldNot] beCalled];
        });
    });

    context(@"onMainThread", ^{
        it(@"should perform asynchronously on success", ^{
            id<AsyncResult> transformedResult = asyncTransformOnMainThread(result, multiplyResult.blockForTransform);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [result setAsyncValue:[NSNumber numberWithInteger:1] withMetadata:nil];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithValue:[NSNumber numberWithInteger:2] result:transformedResult onMainThread:YES];
            [[multiplyResult should] beCalledWithValue:[NSNumber numberWithInteger:1] onMainThread:YES];
        });

        it(@"should not perform asynchronously on error", ^{
            id<AsyncResult> transformedResult = asyncTransformOnMainThread(result, multiplyResult.blockForTransform);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [result setAsyncError:[NSNumber numberWithInteger:5] withMetadata:nil];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithError:[NSNumber numberWithInteger:5] result:transformedResult onMainThread:NO];
            [[multiplyResult shouldNot] beCalled];
        });
    });

    context(@"usingFunction", ^{
        it(@"should perform on success", ^{
            id<AsyncResult> transformedResult = asyncTransformUsingFunction(result, multiplyTransformer);
            asyncWait(transformedResult, resultCallback.block);

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
            [result setAsyncValue:[NSNumber numberWithInteger:1] withMetadata:nil];
            assertCallTransformer([NSNumber numberWithInteger:1], YES);
            [[resultCallback should] beCalledWithValue:[NSNumber numberWithInteger:2] result:transformedResult onMainThread:YES];
        });

        it(@"should perform asynchronously on success", ^{
            id<AsyncResult> transformedResult = asyncTransformUsingFunction(result, multiplyTransformer);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [result setAsyncValue:[NSNumber numberWithInteger:1] withMetadata:nil];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithValue:[NSNumber numberWithInteger:2] result:transformedResult onMainThread:NO];
            assertCallTransformer([NSNumber numberWithInteger:1], NO);
        });

        it(@"should not perform on error", ^{
            id<AsyncResult> transformedResult = asyncTransformUsingFunction(result, multiplyTransformer);
            asyncWait(transformedResult, resultCallback.block);

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
            [result setAsyncError:[NSNumber numberWithInteger:4] withMetadata:nil];
            [[theValue(callCount) should] equal:theValue(0)];
            [[resultCallback should] beCalledWithError:[NSNumber numberWithInteger:4] result:transformedResult onMainThread:YES];
        });

        it(@"should not perform asynchronously on error", ^{
            id<AsyncResult> transformedResult = asyncTransformUsingFunction(result, multiplyTransformer);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [result setAsyncError:[NSNumber numberWithInteger:5] withMetadata:nil];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithError:[NSNumber numberWithInteger:5] result:transformedResult onMainThread:NO];
            [[theValue(callCount) should] equal:theValue(0)];
        });
    });

    context(@"onMainThreadUsingFunction", ^{
        it(@"should perform asynchronously on success", ^{
            id<AsyncResult> transformedResult = asyncTransformOnMainThreadUsingFunction(result, multiplyTransformer);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [result setAsyncValue:[NSNumber numberWithInteger:1] withMetadata:nil];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithValue:[NSNumber numberWithInteger:2] result:transformedResult onMainThread:YES];
            assertCallTransformer([NSNumber numberWithInteger:1], YES);
        });

        it(@"should not perform asynchronously on error", ^{
            id<AsyncResult> transformedResult = asyncTransformUsingFunction(result, multiplyTransformer);
            asyncWait(transformedResult, resultCallback.block);
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [result setAsyncError:[NSNumber numberWithInteger:5] withMetadata:nil];
            });

            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithError:[NSNumber numberWithInteger:5] result:transformedResult onMainThread:NO];
            [[theValue(callCount) should] equal:theValue(0)];
        });
    });
});

SPEC_END
