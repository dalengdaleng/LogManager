//
//  DataCollector.m
//  DataCollector
//
//  Created by lvsheng on 11-11-3.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "DataCollector.h"
#import "SystemMonitor.h"
#import "EventManager.h"
#import "Event.h"
#import "DCUtil.h"

static DataCollector *dataCollector;

extern int DCKey;
extern int DCKeyDebug;
extern int gAdd_Debug_Header;

@interface DataCollector()
{
    @public
    NSString *_productName;
    NSString *_productVer;
    NSString *_buildVer;
}

@property(nonatomic, retain) SystemMonitor *sysMonitor;
@property(nonatomic, retain) NSMutableDictionary *allTimingEvents;

+ (void)setAccount:(NSString *)accountName;
+ (void)setUserId:(NSString *)userId;
@end

@implementation DataCollector

@synthesize sysMonitor = _sysMonitor;
@synthesize allTimingEvents = _timedEventDictionary;

- (id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    _sysMonitor = [[SystemMonitor alloc] init];
    self.allTimingEvents = [[[NSMutableDictionary alloc] init] autorelease];
    
    return self;
}

-(void)dealloc
{
    [_productName release];
    [_productVer release];
    [_buildVer release];
    [_sysMonitor release];
    [_timedEventDictionary release];
    [super dealloc]; 
}

- (void)start
{
    DCPrint(@"-------------Start-----------");
    
    // register application event monitor
    [[EventManager instance] addHeader:MSGHEADER_PRODUCT value:_productName];
    [[EventManager instance] addHeader:MSGHEADER_PRODUCT_VER value:_productVer];
    [[EventManager instance] addHeader:MSGHEADER_OS value:_buildVer];
#ifndef BUILD_FOR_PRIS
    [[dataCollector sysMonitor] registerAppEvent];
#endif
    [[dataCollector sysMonitor] startHeartBeat];
}

#pragma mark - external API
+ (void)openLog
{
    DCKey = 1;
}

+ (void)openLogDebug {
    DCKeyDebug = 1;
}

+ (void)setAccount:(NSString *)accountName userId:(NSString *)userId {
    [DataCollector setAccount:accountName];
    [DataCollector setUserId:userId];
}

+ (void)setAccount:(NSString *)accountName
{
    //4.8.6 出现一个crash，[DataCollector setAccount:]－－－[EventManager transformEventsToJson]－－－+[NSException raise:format:]
    //具体什么原因暂时无法确定，如果UI传accountName是nil，就会导致出问题，增加下面判断，如果是nil，accountName设置成@""
    if(accountName == nil)
    {
        accountName = @"";
    }
    //
    
    if ([DataCollector swithThread:_cmd object:accountName])
        return;
    
    NSString *currAccount = [[EventManager instance] currAccount];
    
    if (![currAccount isEqualToString:accountName])
        [[EventManager instance] transformEventsToJson];
    
    [[EventManager instance] setCurrAccount:accountName];
}

+ (void)setUserId:(NSString *)userId {
    if ([DataCollector swithThread:_cmd object:userId])
        return;
    
    [[EventManager instance] setCurrUserId:userId];
}

/*
 * initialize module, productName and productVersion must be given
 * including register system event, and add message header, e.g. application name and application version
 */
+ (void)startWithProduct:(NSString *)productName
                     ver:(NSString *)productVer
                buildVer:(NSString *)buildVer
                     mac:(NSString *)macAddr
                   debug:(BOOL)isDebug
{
    if (!productName || !productVer || !buildVer) {
        return;
    }
    
    if(dataCollector == nil) {
        dataCollector = [[DataCollector alloc] init];
        dataCollector->_productName = [productName retain];
        dataCollector->_productVer = [productVer retain];
        dataCollector->_buildVer = [buildVer retain];
        if (macAddr) {
            [[EventManager instance] addHeader:MSGHEADER_MAC value:macAddr];
        }else{
            DCPrint(@"start with nil mac address string");
        }
    }else{
        DCPrint(@"already started!",nil);
    }
    
    if (isDebug) {
        gAdd_Debug_Header = 1;
    }
    
    NSThread *thread = [EventManager threadForOperation];
    if ([NSThread currentThread] != thread)
    {
        [dataCollector performSelector:@selector(start) onThread:thread withObject:nil waitUntilDone:NO];
    }else{
        [dataCollector start];
    }
}

+ (void)setMacAddress:(NSString *)macAddr
{
    if (macAddr && ![macAddr isEqualToString:@""]) {
        [[EventManager instance] addHeader:MSGHEADER_MAC value:macAddr];
    }
}

/**
 @discussion, 接口的线程切换
 
 @return, YES,执行了perform selector；NO,已经是该线程
 */
