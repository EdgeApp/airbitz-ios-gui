//
//  StylizedButtonOutline.m
//  AirBitz
//

#import "StylizedButtonOutline.h"
#import "Util.h"

@implementation StylizedButtonOutline

-(void)initMyVariables
{
////    self.layer.borderWidth = 0.0f;
////    self.layer.borderColor = [[UIColor whiteColor] CGColor];
//    self.layer.cornerRadius = 5;
//    self.clipsToBounds = YES;
//    CGFloat myred = 0.0, mygreen = 0.0, myblue = 0.0, myalpha = 0.0;
//
////    if ([self.backgroundColor respondsToSelector:@selector(getRed:green:blue:alpha:)])
////    {
////        [self.backgroundColor getRed:&myred green:&mygreen blue:&myblue alpha:&myalpha];
////
////#define SHADOW_COLOR_OFFSET 0.5
////
//////        myred *= SHADOW_COLOR_OFFSET;
//////        mygreen *= SHADOW_COLOR_OFFSET;
//////        myblue *= SHADOW_COLOR_OFFSET;
//////        self.layer.shadowColor = (__bridge CGColorRef)([UIColor colorWithRed:red green:green blue:blue alpha:alpha]);
//////        self.layer.shadowRadius = 5;
//////        self.layer.shadowOffset = CGSizeMake(0.0, 4.0);
////
////        [self.layer setBorderColor:(__bridge CGColorRef)([UIColor colorWithRed:myred green:mygreen blue:myblue alpha:myalpha])];
////
////    }
////    else
//    {
//        [self.layer setBorderColor:(__bridge CGColorRef)([UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f])];
//    }
//    [self.layer setBackgroundColor:(__bridge CGColorRef)([UIColor clearColor])];
//    [self.layer setBorderWidth:1.0];
//    [self.layer setMasksToBounds:YES];
//

    CALayer *layer = self.layer;
    layer.cornerRadius = 5.0f;
    layer.masksToBounds = YES;
    layer.borderWidth = 1.0f;
    layer.borderColor = [UIColor colorWithWhite:1.0f alpha:1.0f].CGColor;
    layer.backgroundColor = [UIColor clearColor].CGColor;
    
    

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initMyVariables];
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self initMyVariables];
}

@end