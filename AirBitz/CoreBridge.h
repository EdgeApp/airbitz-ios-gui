//
//  CoreBridge.h
//  AirBitz
//

#import "ABC.h"
#import "Wallet.h"


@interface CoreBridge : NSObject

+ (void)loadWallets: (NSMutableArray *) arrayWallets archived:(NSMutableArray *) arrayArchivedWallets;
+ (void)reloadWallet: (Wallet *) wallet;
+ (NSMutableArray *)searchTransactionsIn: (Wallet *) wallet query:(NSString *)term addTo:(NSMutableArray *) arrayTransactions;
+ (bool)setWalletAttributes: (Wallet *) wallet;
+ (bool)storeTransaction: (Transaction *) transaction;
+ (NSString *)formatCurrency: (double) currency;
+ (NSString *)formatCurrency: (double) currency withSymbol:(bool) symbol;
+ (NSString *)formatSatoshi: (double) bitcoin;
+ (NSString *)formatSatoshi: (double) bitcoin withSymbol:(bool) symbol;
+ (double) denominationToSatoshi: (double) coin;
+ (NSString *)conversionString: (int) currencyNumber;

@end
