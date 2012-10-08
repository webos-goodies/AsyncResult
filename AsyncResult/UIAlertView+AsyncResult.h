//
//  UIAlertView+AsyncResult.h
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/10/02.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

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
