//
//  HandlerMock.m
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/09/30.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import "HandlerMock.h"
#import "KWFormatter.h"


#pragma mark - HandlerMock

@implementation HandlerMock {
    id (^_block)(id result);
    NSMutableArray* _calls;
    id _value;
    NSDictionary* _metadata;
    id<AsyncResult> _result;
    BOOL onMainThread;
}

@synthesize calls    = _calls;
@synthesize value    = _value;
@synthesize metadata = _metadata;
@synthesize result   = _result;
@synthesize onMainThread = _onMainThread;


- (id)initWithValue:(id)value metadata:(NSDictionary*)metadata result:(id<AsyncResult>)result block:(id (^)(id result)) block
{
    self = [super init];
    if (self) {
        _block    = block;
        _calls    = nil;
        _value    = value;
        _metadata = metadata;
        _result   = result;
        _onMainThread = [NSThread isMainThread];
    }
    return self;
}

- (id)initWithValue:(id)value metadata:(NSDictionary*)metadata result:(id<AsyncResult>)result
{
    self = [self initWithValue:value metadata:metadata result:result block:^id(id result) {
        return nil;
    }];
    return self;
}

- (id)init
{
    self = [self initWithValue:nil metadata:nil result:nil];
    if (self) {
        _calls = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithBlock:(id (^)(id))block
{
    self = [self initWithValue:nil metadata:nil result:nil block:block];
    if (self) {
        _calls = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)clear {
    if(_calls) {
        for(HandlerMock* item in _calls) {
            [item clear];
        }
    }
    _block    = nil;
    _calls    = nil;
    _value    = nil;
    _metadata = nil;
    _result   = nil;
    _onMainThread = NO;
    return nil;
}

- (NSInteger) callCount {
    return [_calls count];
};

- (HandlerMock*)lastCall {
    return [_calls lastObject];
}

- (void(^)(id<AsyncResult> result))block
{
    return ^(id<AsyncResult> result) {
        _block(result);
        @synchronized(self) {
            id value = result.asyncState == AsyncResultStateSuccess ? result.asyncValue : result.asyncError;
            [_calls addObject:[[HandlerMock alloc] initWithValue:value metadata:[result.asyncMetadata copy] result:result]];
        }
    };
}

- (void(^)(id value, id<AsyncResult> result))blockWithValue
{
    return ^(id value, id<AsyncResult> result) {
        _block(result);
        @synchronized(self) {
            [_calls addObject:[[HandlerMock alloc] initWithValue:value metadata:[result.asyncMetadata copy] result:result]];
        }
    };
}

- (id<AsyncResult>(^)(id<AsyncResult> result))blockForChain
{
    return ^id<AsyncResult>(id<AsyncResult> result) {
        id<AsyncResult> secondResult = _block(result);
        @synchronized(self) {
            id value = result.asyncState == AsyncResultStateSuccess ? result.asyncValue : result.asyncError;
            [_calls addObject:[[HandlerMock alloc] initWithValue:value metadata:[result.asyncMetadata copy] result:result]];
        }
        return secondResult;
    };
}

- (id(^)(id value, NSDictionary* metadata))blockForTransform
{
    return ^id(id value, NSDictionary* metadata) {
        id transformedValue = _block(value);
        @synchronized(self) {
            [_calls addObject:[[HandlerMock alloc] initWithValue:value metadata:[metadata copy] result:nil]];
        }
        return transformedValue;
    };
}

- (NSString*)description
{
    return [NSString stringWithFormat:
            @"%@ (result:%@, value:%@, metadata:%@, block:%@, onMainThread:%d, calls:%@",
            [super description], _result, _value, _metadata, _block, _onMainThread, _calls];
}

@end


#pragma mark - ARHandlerMatcher

@implementation ARHandlerMatcher {
    id<AsyncResult> _result;
    NSUInteger _state;
    id _value;
    BOOL _onMainThread;
}

+ (NSArray *)matcherStrings {
    return [NSArray arrayWithObjects:@"beCalled", @"beCalledWithValue:onMainThread:", @"beCalledWithResult:onMainThread:", @"beCalledWithValue:result:onMainThread:", @"beCalledWithError:result:onMainThread:", nil];
}

- (BOOL)evaluate {
    /** handle this as a special case; KWValue supports NSNumber equality but not vice-versa **/
    @synchronized(self.subject) {
        HandlerMock* handler = (HandlerMock*)self.subject;
        NSAssert([handler isKindOfClass:[HandlerMock class]], @"Subject of beCalled matcher must be a HandlerMock.");
        if(handler.callCount != 1) {
            return NO;
        }
        handler = handler.lastCall;
        if(_result) {
            if(_state != AsyncResultStatePending) {
                return (handler.result.asyncState == _state &&
                        ((handler.value == nil && _value == nil) || [handler.value isEqual:_value]) &&
                        [handler.result isEqual:_result] &&
                        handler.onMainThread == _onMainThread);
            } else {
                return ([handler.result isEqual:_result] &&
                        handler.onMainThread == _onMainThread);
            }
        } else if(_state != AsyncResultStatePending) {
            return (((handler.value == nil && _value == nil) || [handler.value isEqual:_value]) &&
                    handler.onMainThread == _onMainThread);
        } else {
            return YES;
        }
    }
}

- (NSString *)failureMessageForShould {
    HandlerMock* handler = (HandlerMock*)self.subject;
    if(handler.callCount != 1) {
        return [NSString stringWithFormat:@"expected subject to be called once but called %d times", handler.callCount];
    } else if(_result) {
        handler = handler.lastCall;
        if(_state != AsyncResultStatePending) {
            return [NSString stringWithFormat:@"expected subject to be called once with %d, %@, %@, %d got %d, %@, %@, %d",
                    _state,
                    [KWFormatter formatObject:_value],
                    [KWFormatter formatObject:_result],
                    _onMainThread,
                    handler.result.asyncState,
                    [KWFormatter formatObject:handler.value],
                    [KWFormatter formatObject:handler.result],
                    handler.onMainThread];
        } else {
            return [NSString stringWithFormat:@"expected subject to be called once with %@, %d got %@, %d",
                    [KWFormatter formatObject:_result],
                    _onMainThread,
                    [KWFormatter formatObject:handler.result],
                    handler.onMainThread];
        }
    } else if(_state != AsyncResultStatePending) {
        handler = handler.lastCall;
        return [NSString stringWithFormat:@"expected subject to be called once with %@, %d got %@, %d",
                [KWFormatter formatObject:_value],
                _onMainThread,
                [KWFormatter formatObject:handler.value],
                handler.onMainThread];
    } else {
        return @"expected subject to be called once";
    }
}

- (void)beCalled
{
    _result = nil;
    _state  = AsyncResultStatePending;
    _value  = nil;
    _onMainThread = NO;
}

- (void)beCalledWithValue:(id)value onMainThread:(BOOL)onMainThread
{
    _state  = AsyncResultStateSuccess;
    _value  = value;
    _onMainThread = !!onMainThread;
}

- (void)beCalledWithResult:(id<AsyncResult>)result onMainThread:(BOOL)onMainThread
{
    NSAssert([result conformsToProtocol:@protocol(AsyncResult)], @"result must conforms to AsyncResult.");
    _result = result;
    _state  = AsyncResultStatePending;
    _value  = nil;
    _onMainThread = !!onMainThread;
}

- (void)beCalledWithValue:(id)value result:(id<AsyncResult>)result onMainThread:(BOOL)onMainThread
{
    NSAssert([result conformsToProtocol:@protocol(AsyncResult)], @"result must conforms to AsyncResult.");
    _result = result;
    _state  = AsyncResultStateSuccess;
    _value  = value;
    _onMainThread = !!onMainThread;
}

- (void)beCalledWithError:(id)error result:(id<AsyncResult>)result onMainThread:(BOOL)onMainThread
{
    NSAssert([result conformsToProtocol:@protocol(AsyncResult)], @"result must conforms to AsyncResult.");
    _result = result;
    _state  = AsyncResultStateError;
    _value  = error;
    _onMainThread = !!onMainThread;
}

@end
