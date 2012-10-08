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

    __block AsyncResult* givenResult;
    __block AsyncResult* dependentResult;
    __block HandlerMock* counter;
    __block HandlerMock* actionCallback;

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

#pragma mark - Synchronous tests for asyncChain

    context(@"UsingBlock", ^{
        it(@"should chain when both results success", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWaitSuccess(finalResult, counter.blockWithValue);

            givenResult.asyncValue     = [[NSNumber alloc] initWithInteger:1];
            dependentResult.asyncValue = [[NSNumber alloc] initWithInteger:2];

            [[actionCallback should] beCalledWithValue:[[NSNumber alloc] initWithInteger:1] result:givenResult onMainThread:YES];
            [[counter should] beCalledWithValue:[[NSNumber alloc] initWithInteger:2] result:finalResult onMainThread:YES];
        });

        it(@"should not chain when the first result fail", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            givenResult.asyncError = [[NSNumber alloc] initWithInteger:4];

            [[actionCallback shouldNot] beCalled];
            [[counter should] beCalledWithError:[[NSNumber alloc] initWithInteger:4] result:finalResult onMainThread:YES];
        });

        it(@"should get an error result when the second result fail", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            givenResult.asyncValue = [[NSNumber alloc] initWithInteger:1];
            dependentResult.asyncError = [[NSNumber alloc] initWithInteger:5];

            [[actionCallback should] beCalledWithValue:[[NSNumber alloc] initWithInteger:1] result:givenResult onMainThread:YES];
            [[counter should] beCalledWithError:[[NSNumber alloc] initWithInteger:5] result:finalResult onMainThread:YES];
        });


#pragma mark - Asynchronous tests for asyncChain.

        it(@"should chain asynchronously when both results success", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                givenResult.asyncValue = value;
            });

            [[expectFutureValue(actionCallback) shouldEventually] beCalledWithValue:value result:givenResult onMainThread:NO];

            value = [[NSNumber alloc] initWithInteger:2];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dependentResult.asyncValue = value;
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithValue:value result:finalResult onMainThread:NO];
        });

        it(@"should not chain when the first result fail asynchronously", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            NSNumber* error = [[NSNumber alloc] initWithInteger:6];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                givenResult.asyncError = error;
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithError:error result:finalResult onMainThread:NO];
            [[actionCallback shouldNot] beCalled];
        });

        it(@"should get an error result asynchronously when the second result fail", ^{
            AsyncResult* finalResult = asyncChain(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                givenResult.asyncValue = value;
            });

            [[expectFutureValue(actionCallback) shouldEventually] beCalledWithValue:value result:givenResult onMainThread:NO];

            NSNumber* error = [[NSNumber alloc] initWithInteger:7];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dependentResult.asyncError = error;
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
                givenResult.asyncValue = value;
            });

            [[expectFutureValue(actionCallback) shouldEventually] beCalledWithValue:value result:givenResult onMainThread:YES];

            value = [[NSNumber alloc] initWithInteger:2];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dependentResult.asyncValue = value;
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithValue:value result:finalResult onMainThread:NO];
        });

        it(@"should chain on main thread then get an error result", ^{
            AsyncResult* finalResult = asyncChainOnMainThread(givenResult, actionCallback.blockForChain);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                givenResult.asyncValue = value;
            });

            [[expectFutureValue(actionCallback) shouldEventually] beCalledWithValue:value result:givenResult onMainThread:YES];

            NSNumber* error = [[NSNumber alloc] initWithInteger:7];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dependentResult.asyncError = error;
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
            givenResult.asyncValue = value;

            [[theValue(funcCallCount) should] equal:theValue(1)];
            [[theValue(funcState) should] equal:theValue(AsyncResultStateSuccess)];
            [[value should] equal:value];
            [[theValue(funcOnMainThread) should] equal:theValue(YES)];

            value = [[NSNumber alloc] initWithInteger:2];
            dependentResult.asyncValue = value;

            [[counter should] beCalledWithValue:value result:finalResult onMainThread:YES];
        });

        it(@"should chain asynchronously then get an error result", ^{
            AsyncResult* finalResult = asyncChainUsingFunction(givenResult, actionFunction);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                givenResult.asyncValue = value;
            });

            [[expectFutureValue(theValue(funcCallCount)) shouldEventually] equal:theValue(1)];
            [[theValue(funcState) should] equal:theValue(AsyncResultStateSuccess)];
            [[value should] equal:value];
            [[theValue(funcOnMainThread) should] equal:theValue(NO)];

            NSNumber* error = [[NSNumber alloc] initWithInteger:7];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dependentResult.asyncError = error;
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
                givenResult.asyncValue = value;
            });

            [[expectFutureValue(theValue(funcCallCount)) shouldEventually] equal:theValue(1)];
            [[theValue(funcState) should] equal:theValue(AsyncResultStateSuccess)];
            [[value should] equal:value];
            [[theValue(funcOnMainThread) should] equal:theValue(YES)];

            value = [[NSNumber alloc] initWithInteger:2];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dependentResult.asyncValue = value;
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithValue:value result:finalResult onMainThread:NO];
        });

        it(@"should chain asynchronously then get an error result", ^{
            AsyncResult* finalResult = asyncChainOnMainThreadUsingFunction(givenResult, actionFunction);
            asyncWait(finalResult, counter.block);

            NSNumber* value = [[NSNumber alloc] initWithInteger:1];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                givenResult.asyncValue = value;
            });

            [[expectFutureValue(theValue(funcCallCount)) shouldEventually] equal:theValue(1)];
            [[theValue(funcState) should] equal:theValue(AsyncResultStateSuccess)];
            [[value should] equal:value];
            [[theValue(funcOnMainThread) should] equal:theValue(YES)];

            NSNumber* error = [[NSNumber alloc] initWithInteger:7];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dependentResult.asyncError = error;
            });

            [[expectFutureValue(counter) shouldEventually] beCalledWithError:error result:finalResult onMainThread:NO];
        });
    });
    
});

SPEC_END
