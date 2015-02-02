//
//  ViewController.m
//  beacon_app1
//
//  Created by 奥野遼 on 2015/02/02.
//  Copyright (c) 2015年 奥野遼. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSUUID *proximityUUID;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) CLBeacon *nearestBeacon;
@property (strong, nonatomic) NSString *str;
@property (weak, nonatomic) IBOutlet UILabel *msg;
@property (weak, nonatomic) IBOutlet UILabel *msg2;
@property (weak, nonatomic) IBOutlet UIImageView *medal;

@property AVAudioPlayer* player;
@property AVAudioPlayer* player2;

@end

@implementation ViewController{
    AVCaptureSession *captureSession;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.

    self.medal.hidden = YES;
    
    // リソースファイルをAVAudioPlayerにセット。
    NSString *path = [[NSBundle mainBundle] pathForResource:@"jiba" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath: path];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL: url error:nil];
    
//    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"yokai_bgm" ofType:@"mp3"];
//    NSURL *url2 = [NSURL fileURLWithPath: path2];
//    self.player2 = [[AVAudioPlayer alloc] initWithContentsOfURL: url2 error:nil];
//    
//    [self.player2 play];
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        self.proximityUUID = [[NSUUID alloc] initWithUUIDString:@"00000000-F48E-1001-B000-001C4DEAF2A1"];
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID: self.proximityUUID
                                                               identifier:@"com.kato.ibeaconSample"];
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            // requestAlwaysAuthorizationメソッドが利用できる場合(iOS8以上の場合)
            // 位置情報の取得許可を求めるメソッド
            [self.locationManager requestAlwaysAuthorization];
        } else {
            // requestAlwaysAuthorizationメソッドが利用できない場合(iOS8未満の場合)
            [self.locationManager startMonitoringForRegion: self.beaconRegion];
        }
    } else {
        // iBeaconが利用できない端末の場合
        NSLog(@"iBeaconを利用できません。");
    }
}

// ユーザの位置情報の許可状態を確認するメソッド
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusNotDetermined) {
        // ユーザが位置情報の使用を許可していない
    } else if(status == kCLAuthorizationStatusAuthorizedAlways) {
        // ユーザが位置情報の使用を常に許可している場合
        [self.locationManager startMonitoringForRegion: self.beaconRegion];
    } else if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        // ユーザが位置情報の使用を使用中のみ許可している場合
        [self.locationManager startMonitoringForRegion: self.beaconRegion];
    }
}

// 領域計測が開始した場合
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Start Monitoring Region"];
}

// 指定した領域に入った場合
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
//    [self sendLocalNotificationForMessage:@"領域に入ったよ"];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

// 指定した領域から出た場合
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
//    [self sendLocalNotificationForMessage:@"領域から出たよ"];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

// 領域内にいるかどうかを確認する処理
-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    switch (state) {
        case CLRegionStateInside:
            if([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]){
                NSLog(@"Enter %@",region.identifier);
                //Beacon の範囲内に入った時に行う処理を記述する
                [self sendLocalNotificationForMessage:@"Already Entering"];
            }
            break;
            
        case CLRegionStateOutside:
        case CLRegionStateUnknown:
        default:
            break;
    }
}


// Beacon信号を検出した場合
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (beacons.count > 0) {
        self.nearestBeacon = beacons.firstObject;
        self.str = [[NSString alloc] initWithFormat:@"%f [cm]", self.nearestBeacon.accuracy*100];
        NSLog(@"%@", self.str);
        int distance = self.nearestBeacon.accuracy*100;
        if (distance > 0 && distance < 100){
            self.msg.text = @"検知！";
            self.msg2.text = [NSString stringWithFormat:@"iphoneからの距離：%@ ", self.str];
//            [self lightOn]; //LED点滅
//            [self performSelector:@selector(lightOff) withObject:nil afterDelay:0.05];
            [self.player play];
            [self blinkImage:self.medal];
            self.medal.hidden = NO;
        }else{
            self.msg.text = @"検出中";
            self.medal.hidden = YES;
            self.msg2.text = @"範囲外";
        }
//        [self sendLocalNotificationForMessage:self.str];
        
        
    }
}

// ローカルプッシュ処理
- (void)sendLocalNotificationForMessage:(NSString *)message
{
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.fireDate = [NSDate date];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

// 図、文字の点滅
- (void)blinkImage:(UIImageView *)target {
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 0.1f;
    animation.autoreverses = YES;
    //animation.repeatCount =
    animation.repeatCount = 3; //infinite loop -> HUGE_VAL
    animation.fromValue = [NSNumber numberWithFloat:1.0f]; //MAX opacity
    animation.toValue = [NSNumber numberWithFloat:0.0f]; //MIN opacity
    [target.layer addAnimation:animation forKey:@"blink"];
}

////LEDライトを点灯
//-(void)lightOn
//{
//    [captureSession startRunning];
//    NSError *error = nil;
//    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    [captureDevice lockForConfiguration:&error];
//    captureDevice.torchMode = AVCaptureTorchModeOn;
//    [captureDevice unlockForConfiguration];
//}
//
////LEDライトを消灯
//-(void)lightOff
//{          NSError *offerror = nil;
//    AVCaptureDevice *offcaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    
//    [offcaptureDevice lockForConfiguration:&offerror];
//    offcaptureDevice.torchMode = AVCaptureTorchModeOff;
//    [offcaptureDevice unlockForConfiguration];
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
