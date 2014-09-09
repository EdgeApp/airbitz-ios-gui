//
//  OfflineWalletViewController.m
//  AirBitz
//
//  Created by Adam Harris on 5/13/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "OfflineWalletViewController.h"
#import "CommonTypes.h"
#import "ABC.h"


/////// TEMP UNTIL WE GET FUNCTIONALITY IN THE CORE
typedef struct {
	int version;         ///< version of the symbol
	int width;           ///< width of the symbol
	unsigned char *data; ///< symbol data
} QRcode;
typedef enum {
	QR_MODE_NUL = -1,  ///< Terminator (NUL character). Internal use only
	QR_MODE_NUM = 0,   ///< Numeric mode
	QR_MODE_AN,        ///< Alphabet-numeric mode
	QR_MODE_8,         ///< 8-bit data mode
	QR_MODE_KANJI,     ///< Kanji (shift-jis) mode
	QR_MODE_STRUCTURE, ///< Internal use only
	QR_MODE_ECI,       ///< ECI mode
	QR_MODE_FNC1FIRST,  ///< FNC1, first position
	QR_MODE_FNC1SECOND, ///< FNC1, second position
} QRencodeMode;
typedef enum {
	QR_ECLEVEL_L = 0, ///< lowest
	QR_ECLEVEL_M,
	QR_ECLEVEL_Q,
	QR_ECLEVEL_H      ///< highest
} QRecLevel;
extern QRcode *QRcode_encodeString(const char *string, int version, QRecLevel level, QRencodeMode hint, int casesensitive);
extern void QRcode_free(QRcode *qrcode);

#define PRIVATE_KEY     @"***REMOVED***"
#define PUBLIC_ADDRESS  @"***REMOVED***"
//////// END TEMP

@interface OfflineWalletViewController ()
{
	unsigned int    _QRWidth;
    unsigned char   *_pQRData;
}

@property (weak, nonatomic) IBOutlet UIView         *viewDisplayArea;
@property (weak, nonatomic) IBOutlet UILabel        *labelTitlePublicAddress;
@property (weak, nonatomic) IBOutlet UIView         *viewPublicAddress;
@property (weak, nonatomic) IBOutlet UIImageView    *imageQRCode;
@property (weak, nonatomic) IBOutlet UILabel        *labelPublicAddress;
@property (weak, nonatomic) IBOutlet UILabel        *labelTitlePrivateKey;
@property (weak, nonatomic) IBOutlet UIView         *viewPrivateKey;
@property (weak, nonatomic) IBOutlet UILabel        *labelPrivateKey;
@property (weak, nonatomic) IBOutlet UIView         *viewButtons;
@property (weak, nonatomic) IBOutlet UIButton       *buttonDone;

@property (nonatomic, strong) NSString *strPrivate;
@property (nonatomic, strong) NSString *strPublic;

@end

@implementation OfflineWalletViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // TODO: call ABC to generate keys - for now just used hard coded examples
    self.strPrivate = PRIVATE_KEY;
    self.strPublic = PUBLIC_ADDRESS;

    self.labelPrivateKey.text = self.strPrivate;
    self.labelPublicAddress.text = self.strPublic;

    // TODO: call ABC to get the QRCode - for now encode our string
    QRcode *qr = NULL;
    NSString *strURI = [NSString stringWithFormat:@"bitcoin:%@", self.strPublic];
    qr = QRcode_encodeString([strURI UTF8String], 0, QR_ECLEVEL_L, QR_MODE_8, 1);
    int length = qr->width * qr->width;
    _pQRData = malloc(length);
    for (int i = 0; i < length; i++)
    {
        _pQRData[i] = qr->data[i] & 0x1;
    }
    _QRWidth = qr->width;
    QRcode_free(qr);

    // set the image to the qr code
    UIImage *qrimage = [self dataToImage:_pQRData withWidth:_QRWidth andHeight:_QRWidth];
    self.imageQRCode.layer.magnificationFilter = kCAFilterNearest;
    self.imageQRCode.image = qrimage;

    // update display layout
    [self updateDisplayLayout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    free(_pQRData);
}

/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - Action Methods

- (IBAction)buttonDoneTouched:(id)sender
{
    [self animatedExit];
}

