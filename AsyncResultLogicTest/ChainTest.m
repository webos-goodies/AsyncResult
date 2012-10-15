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

static NSUInteger   funcCallCount    = 0;
static id           funcValue        = nil;
static NSUInteger   funcState        = AsyncResultStatePending;
static AsyncResult* funcResult       = nil;
static BOOL         funcOnMainThread = NO;

static id<AsyncResult> actionFunction(id<AsyncResult> result) {
    funcCallCount += 1;
    funcState = result.asyncState;
    if(result.asyncState == AsyncResultStateSuccess) {
        funcValue = result.asyncValue;
    }
    funcOnMainThread = [NSThread isMainThread];
    return funcResult;
}

SPEC_BEGIN(ChainSpec)

describe(@"Chain", ^{
    registerMatchers(@"AR");

    __block AsyncResult*  givenResult;
    __block AsyncResult*  dependentResult;
    __block HandlerMock*  counter;
    __block HandlerMock*  actionCallback;
    __block NSDictionary* metadata;

    beforeAll(^{
        metadata = @{ @"test":@"test" };
    });

    beforeEach(^{
        givenResult     = [[AsyncResult alloc] init];
        dependentResult = [[AsyncResult alloc] init];
        counter         = [[HandlerMock alloc] init];
        actionCallback  = [[HandlerMock alloc] initWithBlock:^id<AsyncResult>(id<AsyncResult> result) {
            return dependentResult;
        }];

        funcResult = dependentResult;
    });

    afterEach(^{
        givenResult     = nil;
        dependentResult = nil;
        counter         = [counter clear];
        actionCallback  = [actionCallback clear];

        funcCallCount    = 0;
        funcState        = AsyncResultStatePending;
        funcValue        = nil;
        funcResult       = nil;
        funcOnMainThread = NO;
    });

    afterAll(^{
        metadata = nil;
    });


#pragma mark - Synchronous tests for asyncChain

    context(@"UsingBlock", ^{
        it(@"should chain when both results success", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWaitSuccess(finalResult, counter.blockWithValue);

            [givenResult setAsyncValue:@1 withMetadata:metadata];
            [dependentResult setAsyncValue:@2 withMetadata:givenResult.asyncMetadata];

            [[actionCallback should] beCalledWithValue:@1 result:givenResult onMainThread:YES];
            [[actionCallback.lastCall.metadata should] equal:metadata];
            [[counter should] beCalledWithValue:@2 result:finalResult onMainThread:YES];
            [[counter.lastCall.metadata should] equal:metadata];
        });

        it(@"should not chain when the first result fail", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            [givenResult setAsyncError:@4 withMetadata:metadata];

            [[actionCallback shouldNot] beCalled];
            [[counter should] beCalledWithError:@4 result:finalResult onMainThread:YES];
            [[counter.lastCall.metadata should] equal:metadata];
        });

        it(@"should get an error result when the second result fail", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            [givenResult setAsyncValue:@1 withMetadata:metadata];
            [dependentResult setAsyncError:@5 withMetadata:givenResult.asyncMetadata];

            [[actionCallback should] beCalledWithValue:@1 result:givenResult onMainThread:YES];
            [[actionCallback.lastCall.metadata should] equal:metadata];
            [[counter should] beCalledWithError:@5 result:finalResult onMainThread:YES];
            [[counter.lastCall.metadata should] equal:metadata];
        });


#pragma mark - Asynchronous tests for asyncChain.

        it(@"should chain asynchronously when both results success", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [givenResult setAsyncValue:value withMetadata:nil];
            });

            [[expectFutureValue(actionCallback) shouldEventually] beCalledWithValue:value result:givenResult onMainThread:NO];

            value = [[NSNumber alloc] initWithInteger:2];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [dependentResult setAsyncValue:value withMetadata:nil];
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithValue:value result:finalResult onMainThread:NO];
        });

        it(@"should not chain when the first result fail asynchronously", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            NSNumber* error = [[NSNumber alloc] initWithInteger:6];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [givenResult setAsyncError:error withMetadata:nil];
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithError:error result:finalResult onMainThread:NO];
            [[actionCallback shouldNot] beCalled];
        });

        it(@"should get an error result asynchronously when the second result fail", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [givenResult setAsyncValue:value withMetadata:nil];
            });

            [[expectFutureValue(actionCallback) shouldEventually] beCalledWithValue:value result:givenResult onMainThread:NO];

            NSNumber* error = [[NSNumber alloc] initWithInteger:7];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [dependentResult setAsyncError:error withMetadata:nil];
            });
            
            [[expectFutureValue(counter) shouldEventually] beCalledWithError:error result:finalResult onMainThread:NO];
        });
    });

