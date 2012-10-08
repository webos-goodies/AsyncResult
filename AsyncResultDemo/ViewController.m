//
//  ViewController.m
//  AsyncResultSampleApp
//
//  Created by Chihiro Ito on 2012/10/02.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import "ViewController.h"
#import "NSURLConnection+AsyncResult.h"
#import "UIAlertView+AsyncResult.h"
#import "UIActionSheet+AsyncResult.h"
#import "ACAccountStore+AsyncResult.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actionNSURLConnection:(id)sender {
    NSURL* url = [[NSURL alloc] initWithString:@"https://ajax.googleapis.com/ajax/services/feed/load?v=1.0&q=https%3A%2F%2Fnews.google.com%2Fnews%2Ffeeds%3Fhl%3Den%26num%3D3%26output%3Drss"];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request];

    id<AsyncResult> result = connection.asyncResponseJson;

    asyncWaitSuccessOnMainThread(result, ^(NSDictionary* value, id<AsyncResult> result) {
        NSLog(@"response body : %@", value);
        NSArray* titles = [value valueForKeyPath:@"responseData.feed.entries.title"];
        if(titles && titles.count > 0) {
            self.labelOfTopNews.text =  [titles objectAtIndex:0];
        } else {
            self.labelOfTopNews.text = @"empty response.";
        }
    });
}

- (IBAction)actionUIAlertView:(id)sender {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"AsyncResult Test" message:@"Tap any button." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];

    id<AsyncResult> result = [alertView asyncShow];

    asyncWaitSuccessOnMainThread(result, ^(NSNumber* value, id<AsyncResult> result) {
        self.labelOfAlertViewChoice.text = [NSString stringWithFormat:@"%@", value];
    });
    asyncWaitErrorOnMainThread(result, ^(id<AsyncResult> result) {
        self.labelOfAlertViewChoice.text = result.asyncIsCanceled ? @"canceled" : @"error";
    });
}

- (IBAction)actionUIActionSheet:(id)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"AsyncResult Test" delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Button 0" otherButtonTitles:@"Button1", nil];
    id<AsyncResult> result = [actionSheet asyncShowInView:self.view];

    asyncWaitSuccessOnMainThread(result, ^(NSNumber* value, id<AsyncResult> result) {
        self.labelOfActionSheetChoice.text = [NSString stringWithFormat:@"%@", value];
    });
    asyncWaitErrorOnMainThread(result, ^(id<AsyncResult> result) {
        self.labelOfActionSheetChoice.text = result.asyncIsCanceled ? @"canceled" : @"error";
    });
}

- (IBAction)actionACAccountStore:(id)sender {
    ACAccountStore* store   = [[ACAccountStore alloc] init];
    ACAccountType*  accType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    id<AsyncResult> result  = [store requestAccessToAccountsWithType:accType];
    asyncWaitSuccessOnMainThread(result, ^(ACAccountStore* value, id<AsyncResult> result) {
        if(value.accounts.count > 0) {
            self.labelOfTwitterName.text = ((ACAccount*)[value.accounts objectAtIndex:0]).username;
        } else {
            self.labelOfTwitterName.text = @"no account";
        }
    });
    asyncWaitErrorOnMainThread(result, ^(id<AsyncResult> result) {
        self.labelOfTwitterName.text = @"error";
    });
}
@end
