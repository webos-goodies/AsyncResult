//
//  ViewController.h
//  AsyncResultSampleApp
//
//  Created by Chihiro Ito on 2012/10/02.
//  Copyright (c) 2012年 Chihiro Ito. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *labelOfTopNews;
@property (weak, nonatomic) IBOutlet UILabel *labelOfAlertViewChoice;
@property (weak, nonatomic) IBOutlet UILabel *labelOfActionSheetChoice;
@property (weak, nonatomic) IBOutlet UILabel *labelOfTwitterName;
- (IBAction)actionNSURLConnection:(id)sender;
- (IBAction)actionUIAlertView:(id)sender;
- (IBAction)actionUIActionSheet:(id)sender;
- (IBAction)actionACAccountStore:(id)sender;

@end
