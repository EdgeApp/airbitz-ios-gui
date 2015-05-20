//
//  SendViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PickerTextView.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "AirbitzViewController.h"
#import "SpendTarget.h"

@protocol SendViewControllerDelegate;

@interface SendViewController : AirbitzViewController

//@property (nonatomic, strong) NSString              *walletUUID;
//@property (nonatomic, weak) IBOutlet PickerTextView *pickerTextSendTo;
@property (nonatomic, weak) IBOutlet UITextField    *addressTextField;
@property (nonatomic, weak) SpendTarget *spendTarget;
@property (nonatomic) BOOL bDidFailReadingQR;
@property (nonatomic) BOOL bInvalidAddressReadingQR;
@property (assign) id<SendViewControllerDelegate> delegate;

- (void)processURI;
- (void)resetViews;

@end

@protocol SendViewControllerDelegate <NSObject>

@required
-(void)pleaseRestartSendViewBecauseAppleSucksWithPresentController:(SpendTarget *)spendTarget fail:(BOOL)bDidFail invalidAddress:(BOOL)bInvalidAddress;
@optional


@end

@interface PeripheralContainer : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSDictionary *advertisingData;
@property (nonatomic, strong) NSNumber *rssi;
@property (nonatomic, strong) NSNumber *lastAdvertisingTime; //used for identifying peripherals that dropped out
@end
