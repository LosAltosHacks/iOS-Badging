//
//  ScanViewController.m
//  Badging
//
//  Created by Kendall Goto on 3/20/19.
//  Copyright © 2019 Los Altos Hacks. All rights reserved.
//

#import "ScanViewController.h"

@interface ScanViewController ()

@end

@implementation ScanViewController {
    NSDate *lastSuccess;
    NSMutableArray *scannedThisSession;
    BOOL inProgress;
    NSNumber *selectedMeal;
    NSNumber *servingNumber;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //load NFC
    //https://www.appcoda.com/qr-code-ios-programming-tutorial/
    _isReading = NO;
    inProgress = NO;
    _captureSession = nil;

    NSError *error;

    _capDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_capDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:_CameraView.layer.bounds];
    [_CameraView.layer addSublayer:_videoPreviewLayer];
    
    [_captureSession startRunning];
    [_capDevice lockForConfiguration:nil];
    [_capDevice setTorchMode:AVCaptureTorchModeOn];
    [_capDevice setFlashMode:AVCaptureFlashModeOn];
    [_capDevice unlockForConfiguration];
    
}
- (void)viewWillAppear:(BOOL)animated {
    scannedThisSession = [[NSMutableArray alloc] init];
    OpenViewController *parent = (OpenViewController *)self.presentingViewController;
    NSLog(@"%@", parent);
    NSUInteger selectedRow = [parent.scanTarget selectedRowInComponent:0];
    selectedMeal = [[NSNumber alloc] initWithInteger:selectedRow+1];
    NSLog(@"%@", selectedMeal);
    //number of servings:
    servingNumber = [[NSNumber alloc] initWithInteger:[[parent.stepperValue text] integerValue]];
}
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if(lastSuccess == nil) {
        lastSuccess = [NSDate date];
    }
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            //QR code read!
//            NSString *reader = [metadataObj stringValue];
            if([lastSuccess timeIntervalSinceNow] >= -0.05) {
                return;
            }
            if(inProgress)
                return;
            inProgress = YES;
            lastSuccess = [NSDate date];
            NSLog(@"QR CODE: %@",  [metadataObj stringValue]);
            if([[self.scanDetail_id text] isEqualToString:[metadataObj stringValue]]) {
                inProgress = NO;
                return;
            }
            if([scannedThisSession containsObject:[metadataObj stringValue]]) {
                //dupe scan!
                NSLog(@"Dupe scan");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.scanDetail_id setText:[metadataObj stringValue]];
                    [self.scanDetail_resolved setText:@"Scanned This Session."];
                    [UIView animateWithDuration:0.3f animations:^{
                        [self.popupView setAlpha:0.75f];
                    } completion:^(BOOL finished) {
                        [UIView animateWithDuration:0.3f delay:1.3f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                            [self.popupView setAlpha:0.0f];
                        } completion:^(BOOL finished) {
                            self->inProgress = NO;

                        }];
                    }];
                });
                return;
            }
            [scannedThisSession addObject:[metadataObj stringValue]];
            //overlay popup
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.popupView.layer removeAllAnimations];
                [self.popupView setAlpha:0.0f];
                [self.scanDetail_id setText:[metadataObj stringValue]];
                
                [UIView animateWithDuration:0.3f animations:^{
                    [self.popupView setAlpha:0.75f];
                } completion:nil]; //leave on screen until it clears
            });
            //Call the API with this object to verify
            NSString *jwtkey = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.losaltoshacks.com/registration/v1/history/%@", [metadataObj stringValue]]]];
            [request setHTTPMethod:@"GET"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[NSString stringWithFormat:@"Bearer %@", jwtkey] forHTTPHeaderField:@"Authorization"];
            NSURLResponse *response;
            NSError *err;
            NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
            
            NSString *resp = [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
            NSArray *responseList = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
            NSDictionary *thisUser = [responseList objectAtIndex:0];
            NSString *fullname = [NSString stringWithFormat:@"%@ %@", [thisUser objectForKey:@"first_name"], [thisUser objectForKey:@"surname"]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.scanDetail_resolved setText:fullname];
            });
            
            //Add meal
            [request setURL:[NSURL URLWithString:@"https://api.losaltoshacks.com/dayof/v1/meal"]];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[NSString stringWithFormat:@"Bearer %@", jwtkey] forHTTPHeaderField:@"Authorization"];
            NSDate *jsonObj = [NSJSONSerialization dataWithJSONObject:@{@"meal_number": selectedMeal, @"badge_data": [metadataObj stringValue], @"allowed_servings": servingNumber} options:nil error:nil];
            [request setHTTPBody:jsonObj];
            responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
            responseList = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.scanDetail_resolved setText:fullname];
            });
            BOOL approved = NO;
            NSLog(@"%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
            NSDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
            if([[responseParsed objectForKey:@"status"] isEqualToString:@"ok"])
                approved = YES;
            else
                approved = NO;
            //if approved:
            dispatch_async(dispatch_get_main_queue(), ^{
                if(approved)
                    [self.scanDetail_statusLabel setText:@"APPROVED"];
                else
                    [self.scanDetail_statusLabel setText:@"DENIED"];
                [UIView animateWithDuration:0.3f animations:^{
                    if(approved)
                        self.scanDetail_status.layer.backgroundColor = [UIColor colorWithRed:0.2f green:1.0f blue:0.2f alpha:1.0f].CGColor;
                    else
                        self.scanDetail_status.layer.backgroundColor = [UIColor colorWithRed:1.0f green:.2f blue:0.2f alpha:1.0f].CGColor;

                } completion:^(BOOL finished){
                    [UIView animateWithDuration:0.3f delay:1.3f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        [self.popupView setAlpha:0.0f];
                    } completion:nil];
                    self->inProgress = NO;
                }];
            });
        }
    }
}

- (IBAction)dismissModal:(id)sender {
    
    [_capDevice lockForConfiguration:nil];
    [_capDevice setTorchMode:AVCaptureTorchModeOff];
    [_capDevice setFlashMode:AVCaptureFlashModeOff];
    [_capDevice unlockForConfiguration];
    //dismiss
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
