//
//  Util.m
//  Collector
//
//  Created by shinn on 12-1-5.
//  Copyright 2012年 __MyCompanyName__. All rights reserved.
//

#import "DCUtil.h"
#import "EventManager.h"
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

NSObject *gLockObj;
int DCKey = 0;
int DCKeyDebug = 0;

void DCPrintImpl(NSString *aFormat, ...)
{
    if (!DCKey) {
        return;
    }
    
    va_list argList;
	va_start(argList, aFormat);   
    NSString *logStr = [[NSString alloc] initWithFormat:aFormat arguments:argList];
    va_end(argList);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *threadName = [[NSThread currentThread] name];
    if ([threadName length] > 4) 
    {
        threadName = [threadName substringToIndex:4];
    }
	else if (threadName == nil)
	{
		threadName = @"null";
	}
    
    NSString *printStr = [[NSString alloc] initWithFormat:@"%@[%@]: %@\r\n",dateStr,threadName,logStr];
    NSLog(@"%@", printStr);
    
    
    //-- WRITE LOG SECTION --
    if (!gLockObj) {
        gLockObj = [[NSObject alloc] init];
    }
    @synchronized(gLockObj)
    {
        NSFileManager *fm = [EventManager getFileManager];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *libraryDir = [paths objectAtIndex:0];
        
        NSString *logFilePath = [libraryDir stringByAppendingPathComponent:@"DC.log"];
        
        if (![fm fileExistsAtPath:logFilePath]) {
            if (![fm createFileAtPath:logFilePath contents:nil attributes:nil]){
                return;
            }
        }
        
        NSFileHandle *fHandle;
        if(!(fHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath])){
            return;
        }
        
        [fHandle seekToEndOfFile];
        
        @try{
            [fHandle writeData:[printStr dataUsingEncoding:NSUTF8StringEncoding]];
        }
        @catch (NSException *e){
            NSLog(@"gFileHandle writedata exception %@ %@", [e name], [e reason]);
        }
    }
    // -- END WRITE LOG --
    
    [dateFormatter release];
    [logStr release];
    [printStr release]; 
    
}

void DCPrintImplDebug(NSString *aFormat, ...)
{
    if (!DCKeyDebug) {
        return;
    }
    
    va_list argList;
	va_start(argList, aFormat);
    NSString *logStr = [[NSString alloc] initWithFormat:aFormat arguments:argList];
    va_end(argList);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *threadName = [[NSThread currentThread] name];
    if ([threadName length] > 4)
    {
        threadName = [threadName substringToIndex:4];
    }
	else if (threadName == nil)
	{
		threadName = @"null";
	}
    
    NSString *printStr = [[NSString alloc] initWithFormat:@"统计:%@[%@]: %@\r\n",dateStr,threadName,logStr];
    NSLog(@"%@", printStr);
    
    
    //-- WRITE LOG SECTION --
    if (!gLockObj) {
        gLockObj = [[NSObject alloc] init];
    }
    @synchronized(gLockObj)
    {
        NSFileManager *fm = [EventManager getFileManager];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *libraryDir = [paths objectAtIndex:0];
        
        NSString *logFilePath = [libraryDir stringByAppendingPathComponent:@"DCDebug.log"];
        
        if (![fm fileExistsAtPath:logFilePath]) {
            if (![fm createFileAtPath:logFilePath contents:nil attributes:nil]){
                return;
            }
        }
        
        NSFileHandle *fHandle;
        if(!(fHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath])){
            return;
        }
        
        [fHandle seekToEndOfFile];
        
        @try{
            [fHandle writeData:[printStr dataUsingEncoding:NSUTF8StringEncoding]];
        }
        @catch (NSException *e){
            NSLog(@"gFileHandle writedata exception %@ %@", [e name], [e reason]);
        }
    }
    // -- END WRITE LOG --
    
    [dateFormatter release];
    [logStr release];
    [printStr release];
}

@implementation DCUtil

#pragma mark - util methods 
/*
 * encrypt data using custom 
 */
+(NSData *) encryptMessage:(NSData *) plainData
{
    NSMutableData *encryptedData = [NSMutableData dataWithData: plainData];
    Byte *pData = [encryptedData mutableBytes];
    
    // if data length < XOR_LEN, do encyption with the actual length
    for (int index = 0; index <([plainData length] < XOR_LEN?[plainData length]:XOR_LEN); index ++) 
    {
        // XOR
        *(pData+index) =  *(pData+index)^0xD2;
    }
    return  encryptedData;
}

