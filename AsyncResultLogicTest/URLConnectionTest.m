#import "Kiwi.h"
#import "HandlerMock.h"
#import "AsyncResultInjector.h"
#import "NSURLConnection+AsyncResult.h"

static NSString* responseBody;
static NSInteger statusCode;
static NSError*  requestError;

@interface TestURLProtocol : NSURLProtocol
@end

@implementation TestURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return [[[request URL] scheme] isEqualToString:@"test"];
}
+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}
- (void)startLoading
{
    if(!requestError) {
        NSData* body1 = [[responseBody substringToIndex:  [responseBody length] / 2] dataUsingEncoding:NSUTF8StringEncoding];
        NSData* body2 = [[responseBody substringFromIndex:[responseBody length] / 2] dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary* headers = @{
                @"Content-Type": @"text/plain",
                @"Content-Length": [[NSString alloc] initWithFormat:@"%d", [body1 length] + [body2 length]]
            };
            NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:statusCode HTTPVersion:@"1.1" headerFields:headers];
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.client URLProtocol:self didLoadData:body1];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.client URLProtocol:self didLoadData:body2];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.client URLProtocolDidFinishLoading:self];
        });
    } else {
        [self.client URLProtocol:self didFailWithError:requestError];
    }
}
- (void)stopLoading
{
}
@end

static id extractDelegate(NSURLConnection* connection) {
    return [AsyncResultInjector getValueForKey:@"privateResult" from:connection];
}

SPEC_BEGIN(NSURLConnectionSpec)