#pragma mark - Tests for asyncChainOnMainThread.

    context(@"OnMainThread", ^{
        it(@"should chain on main thread when both results success", ^{
            AsyncResult* finalResult = asyncChainOnMainThread(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [givenResult setAsyncValue:value withMetadata:nil];
            });

            [[expectFutureValue(actionCallback) shouldEventually] beCalledWithValue:value result:givenResult onMainThread:YES];

            value = [[NSNumber alloc] initWithInteger:2];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [dependentResult setAsyncValue:value withMetadata:nil];
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithValue:value result:finalResult onMainThread:NO];
        });

        it(@"should chain on main thread then get an error result", ^{
            AsyncResult* finalResult = asyncChainOnMainThread(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [givenResult setAsyncValue:value withMetadata:nil];
            });

            [[expectFutureValue(actionCallback) shouldEventually] beCalledWithValue:value result:givenResult onMainThread:YES];

            NSNumber* error = [[NSNumber alloc] initWithInteger:7];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [dependentResult setAsyncError:error withMetadata:nil];
            });
            
            [[expectFutureValue(counter) shouldEventually] beCalledWithError:error result:finalResult onMainThread:NO];
        });
    });

#pragma mark - Tests for asyncChainUsingFunction.

    context(@"UsingFunction", ^{
        it(@"should chain when both results success", ^{
            AsyncResult* finalResult = asyncChainUsingFunction(givenResult, actionFunction);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            [givenResult setAsyncValue:value withMetadata:nil];

            [[theValue(funcCallCount) should] equal:theValue(1)];
            [[theValue(funcState) should] equal:theValue(AsyncResultStateSuccess)];
            [[value should] equal:value];
            [[theValue(funcOnMainThread) should] equal:theValue(YES)];

            value = [[NSNumber alloc] initWithInteger:2];
            [dependentResult setAsyncValue:value withMetadata:nil];

            [[counter should] beCalledWithValue:value result:finalResult onMainThread:YES];
        });

        it(@"should chain asynchronously then get an error result", ^{
            AsyncResult* finalResult = asyncChainUsingFunction(givenResult, actionFunction);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [givenResult setAsyncValue:value withMetadata:nil];
            });

            [[expectFutureValue(theValue(funcCallCount)) shouldEventually] equal:theValue(1)];
            [[theValue(funcState) should] equal:theValue(AsyncResultStateSuccess)];
            [[value should] equal:value];
            [[theValue(funcOnMainThread) should] equal:theValue(NO)];

            NSNumber* error = [[NSNumber alloc] initWithInteger:7];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [dependentResult setAsyncError:error withMetadata:nil];
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithError:error result:finalResult onMainThread:NO];
        });
    });

#pragma mark - Tests for asyncChainOnMainThreadUsingFunction.

    context(@"OnMainThreadUsingFunction", ^{
        it(@"should chain when both results success", ^{
            AsyncResult* finalResult = asyncChainOnMainThreadUsingFunction(givenResult, actionFunction);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [givenResult setAsyncValue:value withMetadata:nil];
            });

            [[expectFutureValue(theValue(funcCallCount)) shouldEventually] equal:theValue(1)];
            [[theValue(funcState) should] equal:theValue(AsyncResultStateSuccess)];
            [[value should] equal:value];
            [[theValue(funcOnMainThread) should] equal:theValue(YES)];

            value = [[NSNumber alloc] initWithInteger:2];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [dependentResult setAsyncValue:value withMetadata:nil];
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithValue:value result:finalResult onMainThread:NO];
        });

        it(@"should chain asynchronously then get an error result", ^{
            AsyncResult* finalResult = asyncChainOnMainThreadUsingFunction(givenResult, actionFunction);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [givenResult setAsyncValue:value withMetadata:nil];
            });

            [[expectFutureValue(theValue(funcCallCount)) shouldEventually] equal:theValue(1)];
            [[theValue(funcState) should] equal:theValue(AsyncResultStateSuccess)];
            [[value should] equal:value];
            [[theValue(funcOnMainThread) should] equal:theValue(YES)];

            NSNumber* error = [[NSNumber alloc] initWithInteger:7];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [dependentResult setAsyncError:error withMetadata:nil];
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithError:error result:finalResult onMainThread:NO];
        });
    });
    
});

SPEC_END
