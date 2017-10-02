//
//  PluginCell.m
//  AirBitz
//

#import "PluginCell.h"
#import "CommonTypes.h"
#import "Theme.h"

@implementation PluginCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setThemeValues];
    }
    return self;
}

- (void)setThemeValues {
    self.topLabel.textColor = [Theme Singleton].colorDarkGray;
    self.bottomLabel.textColor = [Theme Singleton].colorMidPrimary;
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
	//changes default reorder control image to our image.  This is a hack since iOS provides no way for us to do this via public APIs
	//can likely break in future iOS releases...
	
    [super setEditing: editing animated: YES];
}

@end
