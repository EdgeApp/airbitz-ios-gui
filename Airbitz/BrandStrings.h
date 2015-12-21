//
//  BrandStrings.h
//
//
//  Created by Paul Puey on 2015/11/24.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#ifdef RACKWALLET

#define appTitle                @"Rack Wallet"
#define appHomepage             @"http://coinbtm.com"
#define supportEmail            @"support@coinbtm.com"
#define appStoreLink            @"https://itunes.apple.com/us/app/airbitz/id843536046"
#define playStoreLink           @"https://play.google.com/store/apps/details?id=com.airbitz"
#define appDownloadLink         @"http://coinbtm.com/app"
#define appLogoWhiteLink        @"https://airbitz.co/go/wp-content/uploads/2015/12/rack-logo-wht-100w.png"
#define appDesignedBy           NSLocalizedString(@"Designed by CoinBTM in",nil)
#define appCompanyLocation      NSLocalizedString(@"New York, New York, USA", nil)

#else

#define appTitle                @"Airbitz"
#define appHomepage             @"https://airbitz.co"
#define supportEmail            @"support@airbitz.co"
#define appStoreLink            @"https://itunes.apple.com/us/app/airbitz/id843536046"
#define playStoreLink           @"https://play.google.com/store/apps/details?id=com.airbitz"
#define appDownloadLink         @"https://airbitz.co/app"
#define appLogoWhiteLink        @"https://airbitz.co/static/img/logo-nav.png"
#define appDesignedBy           NSLocalizedString(@"Designed and Built by Airbitz in",nil)
#define appCompanyLocation      NSLocalizedString(@"San Diego, California, USA", nil)

#endif
