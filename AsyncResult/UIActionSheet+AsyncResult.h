//
//  UIActionSheet+AsyncResult.h
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/10/05.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

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
