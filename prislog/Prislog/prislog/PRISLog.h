//
//  PRISLog.h
//  PRIS
//
//  Created by huangxiaowei on 10-12-13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PRISLogLevel) {
    kPRISLogLevelEmergency    = 0,    // <M> Emergency: system is unusable
    kPRISLogLevelAlert        = 1,    // <A> Alert: action must be taken immediately
    kPRISLogLevelCritical     = 2,    // <C> Critical: critical conditions
    kPRISLogLevelError        = 3,    // <E> Error: error conditions
    kPRISLogLevelWarning      = 4,    // <W> Warning: warning conditions
    kPRISLogLevelNotice       = 5,    // <N> Notice: normal but significant condition
    kPRISLogLevelInfo         = 6,    // <I> Informational: informational messages
    kPRISLogLevelDebug        = 7     // <D> Debug: debug-level messages
};

#define LogEnable

#define PRISLog(x, ...)     PRISLogDebug(x, ## __VA_ARGS__);

#define FunctionInLog()     PRISLog(@"%s in", __FUNCTION__)
#define FunctionOutLog()    PRISLog(@"%s out", __FUNCTION__)

#define TickDebugStart 	long long startTick = [DateUtil currentTimeMillis]

#define TickDebugEnd        NSLog(@"%s cost %lld", __FUNCTION__, [DateUtil currentTimeMillis] - startTick)

FOUNDATION_EXTERN void PRISLogInit();
FOUNDATION_EXTERN void PRISLogUninit();
// Don't call this function directly, MUST use PRISLog macro definition instead.
FOUNDATION_EXTERN void PRISLogImpl(NSString *logStr);

FOUNDATION_EXTERN NSString *PRISLogGetLogFilepath();
FOUNDATION_EXTERN NSString *PRISLogGetLastlogFilepath();

FOUNDATION_EXTERN void PRISLogSetLogLevel(PRISLogLevel logLevel);  // Optional, default is kNELogLevelDebug

FOUNDATION_EXTERN void PRISLogEmergency(NSString *format, ...);
FOUNDATION_EXTERN void PRISLogAlert(NSString *format, ...);
FOUNDATION_EXTERN void PRISLogCritical(NSString *format, ...);
FOUNDATION_EXTERN void PRISLogError(NSString *format, ...);
FOUNDATION_EXTERN void PRISLogWarning(NSString *format, ...);
FOUNDATION_EXTERN void PRISLogNotice(NSString *format, ...);
FOUNDATION_EXTERN void PRISLogInfo(NSString *format, ...);
FOUNDATION_EXTERN void PRISLogDebug(NSString *format, ...);