+ (BOOL)swithThread:(SEL)selector object:(id)arg
{
    NSThread * thread = [EventManager threadForOperation];
    if ([NSThread currentThread] != thread)
    {
        [self performSelector:selector onThread:thread withObject:arg waitUntilDone:NO];
        return YES;
    }
    return NO;
}

/*
 * method used to send events in the memory
 */
+ (void)sendEventsImmediate
{
    if ([DataCollector swithThread:_cmd object:nil])
        return;
    
    if (![[EventManager instance] isNeedSend]){
        return;
    }
    [[EventManager instance] postMessageWithEventType:ImmediateSend];
}

+ (void)switchModuleStatus:(ModuleStatus)status
{
    // run on main thread
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:[NSNumber numberWithInt:status] forKey:USER_SWITCH_KEY];

    [[EventManager instance] setModuleStatus:status];
}

+ (ModuleStatus)currentModuleStatus
{
    return [[EventManager instance] moduleStatus];
}
/*
 * set product version field in the message header
 */
+ (void)setApplicationVersion: (NSString *)appVersion
{
    if ([DataCollector swithThread:_cmd object:appVersion])
        return;
    
    [[EventManager instance] addHeader:MSGHEADER_PRODUCT_VER value:appVersion];
}

/*
 * log XMID, where the application will be published, e.g. AppStore, WeiPhone.com.
 */
+ (void)setXMID: (NSString *)XMID
{    
    if ([DataCollector swithThread:_cmd object:(XMID==nil?@"":XMID)])
        return;
    
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    [[EventManager instance] addHeader:MSGHEADER_XMID value:XMID];
}

#pragma mark - log 方法
/*
 * log application upgrade event
 */
+ (void)logEventUpgradeApp:(NSString *)currVersion toVer:(NSString *)newVersion
{
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    // create an upgrade event
    Event *upgradeEvent = [[Event alloc] initWithEventName:@"autoupdate"] ;
    
    // build the event body
    NSMutableDictionary *eventBody = [[NSMutableDictionary alloc] init] ;
    [eventBody setValue:currVersion forKey:EVENT_UPGRADE_OLD_VERSION];
    [eventBody setValue:newVersion forKey:EVENT_UPGRADE_NEW_VERSION];
    [upgradeEvent setEventBody:eventBody];
    
    // pass the event to manager
    [[EventManager instance] performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:upgradeEvent waitUntilDone:NO];
    
    [eventBody release];
    [upgradeEvent release];
}

// login event
+ (void)logEventLoginWithAccount:(NSString *)accountName userId:(NSString *)userId
{
    if (!accountName || !userId) {
        return;
    }
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    
    [[EventManager instance] setCurrAccount:accountName];
    [[EventManager instance] setCurrUserId:userId];
    
    // create an login event
    Event *loginEvent = [[Event alloc] initWithEventName:@"login"];
    
    // build the event body
    NSMutableDictionary *eventBody = [[NSMutableDictionary alloc] init];
    [eventBody setValue:accountName forKey:EVENT_LOGIN_ACCOUNT];
    [eventBody setValue:userId forKey:EVENT_LOGIN_USERID];
    [eventBody setValue:[DCUtil getCarrier] forKey:EVENT_LOGIN_MNO];
    [eventBody setValue:[[EventManager instance] getNetworkType] forKey:EVENT_LOGIN_NETWORK_TYPE];
    [loginEvent setEventBody:eventBody];
    
    // pass the event to manager
    [[EventManager instance] performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:loginEvent waitUntilDone:NO];
    
    [eventBody release];
    [loginEvent release];
    
}

// log user signup within the application
+ (void)logEventLogoutAccount:(NSString *)accountName userId:(NSString *)userId
{
    if (!accountName) {
        return;
    }
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    // create an logout event
    Event *logoutEvent = [[Event alloc] initWithEventName:@"logout"] ;
    
    // build the event body
    NSMutableDictionary *eventBody = [[NSMutableDictionary alloc] init] ;
    [eventBody setValue:accountName forKey:EVENT_LOGOUT_ACCOUNT];
    [eventBody setValue:userId forKey:EVENT_LOGOUT_USERID];
    [logoutEvent setEventBody:eventBody];
    
    // pass the event to manager
    [[EventManager instance] performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:logoutEvent waitUntilDone:NO];
    
    [eventBody release];
    [logoutEvent release];
}

/*
 * log user signup within the application
 */
+ (void)logEventSignup
{
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    
    // create an signup event
    Event *signupEvent = [[Event alloc] initWithEventName:@"signup"];
    
    // pass the event to manager
    [[EventManager instance] performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:signupEvent waitUntilDone:NO];
    
    [signupEvent release];
}

/*
 * log user page+access flow of the application
 */
