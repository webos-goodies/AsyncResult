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

@interface UIActionSheet (AsyncResult)

// If this property set to YES, handlers called by actionSheet:didDismissWithButtonIndex delegation method
// instead of actionSheet:willDismissWithButtonIndex.
@property (nonatomic) BOOL asyncResolveAfterDismissal;

// Block version of delegation methods.
@property (nonatomic) void(^delegateClickedButtonAtIndex)(UIActionSheet* actionSheet, NSInteger buttonIndex);
@property (nonatomic) void(^delegateWillPresent)(UIActionSheet* actionSheet);
@property (nonatomic) void(^delegateDidPresent)(UIActionSheet* actionSheet);
@property (nonatomic) void(^delegateWillDismissWithButtonIndex)(UIActionSheet* actionSheet, NSInteger buttonIndex);
@property (nonatomic) void(^delegateDidDismissWithButtonIndex)(UIActionSheet* actionSheet, NSInteger buttonIndex);
@property (nonatomic) void(^delegateCancel)(UIActionSheet* actionSheet);

- (id<AsyncResult>)asyncShowFromToolbar:(UIToolbar *)view;
- (id<AsyncResult>)asyncShowFromTabBar:(UITabBar *)view;
- (id<AsyncResult>)asyncShowFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated;
- (id<AsyncResult>)asyncShowFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated;
- (id<AsyncResult>)asyncShowInView:(UIView *)view;

@end
