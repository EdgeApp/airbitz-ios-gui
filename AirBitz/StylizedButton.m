//
//  StylizedButton.m
//  AirBitz
//

#import "StylizedButton.h"

@implementation StylizedButton

-(void)initMyVariables
{
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.layer.cornerRadius = 10;
    self.clipsToBounds = YES;
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
