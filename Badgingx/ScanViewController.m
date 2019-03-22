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
    NSNumber selectedMeal;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //load NFC
    scannedThisSession = [[NSMutableArray alloc] init];
    OpenViewController *parent = (OpenViewController *)self.presentingViewController;
    NSUInteger selectedRow = [parent.scanTarget selectedRowInComponent:0];
    selectedMeal = [[NSNumber alloc] initWithInteger:selectedRow+1];
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

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if(lastSuccess == nil) {
        lastSuccess = [NSDate date];
    }
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            //QR code read!
//            NSString *reader = [metadataObj stringValue];
            if([lastSuccess timeIntervalSinceNow] >= -0.25) {
                return;
            }
            if(inProgress)
                return;
            lastSuccess = [NSDate date];
            NSLog(@"QR CODE: %@",  [metadataObj stringValue]);
            if([scannedThisSession containsObject:[metadataObj stringValue]]) {
                //dupe scan!
                //ignore for now
                return;
            }
            inProgress = YES;
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
            NSString *jwtkey = [[NSUserDefaults standardUserDefaults] objectForKey:@"authKey"];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:[NSURL URLWithString:@"https://api.losaltoshacks.com/registration/v1/search"]];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[NSString stringWithFormat:@"Bearer %@", jwtkey] forHTTPHeaderField:@"Content-Type"];
            NSData *jsonObj = [NSJSONSerialization dataWithJSONObject:@{@"query": @"d5a87081-2b0a-45c6-9bec-d75c22a13742"} options:nil error:nil];
            [request setHTTPBody:jsonObj];
            NSLog(@"Data: %@", [[NSString alloc] initWithData:jsonObj encoding:NSUTF8StringEncoding]);
            NSURLResponse *response;
            NSError *err;
            NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
            
            NSString *resp = [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
            NSLog(@"response: %@",resp);

            //Add meal
            [request setURL:[NSURL URLWithString:@"https://api.losaltoshacks.com/dayof/v1/meal"]];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[NSString stringWithFormat:@"Bearer %@", jwtkey] forHTTPHeaderField:@"Content-Type"];
            jsonObj = [NSJSONSerialization dataWithJSONObject:@{@"meal_number": selectedMeal, @"badge_data": @"null", @"allowed_servings": @1} options:nil error:nil];
            [request setHTTPBody:jsonObj];
            responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
            
            resp = [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
            NSLog(@"response: %@", resp);

            
            /*
             [UIView animateWithDuration:0.3f delay:3.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
             [self.popupView setAlpha:0.0f];
             }
             completion:nil];
             */
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
