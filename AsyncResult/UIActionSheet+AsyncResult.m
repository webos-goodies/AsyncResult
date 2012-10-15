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

#import "UIActionSheet+AsyncResult.h"
#import "AsyncResultInjector.h"


#pragma mark - AsyncResultActionSheetDelegate

@interface AsyncResultActionSheetDelegate : AsyncResult<UIActionSheetDelegate>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet;
- (void)didPresentActionSheet:(UIActionSheet *)actionSheet;
- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)actionSheetCancel:(UIActionSheet *)actionSheet;
@end

@implementation AsyncResultActionSheetDelegate {
    __weak UIActionSheet* _actionSheet;
    BOOL _isResolved;
}

- (id)initWithActionSheet:(UIActionSheet*)actionSheet
{
    self = [super init];
    if (self) {
        _actionSheet = actionSheet;
        _isResolved  = NO;
    }
    return self;
}

- (BOOL)asyncCancel
{
    if([super asyncCancel]) {
        [_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:NO];
        return YES;
    } else {
        return NO;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    void(^block)(UIActionSheet*, NSInteger) = actionSheet.delegateClickedButtonAtIndex;
    if(block){ block(actionSheet, buttonIndex); }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    void(^block)(UIActionSheet*) = actionSheet.delegateWillPresent;
    if(block) { block(actionSheet); }
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet
{
    void(^block)(UIActionSheet*) = actionSheet.delegateDidPresent;
    if(block) { block(actionSheet); }
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(!actionSheet.asyncResolveAfterDismissal) {
        _isResolved = YES;
        [self resolveOnActionSheet:actionSheet withButtonIndex:buttonIndex];
    }
    void(^block)(UIActionSheet*, NSInteger) = actionSheet.delegateWillDismissWithButtonIndex;
    if(block){ block(actionSheet, buttonIndex); }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(!_isResolved) {
        _isResolved = YES;
        [self resolveOnActionSheet:actionSheet withButtonIndex:buttonIndex];
    }
    void(^block)(UIActionSheet*, NSInteger) = actionSheet.delegateDidDismissWithButtonIndex;
    if(block){ block(actionSheet, buttonIndex); }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
    void(^block)(UIActionSheet*) = actionSheet.delegateCancel;
    if(block) { block(actionSheet); }
}

- (void)resolveOnActionSheet:(UIActionSheet*)actionSheet withButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == actionSheet.cancelButtonIndex) {
        // Call super class's asyncCancel to avoid duplicated call of dismissWithClickedButtonIndex:animated:.
        [super asyncCancel];
    } else {
        [self setAsyncValue:[[NSNumber alloc] initWithInteger:buttonIndex] withMetadata:nil];
    }
}

@end


#pragma mark - UIActionSheet

static id<AsyncResult>setupAsyncResult(UIActionSheet* actionSheet) {
    AsyncResultActionSheetDelegate* result = [[AsyncResultActionSheetDelegate alloc] initWithActionSheet:actionSheet];
    [AsyncResultInjector setValue:result forKey:@"result" to:actionSheet];
    actionSheet.delegate = result;
    return result;
}

@implementation UIActionSheet (AsyncResult)

- (BOOL)asyncResolveAfterDismissal
{
    return ((NSNumber*)[AsyncResultInjector getValueForKey:@"resolveAfterDismissal" from:self]).boolValue;
}

- (void)setAsyncResolveAfterDismissal:(BOOL)asyncResolveAfterDismissal
{
    [AsyncResultInjector setValue:[[NSNumber alloc] initWithBool:asyncResolveAfterDismissal] forKey:@"resolveAfterDismissal" to:self];
}

#define DEFINE_SHOW_METHOD(suffix) \
- (id<AsyncResult>)asyncShow##suffix \
{ \
    id<AsyncResult> result = setupAsyncResult(self); \
    [self show##suffix]; \
    return result; \
}

DEFINE_SHOW_METHOD(FromToolbar:(UIToolbar *)view)
DEFINE_SHOW_METHOD(FromTabBar:(UITabBar *)view)
DEFINE_SHOW_METHOD(FromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated)
DEFINE_SHOW_METHOD(FromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated)
DEFINE_SHOW_METHOD(InView:(UIView *)view)

#define DEFINE_PROPERTY(name, type) \
- type delegate##name { return [AsyncResultInjector getValueForKey:@"delegate" #name from:self]; }\
- (void)setDelegate##name:type value { [AsyncResultInjector setValue:value forKey:@"delegate" #name to:self]; }

DEFINE_PROPERTY(ClickedButtonAtIndex,       (void(^)(UIActionSheet*, NSInteger)))
DEFINE_PROPERTY(WillPresent,                (void(^)(UIActionSheet*)))
DEFINE_PROPERTY(DidPresent,                 (void(^)(UIActionSheet*)))
DEFINE_PROPERTY(WillDismissWithButtonIndex, (void(^)(UIActionSheet*, NSInteger)))
DEFINE_PROPERTY(DidDismissWithButtonIndex,  (void(^)(UIActionSheet*, NSInteger)))
DEFINE_PROPERTY(Cancel,                     (void(^)(UIActionSheet*)))

@end
