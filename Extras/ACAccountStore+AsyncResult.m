//
//  ACAccountStore+AsyncResult.m
//  AsyncResult
//
//  Created by Chihiro Ito on 2012/10/05.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import "ACAccountStore+AsyncResult.h"

@implementation ACAccountStore (AsyncResult)

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (id<AsyncResult>)requestAccessToAccountsWithType:(ACAccountType *)accountType
{
    AsyncResult* result = [[AsyncResult alloc] init];
    [self requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if(error) {
            result.asyncError = @{ @"accountStore":self, @"error":error };
        } else if(granted) {
            result.asyncValue = self;
        } else {
            result.asyncError = @{ @"accountStore":self };
        }
    }];
    return result;
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"

- (id<AsyncResult>)requestAccessToAccountsWithType:(ACAccountType *)accountType options:(NSDictionary *)options
{
    AsyncResult* result = [[AsyncResult alloc] init];
    [self requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error) {
        if(error) {
            result.asyncError = @{ @"accountStore":self, @"error":error };
        } else if(granted) {
            result.asyncValue = self;
        } else {
            result.asyncError = @{ @"accountStore":self };
        }
    }];
    return result;
}

- (id<AsyncResult>)renewCredentialsForAccount:(ACAccount *)account
{
    AsyncResult* result = [[AsyncResult alloc] init];
    [self renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
        if(error) {
            result.asyncError = @{ @"accountStore":self, @"account":account, @"renewResult":[[NSNumber alloc] initWithInteger:renewResult], @"error":error };
        } else if(renewResult == ACAccountCredentialRenewResultRenewed) {
            result.asyncValue = account;
        } else {
            result.asyncError = @{ @"accountStore":self, @"account":account, @"renewResult":[[NSNumber alloc] initWithInteger:renewResult] };
        }
    }];
    return result;
}

- (id<AsyncResult>)removeAccount:(ACAccount *)account
{
    AsyncResult* result = [[AsyncResult alloc] init];
    [self removeAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
        if(error) {
            result.asyncError = @{ @"accountStore":self, @"account":account, @"error":error };
        } else if(success) {
            result.asyncValue = account;
        } else {
            result.asyncError = @{ @"accountStore":self, @"account":account };
        }
    }];
    return result;
}

@end
