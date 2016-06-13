//
//  TransactionsHeaderView.m
//  Airbitz
//
//  Created by Paul Puey on 6/12/16.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "TransactionsHeaderView.h"
#import "Theme.h"

@interface TransactionsHeaderView ()
{
}

@property (weak, nonatomic) IBOutlet UIView *mainView;

@end

@implementation TransactionsHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+(TransactionsHeaderView *)CreateWithTitle:(NSString *)title;
{
    TransactionsHeaderView *thv = nil;
    
    thv = [[[NSBundle mainBundle] loadNibNamed:@"TransactionsHeaderView~iphone" owner:nil options:nil] objectAtIndex:0];
    thv.titleLabel.text = title;
    [thv.mainView setBackgroundColor:[Theme Singleton].colorTransactionsHeader];
    
    return thv;
}
@end
