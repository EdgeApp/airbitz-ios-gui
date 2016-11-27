//
//  BrandStrings.m
//  Airbitz
//
//  Created by Paul P on 4/22/16.
//  Copyright © 2016 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>

#if AIRBITZ

#define appURI                  @"airbitz"
#define appTitle                @"Airbitz"
#define appHomepage             @"https://airbitz.co"
#define supportEmail            @"support@airbitz.co"
#define supportPhone            @"+1-844-928-9744"
#define supportTelegram         @"https://telegram.airbitz.co"
#define supportSlack            @"https://slack.airbitz.co"
#define supportWhatsapp         @"https://whatsapp.airbitz.co"
#define appStoreLink            @"https://itunes.apple.com/us/app/airbitz/id843536046"
#define playStoreLink           @"https://play.google.com/store/apps/details?id=com.airbitz"
#define appDownloadLink         @"https://airbitz.co/app"
#define appLogoWhiteLink        @"https://airbitz.co/static/img/logo-nav.png"
#define appDesignedBy           NSLocalizedString(@"Designed and Built by Airbitz in",nil)
#define appCompanyLocation      NSLocalizedString(@"San Diego, California, USA", nil)

#elif RACKWALLET

#define appURI                  @"airbitz"
#define appTitle                @"Rack Wallet"
#define appHomepage             @"http://rackwallet.com"
#define supportEmail            @"support@rackwallet.com"
#define supportPhone            @"+1-708-294-3371"
#define supportTelegram         @""
#define supportSlack            @""
#define supportWhatsapp         @""
#define appStoreLink            @"https://itunes.apple.com/us/app/rack-wallet/id1067132601"
#define playStoreLink           @"https://play.google.com/store/apps/details?id=com.coinbtm.rackwallet"
#define appDownloadLink         @"http://rackwallet.com/app"
#define appLogoWhiteLink        @"https://airbitz.co/go/wp-content/uploads/2015/12/rack-logo-wht-100w.png"
#define appDesignedBy           NSLocalizedString(@"Designed by Rack Ltd in",nil)
#define appCompanyLocation      NSLocalizedString(@"New York, New York, USA", nil)

#elif ATHENA

#define appURI                  @"airbitz"
#define appTitle                @"Athena Bitcoin"
#define appHomepage             @"http://athenabitcoin.com"
#define supportEmail            @"support@athenabitcoin.com"
#define supportPhone            @"+1-312-690-4466"
#define supportTelegram         @""
#define supportSlack            @""
#define supportWhatsapp         @""
#define appStoreLink            @"https://itunes.apple.com/us/app/athena-bitcoin/id1087704508"
#define playStoreLink           @"https://play.google.com/store/apps/details?id=com.athenabitcoin.wallet"
#define appDownloadLink         @"http://athenabitcoin.com/app"
#define appLogoWhiteLink        @"https://airbitz.co/go/wp-content/uploads/2016/02/Athena_Bitcoin_LOGO-01-white-100w.png"
#define appDesignedBy           NSLocalizedString(@"Designed by Athena Bitcoin in",nil)
#define appCompanyLocation      NSLocalizedString(@"Chicago, Illinois, USA", nil)

#elif COINSOURCE

#define appURI                  @"airbitz"
#define appTitle                @"Coinsource Bitcoin Wallet"
#define appHomepage             @"http://coinsource.net"
#define supportEmail            @"support@coinsource.net"
#define supportPhone            @"+1-805-500-2646"
#define supportTelegram         @""
#define supportSlack            @""
#define supportWhatsapp         @""
#define appStoreLink            @"https://itunes.apple.com/us/app/coinsource-bitcoin-wallet/id1089856071"
#define playStoreLink           @"https://play.google.com/store/apps/details?id=com.coinsource.wallet"
#define appDownloadLink         @"http://coinsource.net/app"
#define appLogoWhiteLink        @"https://airbitz.co/go/wp-content/uploads/2016/03/Coinsource-logo-100w.png"
#define appDesignedBy           NSLocalizedString(@"Designed by Coinsource in",nil)
#define appCompanyLocation      NSLocalizedString(@"New York, New York, USA", nil)

#endif

#ifndef AIRBITZ
#define AIRBITZ 0
#endif

#ifndef RACKWALLET
#define RACKWALLET 0
#endif

#ifndef ATHENA
#define ATHENA 0
#endif

#ifndef COINSOURCE
#define COINSOURCE 0
#endif

