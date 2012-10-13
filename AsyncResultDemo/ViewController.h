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
