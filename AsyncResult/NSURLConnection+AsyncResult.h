//
//  NSURLConnection+AsyncResult.h
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/10/06.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncResult.h"

@interface NSURLConnection (AsyncResult) <AsyncResult>

// Block version of delegation methods.
@property (nonatomic) void(^delegateDidReceiveResponse)(NSURLConnection* connection, NSURLResponse* response);
@property (nonatomic) void(^delegateDidReceiveData)(NSURLConnection* connection, NSData* data);
@property (nonatomic) void(^delegateDidSendBodyData)(NSURLConnection* connection, NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite);
@property (nonatomic) void(^delegateDidFinishLoading)(NSURLConnection* connection);
@property (nonatomic) NSURLRequest*(^delegateWillSendRequestRedirectResponse)(NSURLConnection* connection, NSURLRequest* request, NSURLResponse* response);
@property (nonatomic) NSCachedURLResponse*(^delegateWillCacheResponse)(NSURLConnection* connection, NSCachedURLResponse* cachedResponse);
@property (nonatomic, readonly) id<AsyncResult> asyncResponseText;
@property (nonatomic, readonly) id<AsyncResult> asyncResponseJson;

+ (NSURLConnection*)connectionWithRequest:(NSURLRequest*)request;
- (id)initWithRequest:(NSURLRequest*)request;
- (id)initWithRequest:(NSURLRequest*)request startImmediately:(BOOL)startImmediately;
- (id<AsyncResult>)asyncResponseTextOnStatusSet:(NSIndexSet*)statusSet;
- (id<AsyncResult>)asyncResponseTextOnStatuses:(NSArray*)statuses;
- (id<AsyncResult>)asyncResponseJsonOnStatusSet:(NSIndexSet*)statusSet;
- (id<AsyncResult>)asyncResponseJsonOnStatuses:(NSArray*)statuses;

@end
