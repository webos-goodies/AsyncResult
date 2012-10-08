//
//  NSURLConnection+AsyncResult.m
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/10/06.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import "NSURLConnection+AsyncResult.h"
#import "AsyncResultInjector.h"

static NSIndexSet* indexSetFromArray(NSArray* array)
{
    NSMutableIndexSet* indexSet = [[NSMutableIndexSet alloc] init];
    for(NSNumber* number in array) {
        if([number respondsToSelector:@selector(unsignedIntegerValue)]) {
            [indexSet addIndex:number.unsignedIntegerValue];
        }
    }
    return indexSet;
}


#pragma mark - AsyncResultURLConnectionDataDelegate

@interface AsyncResultURLConnectionDataDelegate : AsyncResult<NSURLConnectionDataDelegate>
@end

@implementation AsyncResultURLConnectionDataDelegate {
    NSURLResponse* _response;
    NSMutableData* _body;
}

- (id)init
{
    self = [super init];
    if(self) {
        _response   = nil;
        _body       = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _response = response;
    [_body setLength:0];
    void(^block)(NSURLConnection*, NSURLResponse*) = connection.delegateDidReceiveResponse;
    if(block){ block(connection, response); }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_body appendData:data];
    void(^block)(NSURLConnection*, NSData*) = connection.delegateDidReceiveData;
    if(block){ block(connection, data); }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    void(^block)(NSURLConnection*, NSInteger, NSInteger, NSInteger) = connection.delegateDidSendBodyData;
    if(block){ block(connection, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite); }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.asyncValue = @{ @"response":_response, @"body":_body };
    void(^block)(NSURLConnection*) = connection.delegateDidFinishLoading;
    if(block){ block(connection); }
}

- (NSURLRequest*)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    NSURLRequest*(^block)(NSURLConnection*, NSURLRequest*, NSURLResponse*) = connection.delegateWillSendRequestRedirectResponse;
    return block ? block(connection, request, response) : request;
}

- (NSCachedURLResponse*)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    NSCachedURLResponse*(^block)(NSURLConnection*, NSCachedURLResponse* cachedResponse) = connection.delegateWillCacheResponse;
    return block ? block(connection, cachedResponse) : nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.asyncError = @{ @"error":error };
}

@end


#pragma mark - NSURLConnection

@implementation NSURLConnection (AsyncResult)

+ (NSURLConnection*)connectionWithRequest:(NSURLRequest*)request
{
    return [[NSURLConnection alloc] initWithRequest:request];
}

- (id)initWithRequest:(NSURLRequest*)request
{
    self = [self initWithRequest:request startImmediately:YES];
    return self;
}

- (id)initWithRequest:(NSURLRequest*)request startImmediately:(BOOL)startImmediately
{
    AsyncResultURLConnectionDataDelegate* delegate = [[AsyncResultURLConnectionDataDelegate alloc] init];
    self = [self initWithRequest:request delegate:delegate startImmediately:startImmediately];
    if(self) {
        [AsyncResultInjector setValue:delegate forKey:@"privateResult" to:self];
        [AsyncResultInjector setValue:delegate forKey:@"result" to:self];
    }
    return self;
}

- (id<AsyncResult>)asyncResponseTextOnStatusSet:(NSIndexSet *)statusSet
{
    statusSet = [statusSet copy];
    return asyncChain(self, ^id<AsyncResult>(id<AsyncResult> result) {

        AsyncResult* secondResult = [[AsyncResult alloc] init];
        if(result.asyncState == AsyncResultStateSuccess) {

            NSHTTPURLResponse* response = [result.asyncValue objectForKey:@"response"];
            if([response respondsToSelector:@selector(statusCode)] &&
               [statusSet containsIndex:response.statusCode])
            {
                secondResult.asyncValue = [[NSString alloc] initWithData:[result.asyncValue objectForKey:@"body"] encoding:NSUTF8StringEncoding];
            } else {
                secondResult.asyncError = result.asyncValue;
            }

        } else {
            secondResult.asyncError = result.asyncError;
        }

        return secondResult;
    });
}