+ (void)logEventPageTo:(NSString *)pageTo fromPage:(NSString *)currentPage
{
    if (!pageTo) {
        return;
    }
    
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    // create an page access event
    Event *pageAccessEvent = [[Event alloc] initWithEventName:@"Pagevisit"];
    
    // build the event body
    NSMutableDictionary *eventBody = [[NSMutableDictionary alloc] init];
    [eventBody setValue:currentPage forKey:EVENT_PAGEACCESS_CURRPAGE];
    if (currentPage != nil) {
        [eventBody setValue:pageTo forKey:EVENT_PAGEACCESS_TOPAGE];
    }
    [pageAccessEvent setEventBody:eventBody];
    
    // pass the event to manager
    [[EventManager instance]  performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:pageAccessEvent waitUntilDone:NO];
    
    [eventBody release];
    [pageAccessEvent release];
}

/*
 *  log error information
 */
+ (void)logError:(NSString *)errorCode message:(NSString *)errorMessage
{
    if (!errorCode || !errorMessage) {
        return;
    }
    
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    // create an error event
    Event *errorEvent = [[Event alloc] initWithEventName:@"error"];
    
    // build the event body
    NSMutableDictionary *eventBody = [[NSMutableDictionary alloc] init];
    [eventBody setValue:errorCode forKey:EVENT_ERROR_ERRCODE];
    [eventBody setValue:errorMessage forKey:EVENT_ERROR_ERRMSG];
    [errorEvent setEventBody:eventBody];
    
    // pass the event to manager
    [[EventManager instance]  performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:errorEvent waitUntilDone:NO];
    
    [eventBody release];
    [errorEvent release];
}

/*
 * log custom event
 */
+ (void)logCustomEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters;
{
    if (!eventName) {
        return;
    }
    
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    
    Event *customeEvent = [[Event alloc] initWithEventName:eventName] ;
    
    // build the event body
    [customeEvent setEventBody:[NSMutableDictionary dictionaryWithDictionary: parameters]];
    
    // pass the event to manager
    [[EventManager instance]  performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:customeEvent waitUntilDone:NO];
    
    [customeEvent release];
}

/**
 * log custom event
 */
+ (void)logCustomEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters startTime:(long long)sTime costTime:(long long)timeInMilliSec
{
    if (!eventName) {
        return;
    }
    
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    
    Event *customeEvent = [[Event alloc] initWithEventName:eventName] ;
    
    [customeEvent setEventCostTime:timeInMilliSec];
    [customeEvent setEventOpTime:sTime]; // 这里特殊之处，统计加入的时间并非事件发生的事件,所以单独设置
    
    // build the event body
    [customeEvent setEventBody:[NSMutableDictionary dictionaryWithDictionary: parameters]];
    
    // pass the event to manager
    [[EventManager instance]  performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:customeEvent waitUntilDone:NO];
    
    [customeEvent release];
}

/**
 @brief log custome events that sent immediately once logged
 
 @param eventName, the custom event name
 @param parameters, the infomation of the custom event with key and value
 */
+ (void)logInstantCustomEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters {
    if (!eventName) {
        return;
    }
    
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    
    Event *customeEvent = [[Event alloc] initWithEventName:eventName] ;
    
    // build the event body
    [customeEvent setEventBody:[NSMutableDictionary dictionaryWithDictionary: parameters]];
    
    // pass the event to manager
    [[EventManager instance]  performSelector:@selector(sendInstantEvent:) onThread:[EventManager threadForOperation] withObject:customeEvent waitUntilDone:NO];
    
    [customeEvent release];
}

/**
 @brief log custome events that sent immediately once logged
 
 @param eventName, the custom event name
 @param parameters, the infomation of the custom event with key and value
 */
+ (void)logInstantCustomEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters startTime:(long long)sTime costTime:(long long)timeInMilliSec
{
    if (!eventName) {
        return;
    }
    
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    
    Event *customeEvent = [[Event alloc] initWithEventName:eventName] ;
    
    [customeEvent setEventCostTime:timeInMilliSec];
    [customeEvent setEventOpTime:sTime]; // 这里特殊之处，统计加入的时间并非事件发生的事件,所以单独设置
    
    // build the event body
    [customeEvent setEventBody:[NSMutableDictionary dictionaryWithDictionary: parameters]];
    
    // pass the event to manager
    [[EventManager instance]  performSelector:@selector(sendInstantEvent:) onThread:[EventManager threadForOperation] withObject:customeEvent waitUntilDone:NO];
    
    [customeEvent release];
}

