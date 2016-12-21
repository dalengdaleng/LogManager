//
//  PRISLog.m
//  PRIS
//
//  Created by huangxiaowei on 10-12-13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSFileManager.h>
#import <Foundation/NSFileHandle.h>
#import "PRISLog.h"
#import "CommInfo.h"

#define LogFileName             @"log.txt"
#define LastLogFileName         @"log_last.txt"
#define LogFileSize             (1024 * 1024 / 2) // 500K
#define kKeyPrisLogLevel        @"kKeyPrisLogLevel"

NSFileHandle *gFileHandle = nil;
NSLock *gLock = nil;
unsigned long long gFileSize = 0;
NSString *gLogFilepath = nil;
NSString *gLastlogFilepath = nil;

static PRISLogLevel s_nLogLevel = kPRISLogLevelDebug;

#ifndef PRIS_WRITE_LOG
#define PRIS_WRITE_LOG(level, format)     do {      \
    if (s_nLogLevel < level)                         \
        return;         \
    va_list argumentList;      \
    va_start(argumentList, format);\
    NSString *logStr = [[NSString alloc] initWithFormat:format arguments:argumentList];  \
    va_end(argumentList);          \
    PRISLogImpl(logStr);           \
} while(NO)
#endif

void PRISLogInit()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *libraryDir = [paths objectAtIndex:0];
    
    gLogFilepath = [libraryDir stringByAppendingPathComponent:LogFileName];
    gLastlogFilepath = [libraryDir stringByAppendingPathComponent:LastLogFileName];
    [gLogFilepath copy];
    [gLastlogFilepath copy];
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    // ensure log file exist.
    if ([fm fileExistsAtPath:gLogFilepath] == NO) 
    {
        if ([fm createFileAtPath:gLogFilepath contents:nil attributes:nil] == NO)
        {
            return;
        }
    }

    gFileHandle = [NSFileHandle fileHandleForWritingAtPath:gLogFilepath];
    if(gFileHandle == nil)
	{
		return;
	}
    [gFileHandle copy];
    [gFileHandle seekToEndOfFile];
    gFileSize = [gFileHandle offsetInFile];
    
    gLock = [[NSLock alloc] init];
    
    if (gFileSize > 0) 
    {
        // if already have some logs, insert a blank line.
        NSData *crlf = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
        [gFileHandle writeData:crlf];
    }

    NSString *str = (NSString *)[CommInfo getCustomObjectKey:kKeyPrisLogLevel];
    if (str)
    {
        s_nLogLevel = [str intValue];
    }
  
    PRISLogDebug(@"<-------------new log------------->");
}

void PRISLogUninit()
{
    [gFileHandle closeFile]; 
    
    gFileHandle = nil;

    gLock = nil;

    gLogFilepath = nil;

    gLastlogFilepath = nil;
    gFileSize = 0;
}

NSString * PRISLogGetLogFilepath()
{
    return gLogFilepath;
}

NSString * PRISLogGetLastlogFilepath()
{
    return gLastlogFilepath;
}

// need to synchronized.
void swapLogFile()
{
    @try 
    {
        [gFileHandle closeFile];
        gFileHandle =  nil;
        
        NSError *error ;
        NSFileManager *fm = [[NSFileManager alloc] init];
        [fm removeItemAtPath:gLastlogFilepath error:&error];
        [fm moveItemAtPath:gLogFilepath toPath:gLastlogFilepath error:&error];
        [fm createFileAtPath:gLogFilepath contents:nil attributes:nil];
        
        gFileHandle = [NSFileHandle fileHandleForWritingAtPath:gLogFilepath];
        [gFileHandle copy];
    }
    @catch (NSException *e) 
    {
        NSLog(@"swapLogFile exception: %@ %@", [e name],[e reason]);
    }
}

void PRISLogImpl(NSString *logStr)
{
#ifndef LogEnable
    return;
#endif
    
    // print to gdb windows
//#ifdef DATAENGINE_LOG_TO_CONSOLE
//if ([gDataEngine currentReachabilityStatus]!= JsmNotReachable){
//    NSLog(@"%@", logStr);
//    NSURLConnection *urlConnection;
//    NSMutableURLRequest *serverRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.sina.com.cn"] cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:10];
//    [serverRequest setHTTPMethod: @"POST"];
//    NSData *aData = [logStr dataUsingEncoding: NSUTF8StringEncoding];
//    [serverRequest setHTTPBody:aData];
//    urlConnection = [[NSURLConnection alloc]initWithRequest:serverRequest delegate:nil];
//    [urlConnection release];
//}
//#endif
    // print to log file
    if (gFileHandle == nil)
    {
        return;
    }
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

    NSString *logFileStr = [[NSString alloc] initWithFormat:@"%@[%@]: %@\r\n",dateStr,threadName,logStr];
    NSData *logFileData = [logFileStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [gLock lock];
    if (gFileSize > LogFileSize)
    {
        swapLogFile();
        gFileSize = 0;
    }
    @try 
    {
        [gFileHandle writeData:logFileData];
        gFileSize += [logFileData length];
    }
    @catch (NSException *e) 
    {
        NSLog(@"gFileHandle writedata exception %@ %@", [e name], [e reason]);
    }

    [gLock unlock];
}

void PRISLogSetLogLevel(PRISLogLevel logLevel)
{
    if (s_nLogLevel == logLevel)
        return;
    s_nLogLevel = logLevel;
    NSString *str = [NSString stringWithFormat:@"%d", s_nLogLevel];
    [CommInfo setCustomObjectKey:kKeyPrisLogLevel :str];
}

void PRISLogEmergency(NSString *format, ...)
{
    PRIS_WRITE_LOG(kPRISLogLevelEmergency, format);
}

void PRISLogAlert(NSString *format, ...)
{
    PRIS_WRITE_LOG(kPRISLogLevelAlert, format);
}

void PRISLogCritical(NSString *format, ...)
{
    PRIS_WRITE_LOG(kPRISLogLevelCritical, format);
}

void PRISLogError(NSString *format, ...)
{
    PRIS_WRITE_LOG(kPRISLogLevelError, format);
}

void PRISLogWarning(NSString *format, ...)
{
    PRIS_WRITE_LOG(kPRISLogLevelWarning, format);
}

void PRISLogNotice(NSString *format, ...)
{
    PRIS_WRITE_LOG(kPRISLogLevelNotice, format);
}

void PRISLogInfo(NSString *format, ...)
{
    PRIS_WRITE_LOG(kPRISLogLevelInfo, format);
}

void PRISLogDebug(NSString *format, ...)
{
    PRIS_WRITE_LOG(kPRISLogLevelDebug, format);
}
