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
        [[theValue([AsyncResultUndefined isUndefined:result.asyncValue]) should] beYes];

        asyncWait(result, waitCallback.block);
        asyncWaitSuccess(result, waitOnSuccessCallback.blockWithValue);
        asyncWaitError(result, waitOnErrorCallback.block);

        NSNumber* value = [[NSNumber alloc] initWithInteger:1];
        [result setAsyncValue:value withMetadata:nil];

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
                    [result setAsyncValue:value withMetadata:nil];
                }
            });

            [[theValue([AsyncResultUndefined isUndefined:result.asyncValue]) should] beYes];
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
            [result setAsyncValue:value withMetadata:nil];
        });

        [[expectFutureValue(waitCallback) shouldEventually] beCalledWithResult:result onMainThread:YES];
        [[expectFutureValue(waitOnSuccessCallback) shouldEventually] beCalledWithValue:value result:result onMainThread:YES];
        [[waitOnErrorCallback shouldNot] beCalled];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        [[result.asyncValue should] equal:value];
    });
    
    it(@"should fail synchronously", ^{
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
        [[theValue([AsyncResultUndefined isUndefined:result.asyncValue]) should] beYes];

        asyncWait(result, waitCallback.block);
        asyncWaitSuccess(result, waitOnSuccessCallback.blockWithValue);
        asyncWaitError(result, waitOnErrorCallback.block);

        [result setAsyncError:@"failed" withMetadata:nil];

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[theValue([AsyncResultUndefined isUndefined:result.asyncValue]) should] beYes];
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
                    [result setAsyncError:@"failed" withMetadata:nil];
                }
            });

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
            [[theValue([AsyncResultUndefined isUndefined:result.asyncValue]) should] beYes];

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
        [[theValue([AsyncResultUndefined isUndefined:result.asyncValue]) should] beYes];
        [[result.asyncError should] equal:@"failed"];
    });

    it(@"should fail then dispatch handlers to main thread", ^{
        asyncWaitOnMainThread(result, waitCallback.block);
        asyncWaitSuccessOnMainThread(result, waitOnSuccessCallback.blockWithValue);
        asyncWaitErrorOnMainThread(result, waitOnErrorCallback.block);

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [result setAsyncError:@"failed" withMetadata:nil];
        });

        [[expectFutureValue(waitCallback) shouldEventually] beCalledWithResult:result onMainThread:YES];
        [[expectFutureValue(waitOnErrorCallback) shouldEventually] beCalledWithResult:result onMainThread:YES];
        [[waitOnSuccessCallback shouldNot] beCalled];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[theValue([AsyncResultUndefined isUndefined:result.asyncValue]) should] beYes];
        [[result.asyncError should] equal:@"failed"];
    });
});

SPEC_END
