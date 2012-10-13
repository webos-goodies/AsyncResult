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

// Initialization
+ (NSURLConnection*)connectionWithRequest:(NSURLRequest*)request;
- (id)initWithRequest:(NSURLRequest*)request;
- (id)initWithRequest:(NSURLRequest*)request startImmediately:(BOOL)startImmediately;

// Retrieve a response body in specific format.
@property (nonatomic, readonly) id<AsyncResult> asyncResponseText;
@property (nonatomic, readonly) id<AsyncResult> asyncResponseJson;
- (id<AsyncResult>)asyncResponseTextOnStatusSet:(NSIndexSet*)statusSet;
- (id<AsyncResult>)asyncResponseTextOnStatuses:(NSArray*)statuses;
- (id<AsyncResult>)asyncResponseJsonOnStatusSet:(NSIndexSet*)statusSet;
- (id<AsyncResult>)asyncResponseJsonOnStatuses:(NSArray*)statuses;

@end
