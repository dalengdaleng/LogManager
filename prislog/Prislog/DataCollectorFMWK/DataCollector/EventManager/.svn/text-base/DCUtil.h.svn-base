//
//  Util.h
//  Collector
//
//  Created by shinn on 12-1-5.
//  Copyright 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// 打印宏
#define DCPrint(x, ...) DCPrintImpl(x, ## __VA_ARGS__);
void DCPrintImpl(NSString *aFormat, ...);

#define DCPrintDebug(x, ...) DCPrintImplDebug(x, ## __VA_ARGS__);
void DCPrintImplDebug(NSString *aFormat, ...);

@interface DCUtil : NSObject
/*
 * utility methods to compress data, encrypt data, write data
 */
+(NSData *)uncomressData:(NSData *)compressedData;
+(NSData *)compressData:(NSData *) uncompressData; // compress data within GZIP
+(NSData *)encryptMessage:(NSData *) plainData;// encrypt data using custom algorithm
+(NSData *)decryptMessage:(NSData *) encryptData;
+(BOOL) writeFile:(NSData *) data; // method to store data into file
+ (NSString*)getCarrier;// return the carrier name
+ (long long)timeToMillionSecond:(NSDate *)date;
+ (NSString *)macAddress;
@end

@interface NSData(NSDataExtension)
// GZIP
- (NSData *) gzipInflate;
- (NSData *) gzipDeflate;
@end