//
//  StylizedButtonOutline.m
//  AirBitz
//

#import "StylizedButtonOutline.h"
#import "Util.h"
#import "Theme.h"

@implementation StylizedButtonOutline

-(void)initMyVariables
{

    CALayer *layer = self.layer;
    layer.cornerRadius = 5.0f;
    layer.masksToBounds = YES;
    layer.borderWidth = 1.0f;
    layer.borderColor = [[Theme Singleton].colorTextDark CGColor];
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