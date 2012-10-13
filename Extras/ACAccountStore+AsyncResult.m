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