describe(@"NSURLConnection", ^{
    registerMatchers(@"AR");

    __block HandlerMock*  handler  = nil;
    __block NSURLRequest* request  = nil;

    beforeAll(^{
        [NSURLProtocol registerClass:[TestURLProtocol class]];
    });

    beforeEach(^{
        handler = [[HandlerMock alloc] init];
        request = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"test://localhost/"]];
    });

    afterEach(^{
        handler      = [handler clear];
        request      = nil;
        responseBody = nil;
        requestError = nil;
    });

    afterAll(^{
        [NSURLProtocol unregisterClass:[TestURLProtocol class]];
    });

    context(@"direct result", ^{

        it(@"should contain a response on success", ^{
            responseBody = @"Hello World!";
            statusCode   = 200;
            NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request];
            asyncWait(connection, handler.block);

            [[expectFutureValue(handler) shouldEventuallyBeforeTimingOutAfter(3.0)] beCalled];

            HandlerMock*       lastCall = handler.lastCall;
            NSDictionary*      value    = lastCall.value;
            NSHTTPURLResponse* response = [value objectForKey:@"response"];
            [[theValue(lastCall.result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
            [[response should] isKindOfClass:[NSHTTPURLResponse class]];
            [[theValue(response.statusCode) should] equal:theValue(200)];
            [[[[NSString alloc] initWithData:[value objectForKey:@"body"] encoding:NSUTF8StringEncoding] should] equal:@"Hello World!"];
            [[theValue([connection asyncCancel]) should] beNo];
        });

        it(@"should be canceled when the connection is canceled", ^{
            responseBody = @"Hello World!";
            statusCode   = 200;
            NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request startImmediately:YES];
            asyncWait(connection, handler.block);
            [connection asyncCancel];
            [[handler should] beCalled];
            [[theValue(connection.asyncIsCanceled) should] beYes];
            [[theValue([connection asyncCancel]) should] beNo];
        });

        it(@"should contain an error when the connection is failed", ^{
            requestError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:-1004 userInfo:@{}];
            NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request];
            asyncWait(connection, handler.block);

            [[expectFutureValue(handler) shouldEventually] beCalled];

            [[theValue(connection.asyncState) should] equal:theValue(AsyncResultStateError)];
            NSError* error = [connection.asyncError objectForKey:@"error"];
            [[error should] beKindOfClass:[NSError class]];
            [[error.domain should] equal:requestError.domain];
            [[theValue(error.code) should] equal:theValue(requestError.code)];
        });

    });

    context(@"http result", ^{

        it(@"should contain a response body on success", ^{
            responseBody = @"Hello World!";
            statusCode   = 200;
            NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request];
            id<AsyncResult>  result     = connection.asyncResponseText;
            asyncWait(result, handler.block);
            [[expectFutureValue(handler) shouldEventuallyBeforeTimingOutAfter(3.0)] beCalledWithValue:@"Hello World!" onMainThread:YES];
            [[theValue(connection.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        });

        it(@"should success with specified status code", ^{
            responseBody = @"Hello World!";
            statusCode   = 401;
            id<AsyncResult> result = [[[NSURLConnection alloc] initWithRequest:request] asyncResponseTextOnStatuses:@[@401]];
            asyncWait(result, handler.block);
            [[expectFutureValue(handler) shouldEventually] beCalledWithValue:@"Hello World!" onMainThread:YES];
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        });

        it(@"should contain a response on error response", ^{
            responseBody = @"Hello World!";
            statusCode   = 202;
            id<AsyncResult> result = [[NSURLConnection alloc] initWithRequest:request].asyncResponseText;
            asyncWait(result, handler.block);

            [[expectFutureValue(handler) shouldEventually] beCalled];

            HandlerMock*       lastCall = handler.lastCall;
            NSDictionary*      value    = lastCall.value;
            NSHTTPURLResponse* response = [value objectForKey:@"response"];
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
            [[response should] isKindOfClass:[NSHTTPURLResponse class]];
            [[theValue(response.statusCode) should] equal:theValue(202)];
            [[[[NSString alloc] initWithData:[value objectForKey:@"body"] encoding:NSUTF8StringEncoding] should] equal:@"Hello World!"];
        });

        it(@"should fail with unspecified status code", ^{
            responseBody = @"Hello World!";
            statusCode   = 200;
            id<AsyncResult> result = [[[NSURLConnection alloc] initWithRequest:request] asyncResponseTextOnStatuses:@[@401]];
            asyncWait(result, handler.block);

            [[expectFutureValue(handler) shouldEventually] beCalled];

            HandlerMock*       lastCall = handler.lastCall;
            NSDictionary*      value    = lastCall.value;
            NSHTTPURLResponse* response = [value objectForKey:@"response"];
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
            [[response should] isKindOfClass:[NSHTTPURLResponse class]];
            [[theValue(response.statusCode) should] equal:theValue(200)];
            [[[[NSString alloc] initWithData:[value objectForKey:@"body"] encoding:NSUTF8StringEncoding] should] equal:@"Hello World!"];
        });

        it(@"should be canceled when the connection is canceled", ^{
            responseBody = @"Hello World!";
            statusCode   = 200;
            NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request];
            id<AsyncResult>  result     = connection.asyncResponseText;
            asyncWait(result, handler.block);

            [connection asyncCancel];

            [[expectFutureValue(handler) shouldEventually] beCalled];
            [[theValue(result.asyncIsCanceled) should] beYes];
        });

        it(@"should contain an error when the connection is failed", ^{
            requestError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:-1004 userInfo:@{}];
            id<AsyncResult> result = [NSURLConnection connectionWithRequest:request].asyncResponseText;
            asyncWait(result, handler.block);

            [[expectFutureValue(handler) shouldEventually] beCalled];

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
            NSError* error = [result.asyncError objectForKey:@"error"];
            [[error should] beKindOfClass:[NSError class]];
            [[error.domain should] equal:error.domain];
            [[theValue(error.code) should] equal:theValue(error.code)];
        });

    });

    context(@"json result", ^{

        it(@"should contain a response body on success", ^{
            responseBody = @"[\"Hello World!\"]";
            statusCode   = 200;
            NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request];
            id<AsyncResult>  result     = connection.asyncResponseJson;
            asyncWait(result, handler.block);
            [[expectFutureValue(handler) shouldEventually] beCalledWithValue:@[@"Hello World!"] onMainThread:YES];
            [[theValue(connection.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        });


        it(@"should success with specified status code", ^{
            responseBody = @"[\"Hello World!\"]";
            statusCode   = 401;
            id<AsyncResult> result = [[[NSURLConnection alloc] initWithRequest:request] asyncResponseJsonOnStatuses:@[@401]];
            asyncWait(result, handler.block);
            [[expectFutureValue(handler) shouldEventually] beCalledWithValue:@[@"Hello World!"] onMainThread:YES];
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
        });

        it(@"should contain a response on error response", ^{
            responseBody = @"[\"Hello World!\"]";
            statusCode   = 202;
            id<AsyncResult> result = [[NSURLConnection alloc] initWithRequest:request].asyncResponseJson;
            asyncWait(result, handler.block);

            [[expectFutureValue(handler) shouldEventually] beCalled];

            HandlerMock*       lastCall = handler.lastCall;
            NSDictionary*      value    = lastCall.value;
            NSHTTPURLResponse* response = [value objectForKey:@"response"];
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
            [[response should] isKindOfClass:[NSHTTPURLResponse class]];
            [[theValue(response.statusCode) should] equal:theValue(202)];
            [[[[NSString alloc] initWithData:[value objectForKey:@"body"] encoding:NSUTF8StringEncoding] should] equal:@"[\"Hello World!\"]"];
        });

        it(@"should fail with unspecified status code", ^{
            responseBody = @"[\"Hello World!\"]";
            statusCode   = 200;
            id<AsyncResult> result = [[[NSURLConnection alloc] initWithRequest:request] asyncResponseJsonOnStatuses:@[@401]];
            asyncWait(result, handler.block);

            [[expectFutureValue(handler) shouldEventually] beCalled];

            HandlerMock*       lastCall = handler.lastCall;
            NSDictionary*      value    = lastCall.value;
            NSHTTPURLResponse* response = [value objectForKey:@"response"];
            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
            [[response should] isKindOfClass:[NSHTTPURLResponse class]];
            [[theValue(response.statusCode) should] equal:theValue(200)];
            [[[[NSString alloc] initWithData:[value objectForKey:@"body"] encoding:NSUTF8StringEncoding] should] equal:@"[\"Hello World!\"]"];
        });

        it(@"should be canceled when the connection is canceled", ^{
            responseBody = @"[\"Hello World!\"]";
            statusCode   = 200;
            NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request];
            id<AsyncResult>  result     = connection.asyncResponseJson;
            asyncWait(result, handler.block);

            [connection asyncCancel];

            [[expectFutureValue(handler) shouldEventually] beCalled];
            [[theValue(result.asyncIsCanceled) should] beYes];
        });

        it(@"should contain an error when the connection is failed", ^{
            requestError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:-1004 userInfo:@{}];
            id<AsyncResult> result = [NSURLConnection connectionWithRequest:request].asyncResponseJson;
            asyncWait(result, handler.block);

            [[expectFutureValue(handler) shouldEventually] beCalled];

            [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
            NSError* error = [result.asyncError objectForKey:@"error"];
            [[error should] beKindOfClass:[NSError class]];
            [[error.domain should] equal:error.domain];
            [[theValue(error.code) should] equal:theValue(error.code)];
        });

    });

});

SPEC_END