+ (void)logTimedEventStart:(NSString *)eventName withUniqueID: (NSString *)uid withParameters:(NSDictionary *)parameters
{
    if (!eventName || !uid) {
        return;
    }
    
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    
    @synchronized([dataCollector allTimingEvents])
    {       
        if ([[dataCollector allTimingEvents] valueForKey:eventName] == nil) 
        {
            Event *timedCustomEvent = [[Event alloc] initWithEventName:eventName];
            
            // set start time of timed event with uid as the key
            [[timedCustomEvent timedEventInfoDictionary] setValue:[NSDate date] forKey:uid];
            [[dataCollector allTimingEvents] setValue:timedCustomEvent forKey:eventName];
            [timedCustomEvent release];
        }else{
            Event *evt = [[dataCollector allTimingEvents] valueForKey:eventName];
            [[evt timedEventInfoDictionary] setValue:[NSDate date] forKey:uid];
        }
        
    }

}

+ (void)logTimedEventEnd:(NSString *)eventName withUniqueID: (NSString *)uid withParameters:(NSDictionary *)parameters
{
    if (!eventName || !uid) {
        return;
    }
    
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    
    @synchronized([dataCollector allTimingEvents])
    { 
        // get the specific timed event
        Event *timedCustomEvent = (Event *)[[dataCollector allTimingEvents] valueForKey:eventName];
        
        if (timedCustomEvent == nil) {
            NSString *str = [NSString stringWithFormat:@"没有对应的计时事件\"%@\"uid\"%@\"", eventName, uid];
            DCPrint(str,nil);
            return;
        }
        
        NSDate *startTime  = [[timedCustomEvent timedEventInfoDictionary] valueForKey:uid];
        
        if (startTime == nil) {
            NSString *str = [NSString stringWithFormat:@"对应的计时事件\"%@\"uid\"%@\",没有该uid对应的start time", eventName,uid];
            DCPrint(str, nil);
            return;
        }
        
        // compute the time interval since start-time
        NSTimeInterval timeInterval = [startTime timeIntervalSinceNow];
        
        // set event header
        [timedCustomEvent setEventOpTime:[DCUtil timeToMillionSecond:startTime]];
        [timedCustomEvent setEventCostTime:(long long)(-timeInterval*1000)];// Time interval unit is milliseconds 
        
        // set event body
        [timedCustomEvent setEventBody:[NSMutableDictionary dictionaryWithDictionary: parameters]];
        [[EventManager instance]  performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:timedCustomEvent waitUntilDone:NO];
        
        // remove the item in event
        [[timedCustomEvent timedEventInfoDictionary] removeObjectForKey:uid];
        
        // if there's no more item in the event, remove it from timing event array
        if( [[timedCustomEvent timedEventInfoDictionary] count] == 0)
        {
            // remove from array which stores timing events
            [[dataCollector allTimingEvents] removeObjectForKey:eventName];
        }

    }
}

/*
 * unused!
 */
+ (void)endAllTimedEvent
{
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    
    @synchronized([dataCollector allTimingEvents])
    { 
        for (Event *evt in [[dataCollector allTimingEvents] allValues]) 
        {
            NSArray *allKeys = [[evt timedEventInfoDictionary] allKeys];
            // get the specific timed event
            for (NSString *uid in allKeys) 
            {
                NSDate *startTime = [[evt timedEventInfoDictionary] valueForKey:uid];
                
                Event *endEvent = [[Event alloc] initWithEventName:[evt eventName]];
                
                // compute the time interval since start-time
                NSTimeInterval timeInterval = [startTime timeIntervalSinceNow];
                // convert startTime to string                
                // set event header
                [endEvent setEventOpTime:[DCUtil timeToMillionSecond:startTime]];
                [endEvent setEventCostTime:(long long)(-timeInterval*1000)];
                [[EventManager instance]  performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:endEvent waitUntilDone:NO];
                
                [endEvent release];
            }
            // remove from array which stores timing events
            [[dataCollector allTimingEvents] removeObjectForKey:[evt eventName]];
        }
    }
}

#pragma mark - receive app event
+ (void)notifyAppDidEnterBackground
{
#ifdef BUILD_FOR_PRIS
    [dataCollector.sysMonitor appDidEnterBackground:nil];
#endif
}

/*
 * Terminate
 */
+ (void)notifyAppWillTerminate
{
#ifdef BUILD_FOR_PRIS
    [dataCollector.sysMonitor appWillTerminate:nil];
#endif
}

/*
 * launch
 */
+ (void)notifyAppDidFinishLaunching
{
#ifdef BUILD_FOR_PRIS
    [dataCollector.sysMonitor appDidFinishLaunchingWithOptions:nil];
#endif
}

/*
 * switch to front
 */
+ (void)notifyAppWillEnterForeground
{
#ifdef BUILD_FOR_PRIS
    [dataCollector.sysMonitor appWillEnterForeground:nil];
#endif
}
@end