- (IBAction)buttonCopyTouched:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.strPublic;
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Offline Wallet", nil)
                          message:NSLocalizedString(@"Public Key copied to clipboard", nil)
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)buttonPrintTouched:(id)sender
{
    if ([UIPrintInteractionController isPrintingAvailable])
    {
        NSMutableString *strBody = [[NSMutableString alloc] init];
        [strBody appendString:@"Offline Wallet\n\n"];
        [strBody appendString:@"Public Address:\n"];
        [strBody appendString:self.strPublic];
        [strBody appendString:@"\n\n"];
        [strBody appendString:@"Private Key:\n"];
        [strBody appendString:self.strPrivate];

        UIPrintInteractionController *pc = [UIPrintInteractionController sharedPrintController];

        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = NSLocalizedString(@"Offline Wallet", nil);
        pc.printInfo = printInfo;
        pc.showsPageRange = YES;

        UISimpleTextPrintFormatter *textFormatter = [[UISimpleTextPrintFormatter alloc] initWithText:strBody];
        textFormatter.startPage = 0;
        textFormatter.contentInsets = UIEdgeInsetsMake(72.0, 72.0, 72.0, 72.0); // 1 inch margins
        textFormatter.maximumContentWidth = 6 * 72.0;
        pc.printFormatter = textFormatter;
        pc.showsPageRange = YES;

        UIPrintInteractionCompletionHandler completionHandler =
        ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            if(!completed && error){
                NSLog(@"Print failed - domain: %@ error code %u", error.domain, (unsigned int)error.code);
            }
        };

        [pc presentAnimated:YES completionHandler:completionHandler];
    }
    else
    {
        // not available
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Offline Wallet", nil)
                              message:@"AirPrint is not currently available"
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }

}

- (IBAction)buttonInfoTouched:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Offline Wallet", nil)
                          message:@"TODO: bring up info"
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Misc Methods

- (void)updateDisplayLayout
{
    // update for iPhone 4
    if (IS_IPHONE4 )
    {
        // take all our major controls sections and space them evenly across the area we have

        NSArray *arrayControls = @[self.labelTitlePublicAddress,
                                   self.viewPublicAddress,
                                   self.labelTitlePrivateKey,
                                   self.viewPrivateKey,
                                   self.viewButtons,
                                   self.buttonDone];

        CGFloat needToFit = self.viewDisplayArea.frame.size.height;
        CGFloat totalSizeUsed = 0;
        for (UIView *curView in arrayControls)
        {
            totalSizeUsed += curView.frame.size.height;
        }

        CGFloat spacing = (needToFit - totalSizeUsed) / ([arrayControls count] + 2);

        //NSLog(@"needToFit: %f, totalSizeUsed: %f, spacing: %f", needToFit, totalSizeUsed, spacing);

        for (int i = 0; i < [arrayControls count]; i++)
        {
            UIView *curView = [arrayControls objectAtIndex:i];
            CGRect frame = curView.frame;
            CGFloat newY = spacing;

            if (i > 0)
            {
                UIView *prevView = [arrayControls objectAtIndex:i - 1];
                newY = prevView.frame.origin.y + prevView.frame.size.height + spacing;
            }
            frame.origin.y = newY;
            curView.frame = frame;
        }
    }
}

- (UIImage *)dataToImage:(const unsigned char *)data withWidth:(int)width andHeight:(int)height
{
	//converts raw monochrome bitmap data (each byte is a 1 or a 0 representing a pixel) into a UIImage
	char *pixels = malloc(4 * width * width);
	char *buf = pixels;

	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			if (data[(y * width) + x] & 0x1)
			{
                /*
                // black
				//printf("%c", '*');
				*buf++ = 0;
				*buf++ = 0;
				*buf++ = 0;
				*buf++ = 255;
                 */
                // white
                *buf++ = 255;
                *buf++ = 255;
                *buf++ = 255;
                *buf++ = 255;
			}
			else
			{
                /*
                // white
				//printf(" ");
				*buf++ = 255;
				*buf++ = 255;
				*buf++ = 255;
				*buf++ = 255;
                 */
                // clear
                *buf++ = 0;
				*buf++ = 0;
				*buf++ = 0;
				*buf++ = 0;
			}
		}
		//printf("\n");
	}

	CGContextRef ctx;
	CGImageRef imageRef;

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	ctx = CGBitmapContextCreate(pixels,
								(float)width,
								(float)height,
								8,
								width * 4,
								colorSpace,
								(CGBitmapInfo)kCGImageAlphaPremultipliedLast ); //documentation says this is OK
	CGColorSpaceRelease(colorSpace);
	imageRef = CGBitmapContextCreateImage (ctx);
	UIImage* rawImage = [UIImage imageWithCGImage:imageRef];

	CGContextRelease(ctx);
	CGImageRelease(imageRef);
	free(pixels);
	return rawImage;
}

- (void)animatedExit
{
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.view.frame;
		 frame.origin.x = frame.size.width;
		 self.view.frame = frame;
	 }
                     completion:^(BOOL finished)
	 {
		 [self exit];
	 }];
}

- (void)exit
{
	[self.delegate offlineWalletViewControllerDidFinish:self];
}

@end
