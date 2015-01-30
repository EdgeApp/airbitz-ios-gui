
#import "ScanView.h
#import "ABC.h"
#import "Util.h"

@interface ScanView ()

@end

@implementation ScanView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

+ (ScanView *)CreateInsideView:(UIView *)parentView withDelegate:(id<FadingAlertViewDelegate>)delegate
{
	ScanView *view;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		view = [[[NSBundle mainBundle] loadNibNamed:@"ScanView~iphone" owner:nil options:nil] objectAtIndex:0];
	} else {
		view = [[[NSBundle mainBundle] loadNibNamed:@"ScanView~ipad" owner:nil options:nil] objectAtIndex:0];
	}
    view.alpha = 1.0;
	return view;
}


@end
