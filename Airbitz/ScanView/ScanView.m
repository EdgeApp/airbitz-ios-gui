
#import <AVFoundation/AVFoundation.h>
#import "ScanView.h"
#import "FlashSelectView.h"
#import "Util.h"
#import "CommonTypes.h"
#if !TARGET_IPHONE_SIMULATOR
#import "ZBarSDK.h"
#import "MainViewController.h"

#endif

@interface ScanView () <FlashSelectViewDelegate
#if !TARGET_IPHONE_SIMULATOR
 , ZBarReaderDelegate, ZBarReaderViewDelegate
#endif
>
{
    BOOL                            _bUsingImagePicker;
#if !TARGET_IPHONE_SIMULATOR
    ZBarReaderView                  *_readerView;
    ZBarReaderController            *_readerPicker;
#endif
}

@property (weak, nonatomic) IBOutlet UIImageView     *scanFrame;
@property (weak, nonatomic) IBOutlet FlashSelectView *flashSelector;
@property (weak, nonatomic) IBOutlet UIImageView     *imageFlashFrame;
@property (weak, nonatomic) IBOutlet UIView          *bleView;
@property (weak, nonatomic) IBOutlet UIButton        *bleButton;
@property (weak, nonatomic) IBOutlet UIButton        *imgButton;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *scanningSpinner;
@property (nonatomic, weak) IBOutlet UILabel				*scanningLabel;
@property (nonatomic, weak) IBOutlet UILabel				*scanningErrorLabel;

@end

@implementation ScanView

+ (ScanView *)CreateView:(UIView *)parentView
{
    ScanView *view = [[[NSBundle mainBundle] loadNibNamed:@"ScanView~iphone" owner:nil options:nil] objectAtIndex:0];
    [Util addSubviewWithConstraints:parentView child:view];
    view.bleButton.hidden = YES;
    view.imgButton.hidden = YES;

    return view;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)didMoveToSuperview
{
    [Util resizeView:self withDisplayView:nil];
    _flashSelector.delegate = self;
    _bUsingImagePicker = NO;
}

- (void)willRotateOrientation:(UIInterfaceOrientation) orientation
{
#if !TARGET_IPHONE_SIMULATOR
    [_readerView willRotateToInterfaceOrientation:orientation duration:0.35];
#endif
}

#if TARGET_IPHONE_SIMULATOR

- (void)startQRReader
{
}

- (void)stopQRReader
{
}

#else 

- (void)startQRReader
{
    // on iOS 8, we must request permission to access the camera
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                // Permission has been granted. Use dispatch_async for any UI updating
                // code because this block may be executed in a thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self attemptToStartQRReader];
                });
            } else {
                [self attemptToStartQRReader];
            }
        }];
    } else {
        [self attemptToStartQRReader];
    }
}

-(void)attemptToStartQRReader
{
    // check camera state before proceeding
    _readerView = [ZBarReaderView new];
    _readerView.torchMode = AVCaptureTorchModeOff;

    [_readerView willRotateToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0.35];

    if ([_readerView isDeviceAvailable]) {
        [_scanningErrorLabel setHidden:YES];
        [_flashSelector setHidden:NO];
    } else {
        _scanningErrorLabel.text = NSLocalizedString(@"Camera unavailable", @"");
        [_scanningErrorLabel setHidden:NO];
        [_flashSelector setHidden:YES];
    }

    [self insertSubview:_readerView belowSubview:self.scanFrame];
    _readerView.frame = self.scanFrame.frame;
    _readerView.readerDelegate = self;
    _readerView.tracksSymbols = NO;
    
    _readerView.tag = READER_VIEW_TAG;
    [_readerView start];
    [self flashItemSelected:FLASH_ITEM_OFF];
}

- (void)stopQRReader
{
    if (_readerView) {
        [_readerView stop];
        [_readerView removeFromSuperview];
        _readerView = nil;
    }
}

- (BOOL)processZBarResults:(ZBarSymbolSet *)syms
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
	for (ZBarSymbol *sym in syms) {
		NSString *text = (NSString *)sym.data;
        [array addObject:text];
    }
    return [_delegate processResultArray:array];
}

#endif

#pragma mark - Flash Select Delegates

- (void)flashItemSelected:(tFlashItem)flashType
{
#if !TARGET_IPHONE_SIMULATOR
    AVCaptureDevice *device = _readerView.device;
    if(device)
    {
        switch(flashType) {
        case FLASH_ITEM_OFF:
            if ([device isTorchModeSupported:AVCaptureTorchModeOff])
            {
                NSError *error = nil;
                if ([device lockForConfiguration:&error])
                {
                    device.torchMode = AVCaptureTorchModeOff;
                    [device unlockForConfiguration];
                }
            }
            break;
        case FLASH_ITEM_ON:
            if ([device isTorchModeSupported:AVCaptureTorchModeOn])
            {
                NSError *error = nil;
                if ([device lockForConfiguration:&error])
                {
                    device.torchMode = AVCaptureTorchModeOn;
                    [device unlockForConfiguration];
                }
            }
            break;
        }
    }
#endif
}

#pragma mark - ZBar's Delegate methods

#if !TARGET_IPHONE_SIMULATOR
- (void)readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    if ([self processZBarResults:syms]) {
        [view stop];
    }
    else
    {
        [view start];
    }

}
#endif

#if !TARGET_IPHONE_SIMULATOR

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)reader
{
    [reader dismissViewControllerAnimated:YES completion:nil];
    _bUsingImagePicker = NO;
	
	//cw viewWillAppear will get called which will switch us back into BLE mode
}

- (void)imagePickerController:(UIImagePickerController *)reader didFinishPickingMediaWithInfo:(NSDictionary*) info
{
    id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];
    //UIImage *image = [info objectForKey: UIImagePickerControllerOriginalImage];

    BOOL bSuccess = [self processZBarResults:(ZBarSymbolSet *)results];

    [reader dismissViewControllerAnimated:YES completion:nil];
    //[[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    //[reader dismissModalViewControllerAnimated: YES];

    _bUsingImagePicker = NO;

    if (!bSuccess)
    {
        //_startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
#if !TARGET_IPHONE_SIMULATOR
		[self startQRReader];
#endif
    }
}

- (void)readerControllerDidFailToRead:(ZBarReaderController*)reader
                            withRetry:(BOOL)retry
{
    [reader dismissViewControllerAnimated:YES completion:nil];

    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"QR Code Scan Failure", nil)
                          message:NSLocalizedString(@"Unable to scan QR code", nil)
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];

    _bUsingImagePicker = NO;
   // _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
   [self startQRReader];
}

#endif


@end
