//
//  OpenViewController.m
//  Badging
//
//  Created by Kendall Goto on 3/20/19.
//  Copyright © 2019 Los Altos Hacks. All rights reserved.
//

#import "OpenViewController.h"

@interface OpenViewController ()
@end

@implementation OpenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _pickerOptions = @[@"Lunch", @"Dinner", @"Midnight Surprise", @"Breakfast"];
}
- (void)viewDidAppear:(BOOL)animated {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:@"authToken"] == NULL || [[defaults objectForKey:@"assnTime"] timeIntervalSinceNow] < -14400) {
        NSLog(@"%f", [[defaults objectForKey:@"assnTime"] timeIntervalSinceNow]);
        [self performSegueWithIdentifier:@"toLogin" sender:self];
    }
    else
        NSLog(@"Proceeding with stored token.");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_pickerOptions count];
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [_pickerOptions objectAtIndex:row];
}
- (IBAction)stepperChange:(UIStepper *)sender {
    [self.stepperValue setText:[NSString stringWithFormat:@"%1.f", [sender value]]];
}
@end
