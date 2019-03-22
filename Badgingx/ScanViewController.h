//
//  ScanViewController.h
//  Badging
//
//  Created by Kendall Goto on 3/20/19.
//  Copyright © 2019 Los Altos Hacks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "OpenViewController.h"
NS_ASSUME_NONNULL_BEGIN

@interface ScanViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>
@property (strong, nonatomic) IBOutlet UIView *CameraView;
@property (nonatomic) BOOL isReading;
@property (nonatomic) AVCaptureDevice *capDevice;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (strong, nonatomic) IBOutlet UIView *popupView;
@property (strong, nonatomic) IBOutlet UILabel *scanDetail_id;
@property (strong, nonatomic) IBOutlet UILabel *scanDetail_resolved;
@property (strong, nonatomic) IBOutlet UIView *scanDetail_status;
@property (strong, nonatomic) IBOutlet UILabel *scanDetail_statusLabel;
@end

NS_ASSUME_NONNULL_END
