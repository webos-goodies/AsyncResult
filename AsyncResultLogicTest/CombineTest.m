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

SPEC_BEGIN(CombineSpec)

describe(@"Function", ^{
    registerMatchers(@"AR");

    __block AsyncResult* result1;
    __block AsyncResult* result2;
    __block AsyncResult* result3;
    __block AsyncResult* result4;
    __block HandlerMock* resultCallback;
    __block AsyncResult* combinedResult;
    __block AsyncResult* successCombinedResult;

    void (^resolveAllGivenResultsToSuccess)() = ^{
        NSNumber* value = [[NSNumber alloc] initWithInteger:1];
        [result1 setAsyncValue:value withMetadata:nil];
        [result2 setAsyncValue:value withMetadata:nil];
        [result3 setAsyncValue:value withMetadata:nil];
        [result4 setAsyncValue:value withMetadata:nil];
    };

    void (^resolveAllGivenResultsToError)() = ^{
        NSNumber* error = [[NSNumber alloc] initWithInteger:2];
        [result1 setAsyncError:error withMetadata:nil];
        [result2 setAsyncError:error withMetadata:nil];
        [result3 setAsyncError:error withMetadata:nil];
        [result4 setAsyncError:error withMetadata:nil];
    };

    void (^resolveSomeGivenResultsToSuccess)() = ^{
        NSNumber* value = [[NSNumber alloc] initWithInteger:1];
        NSNumber* error = [[NSNumber alloc] initWithInteger:2];
        [result1 setAsyncError:error withMetadata:nil];
        [result2 setAsyncValue:value withMetadata:nil];
        [result3 setAsyncValue:value withMetadata:nil];
        [result4 setAsyncValue:value withMetadata:nil];
    };

    beforeEach(^{
        result1 = [[AsyncResult alloc] init];
        result2 = [[AsyncResult alloc] init];
        result3 = [[AsyncResult alloc] init];
        result4 = [[AsyncResult alloc] init];

        combinedResult = asyncCombine(@[result1, result2, result3, result4]);

        successCombinedResult = asyncCombineSuccess(@[result1, result2, result3, result4]);

        resultCallback = [[HandlerMock alloc] init];
    });

    afterEach(^{
        result1 = nil;
        result2 = nil;
        result3 = nil;
        result4 = nil;
        combinedResult = nil;
        successCombinedResult = nil;
        resultCallback = [resultCallback clear];
    });


#pragma mark - asyncCombine tests

    context(@"asyncCombine", ^{
        it(@"should success when all results success", ^{
            asyncWait(combinedResult, resultCallback.block);

            resolveAllGivenResultsToSuccess();

            NSArray* value = @[result1, result2, result3, result4];
            [[resultCallback should] beCalledWithValue:value result:combinedResult onMainThread:YES];
        });

        it(@"should success asynchronously when all results success", ^{
            asyncWait(combinedResult, resultCallback.block);

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolveAllGivenResultsToSuccess();
            });

            NSArray* value = @[result1, result2, result3, result4];
            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithValue:value result:combinedResult onMainThread:NO];
        });

        it(@"should success when all results fail", ^{
            asyncWait(combinedResult, resultCallback.block);

            resolveAllGivenResultsToError();

            NSArray* value = @[result1, result2, result3, result4];
            [[resultCallback should] beCalledWithValue:value result:combinedResult onMainThread:YES];
        });

        it(@"should success asynchronously when all results fail", ^{
            asyncWait(combinedResult, resultCallback.block);

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolveAllGivenResultsToError();
            });

            NSArray* value = @[result1, result2, result3, result4];
            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithValue:value result:combinedResult onMainThread:NO];
        });

        it(@"should success when some results success", ^{
            asyncWait(combinedResult, resultCallback.block);

            resolveSomeGivenResultsToSuccess();

            NSArray* value = @[result1, result2, result3, result4];
            [[resultCallback should] beCalledWithValue:value result:combinedResult onMainThread:YES];
        });

        it(@"should success asynchronously when some results success", ^{
            asyncWait(combinedResult, resultCallback.block);

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolveSomeGivenResultsToSuccess();
            });

            NSArray* value = @[result1, result2, result3, result4];
            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithValue:value result:combinedResult onMainThread:NO];
        });
    });


#pragma mark - asyncCombineSuccess tests

    context(@"asyncCombineSuccess", ^{
        it(@"should success when all results success", ^{
            asyncWait(successCombinedResult, resultCallback.block);

            resolveAllGivenResultsToSuccess();

            NSArray* value = @[result1, result2, result3, result4];
            [[resultCallback should] beCalledWithValue:value result:successCombinedResult onMainThread:YES];
        });

        it(@"should success asynchronously when all results success", ^{
            asyncWait(successCombinedResult, resultCallback.block);

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolveAllGivenResultsToSuccess();
            });

            NSArray* value = @[result1, result2, result3, result4];
            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithValue:value result:successCombinedResult onMainThread:NO];
        });

        it(@"should fail when all results fail", ^{
            asyncWait(successCombinedResult, resultCallback.block);

            resolveAllGivenResultsToError();

            NSArray* value = @[result1, result2, result3, result4];
            [[resultCallback should] beCalledWithError:value result:successCombinedResult onMainThread:YES];
        });

        it(@"should fail asynchronously when all results fail", ^{
            asyncWait(successCombinedResult, resultCallback.block);

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolveAllGivenResultsToError();
            });

            NSArray* value = @[result1, result2, result3, result4];
            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithError:value result:successCombinedResult onMainThread:NO];
        });

        it(@"should fail when some results success", ^{
            asyncWait(successCombinedResult, resultCallback.block);

            resolveSomeGivenResultsToSuccess();

            NSArray* value = @[result1, result2, result3, result4];
            [[resultCallback should] beCalledWithError:value result:successCombinedResult onMainThread:YES];
        });

        it(@"should fail asynchronously when some results success", ^{
            asyncWait(successCombinedResult, resultCallback.block);

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                resolveSomeGivenResultsToSuccess();
            });

            NSArray* value = @[result1, result2, result3, result4];
            [[expectFutureValue(resultCallback) shouldEventually] beCalledWithError:value result:successCombinedResult onMainThread:NO];
        });
    });
});

SPEC_END
