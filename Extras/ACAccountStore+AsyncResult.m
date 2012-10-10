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
            [result setAsyncError:error withMetadata:@{ @"accountStore":self }];
        } else if(granted) {
            [result setAsyncValue:self withMetadata:@{ @"accountStore":self }];
        } else {
            [result setAsyncError:nil withMetadata:@{ @"accountStore":self }];
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
            [result setAsyncError:error withMetadata:@{ @"accountStore":self }];
        } else if(granted) {
            [result setAsyncValue:self withMetadata:@{ @"accountStore":self }];
        } else {
            [result setAsyncError:nil withMetadata:@{ @"accountStore":self }];
        }
    }];
    return result;
}

- (id<AsyncResult>)renewCredentialsForAccount:(ACAccount *)account
{
    AsyncResult* result = [[AsyncResult alloc] init];
    [self renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
        NSDictionary* metadata = @{
            @"accountStore": self,
            @"account":      account,
            @"renewResult":  [[NSNumber alloc] initWithInteger:renewResult]
        };
        if(error) {
            [result setAsyncError:error withMetadata:metadata];
        } else if(renewResult == ACAccountCredentialRenewResultRenewed) {
            [result setAsyncValue:account withMetadata:metadata];
        } else {
            [result setAsyncError:nil withMetadata:metadata];
        }
    }];
    return result;
}

- (id<AsyncResult>)removeAccount:(ACAccount *)account
{
    AsyncResult* result = [[AsyncResult alloc] init];
    [self removeAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
        NSDictionary* metadata = @{ @"accountStore":self, @"account":account };
        if(error) {
            [result setAsyncError:error withMetadata:metadata];
        } else if(success) {
            [result setAsyncValue:account withMetadata:metadata];
        } else {
            [result setAsyncError:nil withMetadata:metadata];
        }
    }];
    return result;
}

@end
