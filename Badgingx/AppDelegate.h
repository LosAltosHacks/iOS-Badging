//
//  AppDelegate.h
//  Badging
//
//  Created by Oscar Bjorkman on 3/19/19.
//  Copyright © 2019 Los Altos Hacks. All rights reserved.
//

#import <UIKit/UIKit.h>
@import GoogleSignIn;

@interface AppDelegate : UIResponder <UIApplicationDelegate, GIDSignInDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

