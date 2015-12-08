//
//  BuySellCell.h
//  AirBitz
//

#import <UIKit/UIKit.h>
#import "CommonCell.h"

@interface BuySellCell : CommonCell

@property (nonatomic, weak) IBOutlet UILabel *text;
@property (weak, nonatomic) IBOutlet UIImageView *buySellImage;

@end
