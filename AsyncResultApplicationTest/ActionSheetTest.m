#import "Kiwi.h"
#import "HandlerMock.h"
#import "UIActionSheet+AsyncResult.h"

SPEC_BEGIN(ActionSheetExtensionSpec)

describe(@"ActionSheetExtension", ^{
    registerMatchers(@"AR");

    __block UIView*         mainView;
    __block UIActionSheet*  actionSheet;
    __block id<AsyncResult> result;
    __block HandlerMock*    handler;

    beforeAll(^{
        mainView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
    });

    beforeEach(^{
        handler  = [[HandlerMock alloc] init];
    });

    afterEach(^{
        if(actionSheet.visible) {
            [actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:NO];
        }
        actionSheet = nil;
        result      = nil;
        handler     = nil;
    });

    afterAll(^{
        mainView = nil;
    });

    it(@"should success with an index of clicked button", ^{
        actionSheet = [[UIActionSheet alloc] initWithTitle:@"Title" delegate:nil cancelButtonTitle:@"cancel" destructiveButtonTitle:@"delete" otherButtonTitles:@"show", @"edit", nil];
        result = [actionSheet asyncShowInView:mainView];
        asyncWait(result, handler.block);

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        [actionSheet dismissWithClickedButtonIndex:1 animated:YES];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

        [[expectFutureValue(handler) should] beCalledWithValue:@1 onMainThread:YES];
        [[result.asyncValue should] equal:@1];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateSuccess)];
    });

    it(@"should be canceled via dismissWithClickedButtonIndex:animated:", ^{
        actionSheet = [[UIActionSheet alloc] initWithTitle:@"Title" delegate:nil cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:nil];
        result = [actionSheet asyncShowInView:mainView];
        asyncWait(result, handler.block);

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

        [[expectFutureValue(handler) should] beCalled];
        [[handler.lastCall.value should] beKindOfClass:[AsyncResultCancel class]];
        [[result.asyncError should] beKindOfClass:[AsyncResultCancel class]];
        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStateError)];
        [[theValue(result.asyncIsCanceled) should] beYes];
    });
    
    it(@"should be canceled via asyncCancel", ^{
        actionSheet = [[UIActionSheet alloc] initWithTitle:@"Title" delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"ok", nil];
        actionSheet.asyncResolveAfterDismissal = YES;
        result = [actionSheet asyncShowInView:mainView];
        asyncWait(result, handler.block);

        [[theValue(result.asyncState) should] equal:theValue(AsyncResultStatePending)];
        [[theValue(actionSheet.asyncResolveAfterDismissal) should] beYes];
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
        actionSheet = [[UIActionSheet alloc] initWithTitle:@"Title" delegate:nil cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"ok", nil];

        NSMutableArray* calls = [[NSMutableArray alloc] init];
        actionSheet.delegateClickedButtonAtIndex = ^(UIActionSheet* arg1, NSInteger arg2) {
            [calls addObject:[NSArray arrayWithObjects:@"clicked", arg1, [NSNumber numberWithInteger:arg2], nil]]; };
        actionSheet.delegateWillPresent = ^(UIActionSheet* arg1) {
            [calls addObject:[NSArray arrayWithObjects:@"willPresent", arg1, nil]]; };
        actionSheet.delegateDidPresent = ^(UIActionSheet* arg1) {
            [calls addObject:[NSArray arrayWithObjects:@"didPresent", arg1, nil]]; };
        actionSheet.delegateWillDismissWithButtonIndex = ^(UIActionSheet* arg1, NSInteger arg2) {
            [calls addObject:[NSArray arrayWithObjects:@"willDismiss", arg1, [NSNumber numberWithInteger:arg2], nil]]; };
        actionSheet.delegateDidDismissWithButtonIndex = ^(UIActionSheet* arg1, NSInteger arg2) {
            [calls addObject:[NSArray arrayWithObjects:@"didDismiss", arg1, [NSNumber numberWithInteger:arg2], nil]]; };
        actionSheet.delegateCancel = ^(UIActionSheet* arg1) {
            [calls addObject:[NSArray arrayWithObjects:@"cancel", arg1, nil]]; };

        result = [actionSheet asyncShowInView:mainView];
        asyncWait(result, handler.block);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

        // Call manually since these methods may not be called without user operation
        [actionSheet.delegate actionSheet:actionSheet clickedButtonAtIndex:0];
        [actionSheet.delegate actionSheetCancel:actionSheet];

        NSNumber* index = [NSNumber numberWithInteger:0];
        [[theValue(calls.count) should] equal:theValue(6)];
        [[[calls objectAtIndex:0] should] equal:[NSArray arrayWithObjects:@"willPresent", actionSheet, nil]];
        [[[calls objectAtIndex:1] should] equal:[NSArray arrayWithObjects:@"didPresent", actionSheet, nil]];
        [[[calls objectAtIndex:2] should] equal:[NSArray arrayWithObjects:@"willDismiss", actionSheet, index, nil]];
        [[[calls objectAtIndex:3] should] equal:[NSArray arrayWithObjects:@"didDismiss", actionSheet, index, nil]];
        [[[calls objectAtIndex:4] should] equal:[NSArray arrayWithObjects:@"clicked", actionSheet, index, nil]];
        [[[calls objectAtIndex:5] should] equal:[NSArray arrayWithObjects:@"cancel", actionSheet, nil]];
    });
});

SPEC_END
