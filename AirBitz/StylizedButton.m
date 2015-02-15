//
//  StylizedButton.m
//  AirBitz
//

#import "StylizedButton.h"

@implementation StylizedButton

-(void)initMyVariables
{
//    self.layer.borderWidth = 0.0f;
//    self.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.layer.cornerRadius = 5;
    self.clipsToBounds = NO;
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    
    if ([self.backgroundColor respondsToSelector:@selector(getRed:green:blue:alpha:)])
    {
        [self.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];

#define SHADOW_COLOR_OFFSET 0.8
        
        red *= SHADOW_COLOR_OFFSET;
        red *= SHADOW_COLOR_OFFSET;
        red *= SHADOW_COLOR_OFFSET;
        
        self.layer.shadowColor = (__bridge CGColorRef)([UIColor colorWithRed:red green:green blue:blue alpha:alpha]);
        self.layer.shadowRadius = 5;
        self.layer.shadowOffset = CGSizeMake(0.0, 4.0);

    }
    
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