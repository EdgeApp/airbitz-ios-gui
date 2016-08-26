//
//  PluginCell.h
//  AirBitz
//

#import <UIKit/UIKit.h>
#import "CommonCell.h"

@interface PluginCell : CommonCell
@property (weak, nonatomic) IBOutlet LatoLabel *topLabel;
@property (weak, nonatomic) IBOutlet LatoLabel *bottomLabel;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UIImageView *rightImage;


@end
