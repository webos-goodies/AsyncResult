AsyncResult
===========

AsyncResult is an Objective-C port of [goog.result], an asynchronous module of Google Closure Library. It provides an easy and consistent way to handle asynchronous operations.

A method or a function that initiates an asynchronous operation can return an AsyncResult object as a return value like a synchoronous operation. A caller can regist a handler block to retrieve the result value of the asynchoronous operation when it is resolved.

Features
--------

Although AsyncResult is a variant of implementation of [Promise pattern], it has some original characteristics.

 * Objective-C friendly syntax. No method chaining.
 * Defined as a protocol. You can integrate AsyncResult functionalities to your classes.
 * A value of an operation can be modified with asyncTransform.
 * Categories to add AsyncResult functionalities to exisiting cocoa claasses.
 * Contains metadata (like response headers) along with a value of an operation.
 * You can handle a result on main thread regardless of where it is resolved on.

Requirements
------------

 * Xcode 4.5 or above
 * iOS 5.1 or above
 * ARC should be enabled (I beleve libAsyncResult.a can be used with non-ARC project, but not tested)

Using in your projects
----------------------

The best way to get AsyncResult is by cloning the git repository: `git clone git://github.com/webos-goodies/AsyncResult.git`

Then following these steps.

 * Bring in AsyncResult.xcodeproj into your workspace.
 * Add libAsyncResult.a into **Link Binary With Libraries**.
 * Add `$(SOURCE_ROOT)/AsyncResult/AsyncResult` into **User Header Search Paths**.
 * Add `-ObjC` into **Other Linker Flags**.

Documentation
-------------

See the [Wiki pages] (https://github.com/webos-goodies/AsyncResult/wiki) .

Examples
--------

With AsyncResult, An http request and various response handlings can be done as following.

```objective-c
#import "NSURLConnection+AsyncResult.h"

// ...

// initiate a request
NSURL* url = [NSURL URLWithString:@"http://example.com/"];
NSURLRequest* request = [NSURLRequest requestWithURL:url];
NSURLConnection* connection = [NSURLConnection connectionWithRequest:request];

// retrieve raw response from NSURLConnection directly.
asyncWaitSuccess(connection, ^(NSData* body, id<AsyncResult> result) {
  NSURLResponse* response = [result.asyncMetadata objectForKey:@"response"];
  // ...
});

// retrieve json response with asyncResponseJson property.
id<AsyncResult> jsonResult = connection.asyncResponseJson;

// then extract "msg" member of json response.
id<AsyncResult> msgResult = asyncTransform(jsonResult,
  ^id(NSDictionary* json, NSDictionary* metadata) {
    return [json objectForKey:@"msg"];
  });

// handle the result on main thread.
asyncWaitSuccessOnMainThread(msgResult,
  ^(NSString* msg, id<AsyncResult> result) {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Message"
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"Cancel"
                                           otherButtonTitle:nil];
  });

// initiate a subsequent request.
id<AsyncResult> secondResult = asyncChainOnMainThread(jsonResult,
  ^id<AsyncResult>(id<AsyncResult> result) {
    NSDictionary* json = result.asyncValue;
    NSURL* url = [NSURL urlWithString:[json objectForKey:@"next"]];
    NSRequest* request = [NSRequest requestWithURL:url];
    return [NSURLConnection connectionWithRequest:request].jsonResponse;
  });
asyncWaitSuccess(secondResult, ^(NSDictionary* json, id<AsyncResult> result) {
  // ...
});

// handle an error of both the first and the second request.
// asyncChain will pass the error of the first result to the second.
asyncWaitErrorOnMainThread(secondRequest, ^(id<AsyncResult> result) {
  NSString* msg;
  if(result.asyncIsCanceled) {
    msg = @"Canceled";
  } else {
    NSError* error = result.asyncError;
    msg = [error localizedDescription];
  }
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                  message:msg
                                                 delegate:nil
                                        cancelButtonTitle:@"Cancel"
                                         otherButtonTitle:nil];
});
```

Like NSURLConnection, AsyncResult categories are provided for these classes.

 * [UIAlertView] (https://github.com/webos-goodies/AsyncResult/wiki/UIAlertView-category)
 * [UIActionSheet] (https://github.com/webos-goodies/AsyncResult/wiki/UIActionSheet-category)
 * [ACAccountStore] (https://github.com/webos-goodies/AsyncResult/wiki/ACAccountStore-category)

You can integrate AsyncResult functionalities into any class using category or subclassing.

```objective-c
#import "AsyncResult.h"

@interface YourClass : NSObject<AsyncResult>
@end

@implement YourClass {
  AsyncResult* _result;
}

- (id)init {
  self = [super init];
  if(self) {
    _result = [[AsyncResult alloc] init];
  }
  return self;
}

// you should call this method when the value is determined.
- (void)resolve:(id)value {
  [_result setAsyncValue:value withMetadata:@{}];
}

// you should call this method when something goes wrong.
- (void)error:(id)error {
  [_result setAsyncError:error withMetadata:@{}];
}

#pragma mark AsyncResult protocol

// You can simply delegate almost all operation to private result object.
- (id)asyncValue { return _result.asyncValue; }
- (id)asyncError { return _result.asyncError; }
- (NSDictionary*)asyncMetadata { return _result.asyncMetadata; }
- (NSInteger)asyncState { return _result.asyncState; }
- (BOOL)asyncIsCanceled { return _result.asyncIsCanceled; }

- (BOOL)asyncCancel {
  BOOL canceled = [_result asyncCancel];
  // Do something if needed.
  return canceled;
}

- (void)asyncWait:(void(^)(id<AsyncResult> result))handler {
  return [_result asyncWait:handler];
}

@end
```

License
-------

AsyncResult is an open source software distributed under [Apache License 2.0]. See LICENSE file.


[goog.result]: http://closure-library.googlecode.com/svn/docs/namespace_goog_result.html
[Promise pattern]: http://wiki.commonjs.org/wiki/Promises
[Apache License 2.0]: http://www.apache.org/licenses/LICENSE-2.0
