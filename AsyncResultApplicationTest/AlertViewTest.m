//
//  AsyncResultApplicationTest.m
//  AsyncResultApplicationTest
//
//  Created by Chihiro Ito on 2012/10/02.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import "Kiwi.h"
#import "HandlerMock.h"
#import "UIAlertView+AsyncResult.h"

SPEC_BEGIN(AlertViewExtensionSpec)

describe(@"AlertViewExtension", ^{
    registerMatchers(@"AR");

    __block UIAlertView*    alertView;
    __block id<AsyncResult> result;
    __block HandlerMock*    handler;

    beforeEach(^{
        handler = [[HandlerMock alloc] init];
    });

    afterEach(^{
        if(alertView.visible) {
            [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:NO];
        }
        alertView = nil;
        result    = nil;
        handler   = nil;
    });

    it(@"should success with an index of clicked button", ^{
        alertView = [[UIAlertView alloc] initWithTitle:@"Title" message:@"message" delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles:@"ok", nil];
        result = [alertView asyncShow];
        asyncWait(result, handler.block);

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        [alertView dismissWithClickedButtonIndex:1 animated:YES];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

        [[expectFutureValue(handler) should] beCalledWithValue:@1 onMainThread:YES];
        [[result.asyncValue should] equal:@1];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
    });

    it(@"should be canceled via dismissWithClickedButtonIndex:animated:", ^{
        alertView = [[UIAlertView alloc] initWithTitle:@"Title" message:@"message" delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles:nil];
        result = [alertView asyncShow];
        asyncWait(result, handler.block);

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        [alertView dismissWithClickedButtonIndex:0 animated:YES];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

        [[expectFutureValue(handler) should] beCalled];
        [[handler.lastCall.value should] beKindOfClass:[AsyncResultCancel class]];
        [[result.asyncError should] beKindOfClass:[AsyncResultCancel class]];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[theValue(result.asyncIsCanceled) should] beYes];
    });
    
    it(@"should be canceled via asyncCancel", ^{
        alertView = [[UIAlertView alloc] initWithTitle:@"Title" message:@"message" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil];
        result = [alertView asyncShow];
        alertView.asyncResolveAfterDismissal = YES;
        asyncWait(result, handler.block);

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
        [[theValue(alertView.asyncResolveAfterDismissal) should] beYes];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        [result asyncCancel];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

        [[expectFutureValue(handler) should] beCalled];
        [[handler.lastCall.value should] beKindOfClass:[AsyncResultCancel class]];
        [[result.asyncError should] beKindOfClass:[AsyncResultCancel class]];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[theValue(result.asyncIsCanceled) should] beYes];
    });

    it(@"should call delegate blocks porperly", ^{
        alertView = [[UIAlertView alloc] initWithTitle:@"Title" message:@"message" delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles:@"ok", nil];

        NSMutableArray* calls = [[NSMutableArray alloc] init];
        alertView.delegateClickedButtonAtIndex = ^(UIAlertView* arg1, NSInteger arg2) {
            [calls addObject:[NSArray arrayWithObjects:@"clicked", arg1, [NSNumber numberWithInteger:arg2], nil]]; };
        alertView.delegateShouldEnableFirstOtherButton = ^BOOL(UIAlertView* arg1) {
            [calls addObject:[NSArray arrayWithObjects:@"enableButton", arg1, nil]]; return YES; };
        alertView.delegateWillPresentAlertView = ^void(UIAlertView* arg1) {
            [calls addObject:[NSArray arrayWithObjects:@"willPresent", arg1, nil]]; };
        alertView.delegateDidPresentAlertView = ^void(UIAlertView* arg1) {
            [calls addObject:[NSArray arrayWithObjects:@"didPresent", arg1, nil]]; };
        alertView.delegateWillDismissWithButtonIndex = ^(UIAlertView* arg1, NSInteger arg2) {
            [calls addObject:[NSArray arrayWithObjects:@"willDismiss", arg1, [NSNumber numberWithInteger:arg2], nil]]; };
        alertView.delegateDidDismissWithButtonIndex = ^(UIAlertView* arg1, NSInteger arg2) {
            [calls addObject:[NSArray arrayWithObjects:@"didDismiss", arg1, [NSNumber numberWithInteger:arg2], nil]]; };
        alertView.delegateCancel = ^void(UIAlertView* arg1) {
            [calls addObject:[NSArray arrayWithObjects:@"cancel", arg1, nil]]; };

        result = [alertView asyncShow];
        asyncWait(result, handler.block);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        [alertView dismissWithClickedButtonIndex:0 animated:YES];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

        // Call manually since these methods may not be called without user operation
        [alertView.delegate alertView:alertView clickedButtonAtIndex:0];
        [alertView.delegate alertViewCancel:alertView];

        NSNumber* index = [NSNumber numberWithInteger:0];
        [[theValue(calls.count) should] equal:theValue(7)];
        [[[calls objectAtIndex:0] should] equal:[NSArray arrayWithObjects:@"enableButton", alertView, nil]];
        [[[calls objectAtIndex:1] should] equal:[NSArray arrayWithObjects:@"willPresent", alertView, nil]];
        [[[calls objectAtIndex:2] should] equal:[NSArray arrayWithObjects:@"didPresent", alertView, nil]];
        [[[calls objectAtIndex:3] should] equal:[NSArray arrayWithObjects:@"willDismiss", alertView, index, nil]];
        [[[calls objectAtIndex:4] should] equal:[NSArray arrayWithObjects:@"didDismiss", alertView, index, nil]];
        [[[calls objectAtIndex:5] should] equal:[NSArray arrayWithObjects:@"clicked", alertView, index, nil]];
        [[[calls objectAtIndex:6] should] equal:[NSArray arrayWithObjects:@"cancel", alertView, nil]];
    });

});

SPEC_END
