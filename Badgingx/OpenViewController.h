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
@property (nonatomic) NSArray *pickerOptions;
@property (strong, nonatomic) IBOutlet UILabel *stepperValue;

@end

NS_ASSUME_NONNULL_END
