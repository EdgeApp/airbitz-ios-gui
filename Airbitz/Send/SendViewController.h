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
#import "ABCSpend.h"
#import "ZBarSDK.h"


typedef enum eLoopbackState
{
    LoopbackState_None,
    LoopbackState_Go,
    LoopbackState_Scan_Failed,
    LoopbackState_Invalid_Address,
    LoopbackState_Invalid_Private_Key,
    LoopbackState_Cancelled
} tLoopbackState;



@protocol SendViewControllerDelegate;

@interface SendViewController : AirbitzViewController

@property (nonatomic, strong) ZBarSymbolSet           *zBarSymbolSet;
@property (nonatomic, strong) IBOutlet UITextField    *addressTextField;
@property (nonatomic)       tLoopbackState          loopbackState;
@property (nonatomic)       BOOL                    bImportMode;

@property (assign) id<SendViewControllerDelegate> delegate;

- (void)processURI;
- (void)resetViews;

@end

@protocol SendViewControllerDelegate <NSObject>

@required
@optional


@end

@interface PeripheralContainer : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSDictionary *advertisingData;
@property (nonatomic, strong) NSNumber *rssi;
@property (nonatomic, strong) NSNumber *lastAdvertisingTime; //used for identifying peripherals that dropped out
@end
