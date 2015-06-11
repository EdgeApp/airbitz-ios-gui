//
//  SpendTarget.h
//  AirBitz
//

#import "ABC.h"

@interface SpendTarget : NSObject

@property (nonatomic) tABC_SpendTarget *pSpend;

- (id)init;
- (BOOL)newSpend:(NSString *)text error:(tABC_Error *)pError;
- (BOOL)newTransfer:(NSString *)walletUUID error:(tABC_Error *)pError;
- (BOOL)spendNewInternal:(NSString *)address label:(NSString *)label
                category:(NSString *)category notes:(NSString *)notes
           amountSatoshi:(uint64_t)amountSatoshi
                   error:(tABC_Error *)pError;
- (NSString *)approve:(NSString *)walletUUID
                 fiat:(double)fiatAmount
                error:(tABC_Error *)pError;

- (BOOL)isMutable;
- (uint64_t)maxSpendable:(NSString *)walletUUID;
- (tABC_Error)calcSendFees:(NSString *)walletUUID
                 totalFees:(uint64_t *)totalFees;

@end
