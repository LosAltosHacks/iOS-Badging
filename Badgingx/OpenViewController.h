//
//  OpenViewController.h
//  Badging
//
//  Created by Kendall Goto on 3/20/19.
//  Copyright © 2019 Los Altos Hacks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>
@property (strong, nonatomic) IBOutlet UIPickerView *scanTarget;
@property (nonatomic) NSDictionary *pickerOptions;

@end

NS_ASSUME_NONNULL_END
