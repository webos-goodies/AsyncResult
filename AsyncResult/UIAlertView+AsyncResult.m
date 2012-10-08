//
//  UIAlertView+AsyncResult.m
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/10/02.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import "UIAlertView+AsyncResult.h"
#import "AsyncResultInjector.h"

#pragma mark - AsyncResultAlertViewDelegate

@interface AsyncResultAlertViewDelegate : AsyncResult<UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView;
- (void)willPresentAlertView:(UIAlertView *)alertView;
- (void)didPresentAlertView:(UIAlertView *)alertView;
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)alertViewCancel:(UIAlertView *)alertView;
@end

@implementation AsyncResultAlertViewDelegate {
    __weak UIAlertView* _alertView;
    BOOL _isResolved;
}

- (id)initWithAlertView:(UIAlertView*)alertView;
{
    self = [super init];
    if (self) {
        _alertView  = alertView;
        _isResolved = NO;
    }
    return self;
}

- (BOOL)asyncCancel
{
    if([super asyncCancel]) {
        [_alertView dismissWithClickedButtonIndex:_alertView.cancelButtonIndex animated:NO];
        return YES;
    } else {
        return NO;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    void(^block)(UIAlertView*, NSInteger) = alertView.delegateClickedButtonAtIndex;
    if(block){ block(alertView, buttonIndex); }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    BOOL(^block)(UIAlertView*) = alertView.delegateShouldEnableFirstOtherButton;
    return block ? block(alertView) : YES;
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    void(^block)(UIAlertView*) = alertView.delegateWillPresentAlertView;
    if(block){ block(alertView); }
}

- (void)didPresentAlertView:(UIAlertView *)alertView
{
    void(^block)(UIAlertView*) = alertView.delegateDidPresentAlertView;
    if(block){ block(alertView); }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(!alertView.asyncResolveAfterDismissal) {
        _isResolved = YES;
        [self resolveOnAlertView:alertView withButtonIndex:buttonIndex];
    }
    void(^block)(UIAlertView*, NSInteger) = alertView.delegateWillDismissWithButtonIndex;
    if(block){ block(alertView, buttonIndex); }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(!_isResolved) {
        _isResolved = YES;
        [self resolveOnAlertView:alertView withButtonIndex:buttonIndex];
    }
    void(^block)(UIAlertView*, NSInteger) = alertView.delegateDidDismissWithButtonIndex;
    if(block){ block(alertView, buttonIndex); }
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
    void(^block)(UIAlertView*) = alertView.delegateCancel;
    if(block){ block(alertView); }
}

- (void)resolveOnAlertView:(UIAlertView*)alertView withButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == alertView.cancelButtonIndex) {
        // Call super class's asyncCancel to avoid duplicated call of dismissWithClickedButtonIndex:animated:.
        [super asyncCancel];
    } else {
        self.asyncValue = [[NSNumber alloc] initWithInteger:buttonIndex];
    }
}

@end


#pragma mark - AsyncResult category of UIAlertView

@implementation UIAlertView (AsyncResult)

- (BOOL)asyncResolveAfterDismissal
{
    return ((NSNumber*)[AsyncResultInjector getValueForKey:@"resolveAfterDismissal" from:self]).boolValue;
}

- (void)setAsyncResolveAfterDismissal:(BOOL)asyncResolveAfterDismissal
{
    [AsyncResultInjector setValue:[[NSNumber alloc] initWithBool:asyncResolveAfterDismissal] forKey:@"resolveAfterDismissal" to:self];
}

- (id<AsyncResult>)asyncShow
{
    AsyncResultAlertViewDelegate* result = [[AsyncResultAlertViewDelegate alloc] initWithAlertView:self];
    [AsyncResultInjector setValue:result forKey:@"result" to:self];
    self.delegate = result;
    [self show];
    return result;
}

#define DEFINE_PROPERTY(name, type) \
- type delegate##name { return [AsyncResultInjector getValueForKey:@"delegate" #name from:self]; }\
- (void)setDelegate##name:type value { [AsyncResultInjector setValue:value forKey:@"delegate" #name to:self]; }

DEFINE_PROPERTY(ClickedButtonAtIndex, (void(^)(UIAlertView*, NSInteger)))
DEFINE_PROPERTY(ShouldEnableFirstOtherButton, (BOOL(^)(UIAlertView*)))
DEFINE_PROPERTY(WillPresentAlertView, (void(^)(UIAlertView*)))
DEFINE_PROPERTY(DidPresentAlertView, (void(^)(UIAlertView*)))
DEFINE_PROPERTY(WillDismissWithButtonIndex, (void(^)(UIAlertView*, NSInteger)))
DEFINE_PROPERTY(DidDismissWithButtonIndex, (void(^)(UIAlertView*, NSInteger)))
DEFINE_PROPERTY(Cancel, (void(^)(UIAlertView*)))

@end
