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

#import <UIKit/UIKit.h>
#import "AsyncResult.h"

@interface UIAlertView (AsyncResult)

// If this property set to YES, handlers called by alertView:didDismissWithButtonIndex delegation method
// instead of alertView:willDismissWithButtonIndex.
@property (nonatomic) BOOL asyncResolveAfterDismissal;

// Block version of delegation methods.
@property (nonatomic) void(^delegateClickedButtonAtIndex)(UIAlertView* alertView, NSInteger buttonIndex);
@property (nonatomic) BOOL(^delegateShouldEnableFirstOtherButton)(UIAlertView* alertView);
@property (nonatomic) void(^delegateWillPresentAlertView)(UIAlertView* alertView);
@property (nonatomic) void(^delegateDidPresentAlertView)(UIAlertView* alertView);
@property (nonatomic) void(^delegateWillDismissWithButtonIndex)(UIAlertView* alertView, NSInteger buttonIndex);
@property (nonatomic) void(^delegateDidDismissWithButtonIndex)(UIAlertView* alertView, NSInteger buttonIndex);
@property (nonatomic) void(^delegateCancel)(UIAlertView* alertView);

- (id<AsyncResult>)asyncShow;

@end
