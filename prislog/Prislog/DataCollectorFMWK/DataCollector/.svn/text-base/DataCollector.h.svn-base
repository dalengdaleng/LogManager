//
//  DataCollector.h
//  DataCollector
//
//  Created by lvsheng on 11-11-3.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAIN_SERVER_URL @"http://analytics.hz.netease.com:8084/locate"

#define BUILD_FOR_PRIS

/*
 * 心跳信息 发送事件宏定义
 */
#define HEARTBEAT_INTERVAL  60*30
#define TIMER_INTERVAL      60*10
#define MIN_INTERVAL        10

/*
 * 统计协议版本
 */
#define ProtocolVersion @"1.8.1"

// 本模块的开关状态：只记不发、不记不发，记且发
typedef enum _ModuleStatus {
    MS_NoLogNoSend = 0,
    MS_LogNoSend = 1,
    MS_LogAndSend = 2   
} ModuleStatus;

@interface DataCollector : NSObject{
}

+ (void)openLog;
+ (void)openLogDebug;
/**
 @param product,    product name
 @param ver,        product version
 @param buildVer,   build version
 @param macAddr,    mac address format @"%02x:%02x:%02x:%02x:%02x:%02x"
 @param idDebug, the debug mode will add a debug header to identify the data, post to server, is debug data.

 @discussion
 initialize module, productName and productVersion must be given
 including register system event, and add message header, e.g. application name and application version
 */
+ (void)startWithProduct:(NSString *)productName
                     ver:(NSString *)productVer
                buildVer:(NSString *)buildVer
                     mac:(NSString *)macAddr
                   debug:(BOOL)isDebug;
+ (void)sendEventsImmediate;// method used to send events in the memory

+ (void)setMacAddress:(NSString *)macAddr;

+ (void)setAccount:(NSString *)accountName userId:(NSString *)userId;


/******************************************************/
#pragma mark - methods used to log event
/**
 @brief enable or disable the module
 
 @param status, 0 represent enable, otherwise represent disable
 */
+ (void)switchModuleStatus:(ModuleStatus)status;

/**
 @brief return the value of the switch
 
 @return module status represented with ModuleStatus enum;
 */
+ (ModuleStatus)currentModuleStatus;

/**
 @brief log application version.
 
 @param productVersion, the verion of current product
 */
+ (void)setApplicationVersion: (NSString *) productVersion; 

/**
 @brief log XMID, where the application will be published, e.g. AppStore, WeiPhone.com
 
 @param XMID, the ID where product published
 */
+ (void)setXMID: (NSString *) XMID; 

/**
 @brief log application upgrade event
 
 @param currVersion, the verion of current product
 @param newVersion, the destination version of upgrading
 */
+ (void)logEventUpgradeApp:(NSString *)currVersion toVer:(NSString *)newVersion;

/**
 @brief log user login
 
 @param accountName, the account name to login, must given
 @param userId, the userid of the account, must given
 */
+ (void)logEventLoginWithAccount:(NSString *)accountName userId:(NSString *)userId;

/**
 @brief log user logout
 
 @param accountName, the account name to log out, must given
 @param userId, the userid of the account, must given
 */
+ (void)logEventLogoutAccount:(NSString *)accountName userId:(NSString *)userId;

/**
 @brief log user signup within the application.
 */
+ (void)logEventSignup;

/**
 @brief log user page-access flow of the application.
 
 @param pageTo, the target page
 @param currentPage, the current page
 */
+ (void)logEventPageTo:(NSString *)pageTo fromPage:(NSString *)currentPage;

/**
 @brief log error events
 
 @param errorCode, the ID of the error
 @param errorMessage, the infomation of error
 */
+ (void)logError:(NSString *)errorCode message:(NSString *)errorMessage;

/**
 @brief log events that not include in the methods above.
 
 @param eventName, the custom event name
 @param parameters, the infomation of the custom event with key and value
 */
+ (void)logCustomEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters;

/**
 @brief log events that not include in the methods above, with start and cost time.
 
 @param eventName, the custom event name
 @param parameters, the infomation of the custom event with key and value
 @param sTime, the start time of the event
 @param timeSec, the millionseconds cost on the event
 */
+ (void)logCustomEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters startTime:(long long)sTime costTime:(long long)timeInMilliSec;

/**
 @brief log custome events that sent immediately once logged
 
 @param eventName, the custom event name
 @param parameters, the infomation of the custom event with key and value
 */
+ (void)logInstantCustomEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters;

/**
 @brief log custome events that sent immediately once logged
 
 @param eventName, the custom event name
 @param parameters, the infomation of the custom event with key and value
 @param sTime, the start time of the event
 @param timeSec, the millionseconds cost on the event
 */
+ (void)logInstantCustomEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters startTime:(long long)sTime costTime:(long long)timeInMilliSec;

/**
 @brief called when Timing-Event start, holding a start-time of the custom event with the event name and uid.
         
 @param eventName, the custom event name
 @param uid, the id the identify the custom event with the same event name
 @param parameters, the infomation of the custom event with key and value
 */
+ (void)logTimedEventStart:(NSString *)eventName withUniqueID: (NSString *)uid withParameters:(NSDictionary *)parameters;

/**
 @brief called when Timing-Event end.
 
 @param eventName, the custom event name
 @param uid, the id the identify the custom event with the same event name
 @param parameters, the infomation of the custom event with key and value
 */
+ (void)logTimedEventEnd:(NSString *)eventName withUniqueID:(NSString *)uid withParameters:(NSDictionary *)parameters;


/**
 @brief these are weird Interfaces
 
 **/
+ (void)notifyAppDidEnterBackground;
+ (void)notifyAppDidFinishLaunching;
+ (void)notifyAppWillEnterForeground;
+ (void)notifyAppWillTerminate;
@end