+(NSData *)decryptMessage:(NSData *)encryptData;
{
    NSMutableData *plainData = [NSMutableData dataWithData: encryptData];
    Byte *pData = [plainData mutableBytes];
    
    // if data length < XOR_LEN, do encyption with the actual length
    for (int index = 0; index <([plainData length] < XOR_LEN?[plainData length]:XOR_LEN); index ++)
    {
        // XOR
        *(pData+index) =  *(pData+index)^0xD2;
    }
    return  [plainData gzipInflate];
}

/*
 * method to store data into file
 */
+(BOOL) writeFile:(NSData *) data
{
    NSFileManager *fileManager = [EventManager getFileManager];

    // variable that represents the directory and name
    NSString *homeDir = NSHomeDirectory();
    NSString *dstDir = [homeDir stringByAppendingString:RELATIVE_DIR];
    
    if(![fileManager fileExistsAtPath:dstDir]){
        [fileManager createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // 判断文件个数
    NSArray *oldFilesArray = [fileManager contentsOfDirectoryAtPath:dstDir error:nil];
    
    if (oldFilesArray.count > 10) {
        [fileManager removeItemAtPath:dstDir error:nil];
        [fileManager createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // get current time, used as part of file name
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmssSSS"];
    NSString *fileCreateTime=[formatter stringFromDate:[NSDate date]];
    [formatter release];
    
    // file name "file."+ time
    NSString *dstFilePath = [dstDir stringByAppendingString:[NSString stringWithFormat:@"file.%@",fileCreateTime]];
    if (![fileManager createFileAtPath:dstFilePath contents:data attributes:nil]) {
        return false;
    }
    DCPrint(@"Write File: %@", dstFilePath);
    
    return YES;
}

/*
 * 解压GZIP
 * 测试使用，用于查看发送到服务器的数据是否正确
 */
+ (NSData *) uncomressData:(NSData *)compressedData
{
    NSData * tmpData = [compressedData gzipDeflate];
    
    if ([tmpData length] == 0){
        return tmpData;
    }
    unsigned full_length = [tmpData length];
    unsigned half_length = [tmpData length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length +     half_length];
    BOOL done = NO;
    int status;

    z_stream strm;
    strm.next_in = (Bytef *)[tmpData bytes];
    strm.avail_in = [tmpData length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    
    while (!done){
        if (strm.total_out >= [decompressed length])
        {
            [decompressed increaseLengthBy: half_length];
        }
        
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = [decompressed length] - strm.total_out;
        // Inflate another chunk.
        
        status = inflate (&strm, Z_SYNC_FLUSH);
        
        if (status == Z_STREAM_END){
            done = YES;
        }
        else if (status != Z_OK)
        {
            break;
        }
    }
    
    if (inflateEnd (&strm) != Z_OK) {
        return nil;
    }
    
    if (done){
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    }
    
    return nil;
}
/*
 * compress data within GZIP
 */
+(NSData *) compressData:(NSData *) uncompressData
{ 
    /* 
     Special thanks to Robbie Hanson of Deusty Designs for sharing sample code 
     showing how deflateInit2() can be used to make zlib generate a compressed 
     file with gzip headers: 
     
     http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html 
     
     */  
    
    if (!uncompressData || [uncompressData length] == 0)  
    {  
        DCPrint(@"DtCltr:%s: Error: Can't compress an empty or null NSData object.", __func__);
        return nil;  
    }  
    
    /* Before we can begin compressing (aka "deflating") data using the zlib 
     functions, we must initialize zlib. Normally this is done by calling the 
     deflateInit() function; in this case, however, we'll use deflateInit2() so 
     that the compressed data will have gzip headers. This will make it easy to 
     decompress the data later using a tool like gunzip, WinZip, etc. 
     
     deflateInit2() accepts many parameters, the first of which is a C struct of 
     type "z_stream" defined in zlib.h. The properties of this struct are used to 
     control how the compression algorithms work. z_stream is also used to 
     maintain pointers to the "input" and "output" byte buffers (next_in/out) as 
     well as information about how many bytes have been processed, how many are 
     left to process, etc. */  
    z_stream zlibStreamStruct;  
    zlibStreamStruct.zalloc    = Z_NULL; // Set zalloc, zfree, and opaque to Z_NULL so  
    zlibStreamStruct.zfree     = Z_NULL; // that when we call deflateInit2 they will be  
    zlibStreamStruct.opaque    = Z_NULL; // updated to use default allocation functions.  
    zlibStreamStruct.total_out = 0; // Total number of output bytes produced so far  
    zlibStreamStruct.next_in   = (Bytef*)[uncompressData bytes]; // Pointer to input bytes  
    zlibStreamStruct.avail_in  = [uncompressData length]; // Number of input bytes left to process  
    
    /* Initialize the zlib deflation (i.e. compression) internals with deflateInit2(). 
     The parameters are as follows: 
     
     z_streamp strm - Pointer to a zstream struct 
     int level      - Compression level. Must be Z_DEFAULT_COMPRESSION, or between 
     0 and 9: 1 gives best speed, 9 gives best compression, 0 gives 
     no compression. 
     int method     - Compression method. Only method supported is "Z_DEFLATED". 
     int windowBits - Base two logarithm of the maximum window size (the size of 
     the history buffer). It should be in the range 8..15. Add 
     16 to windowBits to write a simple gzip header and trailer 
     around the compressed data instead of a zlib wrapper. The 
     gzip header will have no file name, no extra data, no comment, 
     no modification time (set to zero), no header crc, and the 
     operating system will be set to 255 (unknown). 
     int memLevel   - Amount of memory allocated for internal compression state. 
     1 uses minimum memory but is slow and reduces compression 
     ratio; 9 uses maximum memory for optimal speed. Default value 
     is 8. 
     int strategy   - Used to tune the compression algorithm. Use the value 
     Z_DEFAULT_STRATEGY for normal data, Z_FILTERED for data 
     produced by a filter (or predictor), or Z_HUFFMAN_ONLY to 
     force Huffman encoding only (no string match) */  
    int initError = deflateInit2(&zlibStreamStruct, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);  
    if (initError != Z_OK)  
    {  
        NSString *errorMsg = nil;  
        switch (initError)  
        {  
            case Z_STREAM_ERROR:  
                errorMsg = @"Invalid parameter passed in to function.";  
                break;  
            case Z_MEM_ERROR:  
                errorMsg = @"Insufficient memory.";  
                break;  
            case Z_VERSION_ERROR:  
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";  
                break;  
            default:  
                errorMsg = @"Unknown error code.";  
                break;  
        }  
        DCPrint(@"deflateInit2() Error: \"%@\" Message: \"%s\"", errorMsg, zlibStreamStruct.msg);  
        [errorMsg release];  
        return nil;  
    }  
    
    // Create output memory buffer for compressed data. The zlib documentation states that  
    // destination buffer size must be at least 0.1% larger than avail_in plus 12 bytes.  
    NSMutableData *compressedData = [NSMutableData dataWithLength:[uncompressData length] * 1.01 + 12];  
    
    int deflateStatus;  
    do  
    {  
        // Store location where next byte should be put in next_out  
        zlibStreamStruct.next_out = [compressedData mutableBytes] + zlibStreamStruct.total_out;  
        
        // Calculate the amount of remaining free space in the output buffer  
        // by subtracting the number of bytes that have been written so far  
        // from the buffer's total capacity  
        zlibStreamStruct.avail_out = [compressedData length] - zlibStreamStruct.total_out;  
        
        /* deflate() compresses as much data as possible, and stops/returns when 
         the input buffer becomes empty or the output buffer becomes full. If 
         deflate() returns Z_OK, it means that there are more bytes left to 
         compress in the input buffer but the output buffer is full; the output 
         buffer should be expanded and deflate should be called again (i.e., the 
         loop should continue to rune). If deflate() returns Z_STREAM_END, the 
         end of the input stream was reached (i.e.g, all of the data has been 
         compressed) and the loop should stop. */  
        deflateStatus = deflate(&zlibStreamStruct, Z_FINISH);  
        
    } while ( deflateStatus == Z_OK );        
    
    // Check for zlib error and convert code to usable error message if appropriate  
    if (deflateStatus != Z_STREAM_END)  
    {  
        NSString *errorMsg = nil;  
        switch (deflateStatus)  
        {  
            case Z_ERRNO:  
                errorMsg = @"Error occured while reading file.";  
                break;  
            case Z_STREAM_ERROR:  
                errorMsg = @"The stream state was inconsistent (e.g., next_in or next_out was NULL).";  
                break;  
            case Z_DATA_ERROR:  
                errorMsg = @"The deflate data was invalid or incomplete.";  
                break;  
            case Z_MEM_ERROR:  
                errorMsg = @"Memory could not be allocated for processing.";  
                break;  
            case Z_BUF_ERROR:  
                errorMsg = @"Ran out of output buffer for writing compressed bytes.";  
                break;  
            case Z_VERSION_ERROR:  
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";  
                break;  
            default:  
                errorMsg = @"Unknown error code.";  
                break;  
        }  
        DCPrint(@"zlib error while attempting compression: \"%@\" Message: \"%s\"", errorMsg, zlibStreamStruct.msg);  
        [errorMsg release];  
        
        // Free data structures that were dynamically created for the stream.  
        deflateEnd(&zlibStreamStruct);  
        
        return nil;  
    }  
    // Free data structures that were dynamically created for the stream.  
    deflateEnd(&zlibStreamStruct);  
    [compressedData setLength: zlibStreamStruct.total_out];  
    
    if ([compressedData length] < 1024) 
    {
        DCPrint(@"Compressed file from %d B to %d B", uncompressData.length, compressedData.length);  
    }else{
        DCPrint(@"Compressed file from %d KB to %d KB", uncompressData.length/1024, compressedData.length/1024);  
    }
    
    return compressedData;  
}

/*
 * return the carrier name
 */
+ (NSString*)getCarrier
{
    // Setup the Network Info and create a CTCarrier object
    CTTelephonyNetworkInfo *networkInfo = [[[CTTelephonyNetworkInfo alloc] init] autorelease];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    
    // Get carrier name
    NSString *carrierName = [carrier carrierName];
    
    if (carrierName != nil)
        DCPrint(@"Carrier: %@", carrierName);
    
    // Get mobile country code
    NSString *mcc = [carrier mobileCountryCode];
    if (mcc != nil)
        DCPrint(@"Mobile Country Code (MCC): %@", mcc);
    
    // Get mobile network code
    NSString *mnc = [carrier mobileNetworkCode];
    if (mnc != nil)
        DCPrint(@"Mobile Network Code (MNC): %@", mnc);
    return carrierName?carrierName:@"";
}

+ (long long)timeToMillionSecond:(NSDate *)date
{
    NSTimeInterval timeInterval= [date timeIntervalSince1970];
    return (long long)(timeInterval*1000);
}

+ (NSString *) macAddress{
    
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", 
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return outstring;
}

@end

@implementation NSData (NSDataExtension)

- (NSData *)gzipInflate
{
	if ([self length] == 0) return self;
	
	unsigned full_length = [self length];
	unsigned half_length = [self length] / 2;
	
	NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
	BOOL done = NO;
	int status;
	
	z_stream strm;
	strm.next_in = (Bytef *)[self bytes];
	strm.avail_in = [self length];
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	
	if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
	while (!done)
	{
		// Make sure we have enough room and reset the lengths.
		if (strm.total_out >= [decompressed length])
			[decompressed increaseLengthBy: half_length];
		strm.next_out = [decompressed mutableBytes] + strm.total_out;
		strm.avail_out = [decompressed length] - strm.total_out;
		
		// Inflate another chunk.
		status = inflate (&strm, Z_SYNC_FLUSH);
		if (status == Z_STREAM_END) done = YES;
		else if (status != Z_OK) break;
	}
	if (inflateEnd (&strm) != Z_OK) return nil;
	
	// Set real length.
	if (done)
	{
		[decompressed setLength: strm.total_out];
		return [NSData dataWithData: decompressed];
	}
	else return nil;
}

- (NSData *)gzipDeflate
{
	if ([self length] == 0) return self;
	
	z_stream strm;
	
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.total_out = 0;
	strm.next_in=(Bytef *)[self bytes];
	strm.avail_in = [self length];
	
	// Compresssion Levels:
	//   Z_NO_COMPRESSION
	//   Z_BEST_SPEED
	//   Z_BEST_COMPRESSION
	//   Z_DEFAULT_COMPRESSION
	
	if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
	
	NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
	
	do {
		
		if (strm.total_out >= [compressed length])
			[compressed increaseLengthBy: 16384];
		
		strm.next_out = [compressed mutableBytes] + strm.total_out;
		strm.avail_out = [compressed length] - strm.total_out;
		
		deflate(&strm, Z_FINISH);
		
	} while (strm.avail_out == 0);
	
	deflateEnd(&strm);
	
	[compressed setLength: strm.total_out];
	return [NSData dataWithData:compressed];
}

@end
