//
//  ACAccountStore+AsyncResult.h
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/10/05.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import <Accounts/Accounts.h>
#import "AsyncResult.h"

@interface ACAccountStore (AsyncResult)

- (id<AsyncResult>)requestAccessToAccountsWithType:(ACAccountType *)accountType;
- (id<AsyncResult>)requestAccessToAccountsWithType:(ACAccountType *)accountType options:(NSDictionary *)options;
- (id<AsyncResult>)renewCredentialsForAccount:(ACAccount *)account;
- (id<AsyncResult>)removeAccount:(ACAccount *)account;

@end