- (id<AsyncResult>)asyncResponseTextOnStatuses:(NSArray *)statuses
{
    return [self asyncResponseTextOnStatusSet:indexSetFromArray(statuses)];
}

- (id<AsyncResult>)asyncResponseText
{
    return [self asyncResponseTextOnStatusSet:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(200, 2)]];
}

- (id<AsyncResult>)asyncResponseJsonOnStatusSet:(NSIndexSet *)statusSet
{
    statusSet = [statusSet copy];
    return asyncChain(self, ^id<AsyncResult>(id<AsyncResult> result) {

        AsyncResult* secondResult = [[AsyncResult alloc] init];
        if(result.asyncState == AsyncResultStateSuccess) {

            NSHTTPURLResponse* response = [result.asyncValue objectForKey:@"response"];
            id body = [result.asyncValue objectForKey:@"body"];
            if([response respondsToSelector:@selector(statusCode)] &&
               [body isKindOfClass:[NSData class]] &&
               [statusSet containsIndex:response.statusCode])
            {
                NSError* error;
                id json = [NSJSONSerialization JSONObjectWithData:body options:0 error:&error];
                if(error) {
                    NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:result.asyncValue];
                    [dict setObject:error forKey:@"error"];
                    secondResult.asyncError = dict;
                } else {
                    secondResult.asyncValue = json;
                }
            } else {
                secondResult.asyncError = result.asyncValue;
            }

        } else {
            secondResult.asyncError = result.asyncError;
        }

        return secondResult;
    });
}

- (id<AsyncResult>)asyncResponseJsonOnStatuses:(NSArray *)statuses
{
    return [self asyncResponseJsonOnStatusSet:indexSetFromArray(statuses)];
}

- (id<AsyncResult>)asyncResponseJson
{
    return [self asyncResponseJsonOnStatusSet:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(200, 2)]];
}

- (id)asyncValue
{
    return [[AsyncResultInjector getValueForKey:@"result" from:self] asyncValue];
}

- (id)asyncError
{
    return [[AsyncResultInjector getValueForKey:@"result" from:self] asyncError];
}

- (NSInteger)asyncState
{
    return [[AsyncResultInjector getValueForKey:@"result" from:self] asyncState];
}

- (BOOL)asyncIsCanceled
{
    return [[AsyncResultInjector getValueForKey:@"result" from:self] asyncIsCanceled];
}

- (BOOL)asyncCancel
{
    BOOL canceled = [[AsyncResultInjector getValueForKey:@"result" from:self] asyncCancel];
    [self cancel];
    return canceled;
}

- (void)asyncWait:(void(^)(id<AsyncResult> result))handler
{
    [[AsyncResultInjector getValueForKey:@"result" from:self] asyncWait:handler];
}

#define DEFINE_PROPERTY(name, type) \
- type delegate##name { return [AsyncResultInjector getValueForKey:@"delegate" #name from:self]; }\
- (void)setDelegate##name:type value { [AsyncResultInjector setValue:value forKey:@"delegate" #name to:self]; }

DEFINE_PROPERTY(DidReceiveResponse, (void(^)(NSURLConnection*, NSURLResponse*)))
DEFINE_PROPERTY(DidReceiveData,     (void(^)(NSURLConnection*, NSData*)))
DEFINE_PROPERTY(DidSendBodyData,    (void(^)(NSURLConnection*, NSInteger, NSInteger, NSInteger)))
DEFINE_PROPERTY(DidFinishLoading,   (void(^)(NSURLConnection*)))
DEFINE_PROPERTY(WillSendRequestRedirectResponse, (NSURLRequest*(^)(NSURLConnection*, NSURLRequest*, NSURLResponse*)))
DEFINE_PROPERTY(WillCacheResponse,  (NSCachedURLResponse*(^)(NSURLConnection*, NSCachedURLResponse*)))

@end
