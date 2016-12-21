//
//  SystemMonitor.m
//  Collector
//
//  Created by lvsheng on 11-11-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SystemMonitor.h"

@implementation SystemMonitor

@synthesize heartBeatTimer = _heartBeatTimer;
@synthesize currentSystemEventType = _currentSystemEventType;

- (void)dealloc
{
    self.heartBeatTimer = nil;    
    [super dealloc];
}

#pragma mark - methods to add obersver for application notification and setup timer
/*
 * register system event notificaiton
 */ 
-(void) registerAppEvent
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // register callback for application event notification
    [nc addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [nc addObserver:self selector:@selector(appDidFinishLaunchingWithOptions:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [nc addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [nc addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [nc addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [nc addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)startHeartBeat
{
    if (![self heartBeatTimer]) {
        // register timer to check that it's time to send heartbeat message
        [self setHeartBeatTimer:[NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(handleHeartBeatTimer:) userInfo:nil repeats:YES]];
    }

}
/*
 * heartbeat NSTimer callback
 */
-(void)handleHeartBeatTimer:(id)sender
{
    [self checkHeartBeatTime];
}
/*
 * do the check if it's time to send heartbeat message
 */
-(void) checkHeartBeatTime
{
    NSDate *lastSendTime = [[EventManager instance] lastMessageSendTime];
    // is necessary??
    if (lastSendTime == nil) 
    {   // if lastSendTime equals nil, use current time
        [[EventManager instance] setLastMessageSendTime:[NSDate date]];
        return;
    }
    
    NSTimeInterval interval = [lastSendTime timeIntervalSinceNow];
    // it's time to send heartbeat message
    if (HEARTBEAT_INTERVAL < (-interval)) 
    {
        // 1. log event
        [self logEventHeartBeat];
        
        // 2. send the message
        [self sendSystemMessageWithEventType:HeartBeatSend];
      
    }
}

/*
 * start a background task, used when will enter background event arrived, to offer more time for sending message
 * the background task will be ended when receive HTTP 200 response
 * todo end the bgtask if time out!!
 */
-(void)startBgTask
{
    UIDevice* device = [UIDevice currentDevice];
	BOOL backgroundSupported = NO;
	
	if ([device respondsToSelector:@selector(isMultitaskingSupported)])
	{	
		backgroundSupported = device.multitaskingSupported;
	}
    
	if (backgroundSupported && _collectorBgTask==UIBackgroundTaskInvalid)
	{
	    UIApplication* app = [UIApplication sharedApplication];
		_collectorBgTask = [app beginBackgroundTaskWithExpirationHandler:^{
			DCPrint(@"background task %d ExpirationHandler fired remaining time %d.",_collectorBgTask, (int)app.backgroundTimeRemaining);
		}];	
		// Start the long-running task and return immediately.
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			// Do the work associated with the task.
			DCPrint(@"DtCltr:background task %d start time %d.", _collectorBgTask, (int)[app backgroundTimeRemaining]);
			while (app.applicationState==UIApplicationStateBackground && _collectorBgTask!=UIBackgroundTaskInvalid && [app backgroundTimeRemaining] > 10) 
			{
				[NSThread sleepForTimeInterval:1];
			}
            // if bgtask still valid, end the bgtask
            // reached when next time entering foreground or this background task have time < 10s
            if ( _collectorBgTask!=UIBackgroundTaskInvalid) {
                DCPrint(@"background task %d finished.", _collectorBgTask);
                [app endBackgroundTask:_collectorBgTask];
                _collectorBgTask = UIBackgroundTaskInvalid;
            }				
		});		
	}
}
/*
 * end the background that started within appDidEnterBackground:
 */
-(void)endCollectorBgTask
{
    // end the background task
    UIApplication* app = [UIApplication sharedApplication];
    DCPrint(@"DtCltr:collector background end", nil);
    [app endBackgroundTask:_collectorBgTask];
    _collectorBgTask = UIBackgroundTaskInvalid;
}

-(void) sendSystemMessageWithEventType:(SendActionType) type
{
    if (![[EventManager instance] isNeedSend]){
        return;
    }
    
    self.currentSystemEventType = type;
    
    if ([NSThread currentThread] == [EventManager threadForOperation])
    {
        [self performSendAction];
    }
    else{
        //保证在performSelector到另一线程之前，currentSystemEventType数据未被修改
        @synchronized(self){
            [self performSelector:@selector(performSendAction) onThread:[EventManager threadForOperation] withObject:nil waitUntilDone:YES];
        }
    }
}

/*
 * 无参数，解决performSelector无法带参数的问题
 */
-(void) performSendAction
{    
    [[EventManager instance] postMessageWithEventType:self.currentSystemEventType];
}

#pragma mark - application event notification callback metond
/*
 * callback of connection received the ok response
 */
-(void)sendSystemMessageSuccess:(id)sender
{
    // remove notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"EventMangerPostNewMessageFinish" object:nil];
    
    [self endCollectorBgTask];
}
/*
 *  switch to background
 */
- (void)appDidEnterBackground:(NSNotification*)notification
{
    NSThread *thread = [EventManager threadForOperation];
    if ([NSThread currentThread] != thread)
    {
        [self performSelector:_cmd onThread:thread withObject:notification waitUntilDone:NO];
        return;
    }
    DCPrint(@"app switch to background", nil);

    // start background task to get more time to send message
    [self startBgTask];
    
    // record time of this enter background
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:USR_DEFAULT_LAST_ENTER_BACK_TIME];
    
    // 1.log the application switch to background event
    [self logEventAppSwitchToMode:@"back"];
    
    // 2.send the message
    [self sendSystemMessageWithEventType:AppSwitchBackSend]; 
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendSystemMessageSuccess:) name:@"EventMangerPostNewMessageFinish" object:nil];
    
}

/*
 * Terminate
 */
- (void)appWillTerminate:(NSNotification*)notification
{
    NSThread *thread = [EventManager threadForOperation];
    if ([NSThread currentThread] != thread)
    {
        [self performSelector:_cmd onThread:thread withObject:notification waitUntilDone:NO];
        return;
    }
    [self logEventAppTerminate:nil];
    [self sendSystemMessageWithEventType:AppTerminateSend];
}

/*
 * launch
 */
- (void)appDidFinishLaunchingWithOptions:(NSNotification*)notification
{
    NSThread *thread = [EventManager threadForOperation];
    if ([NSThread currentThread] != thread)
    {
        [self performSelector:_cmd onThread:thread withObject:notification waitUntilDone:NO];
        return;
    }
    
    DCPrint(@"finish launching", nil);
    // 1.check if it's the first time login the app in the terminal
    NSUserDefaults *usrDefaults = [NSUserDefaults standardUserDefaults];
    if (![usrDefaults valueForKey:USR_DEFAULT_IS_FISRT_USE])
    {
        [self logEventAppActivate];
        [usrDefaults setValue:@"activated" forKey:USR_DEFAULT_IS_FISRT_USE];
        [usrDefaults synchronize];
    }    

    [self logEventAppLanuched];
    [self sendSystemMessageWithEventType:AppLaunchSend]; 
}

/*
 * switch to front
 */
- (void)appWillEnterForeground:(NSNotification*)notification
{
    NSThread *thread = [EventManager threadForOperation];
    if ([NSThread currentThread] != thread)
    {
        [self performSelector:_cmd onThread:thread withObject:notification waitUntilDone:NO];
        return;
    }
    
    DCPrint(@"app switch to foreground", nil);
    // 1.log the event: switch to front
    [self logEventAppSwitchToMode:@"front"];
    
    // 2.set the event type
    [[EventManager instance] setEventType:AppSwitchFrontSend];
    
    NSDate *lastEnterBackTime = [[NSUserDefaults standardUserDefaults] valueForKey:USR_DEFAULT_LAST_ENTER_BACK_TIME];
    
    NSTimeInterval interval = [lastEnterBackTime timeIntervalSinceNow];
    
    if (-interval > MIN_INTERVAL) 
    {  
        DCPrint(@"距上次切换后台大于10秒，检查并发送旧消息文件", nil);
        // send the old data
        [self sendSystemMessageWithEventType:AppSwitchFrontSend]; 
    } 
}
- (void)appDidBecomeActive:(NSNotification*)notification
{
}

- (void)appWillResignActive:(NSNotification*)notification
{
}

#pragma mark - log application event
/*
 * internal interfaces, methods called by system monitor, recording the various application events
 */
-(void)logEventHeartBeat
{
    // create an application heartbeat event
    Event *heartBeatEvent = [[Event alloc] initWithEventName:@"heartbeat"];
    
    // pass the event to manager
    [self addSystemEvent:heartBeatEvent];
    
    [heartBeatEvent release];
    DCPrint(@"log heartbeat", nil);
}

-(void)logEventAppActivate
{   
    // create an application activate event
    Event *activateEvent = [[Event alloc] initWithEventName:@"open"];
    
    // build the event body
    NSMutableDictionary *eventBody = [[NSMutableDictionary alloc] init];
    [eventBody setValue:[DCUtil getCarrier] forKey:EVENT_LOGIN_MNO];
    [eventBody setValue:[[EventManager instance] getNetworkType] forKey:EVENT_LOGIN_NETWORK_TYPE];
    [activateEvent setEventBody:eventBody];
    
    // pass the event to manager
    [self addSystemEvent:activateEvent];
    [eventBody release];
    [activateEvent release];
}

-(void)logEventAppLanuched
{    
    // create an application launch event
    Event *appLaunchEvent = [[Event alloc] initWithEventName:@"launch"];
    
    // pass the event to manager
    [self addSystemEvent:appLaunchEvent];
    
    [appLaunchEvent release];
}
-(void)logEventAppSwitchToMode:(NSString *) mode
{
    // create an application launch event
    Event *appSwitchEvent = [[Event alloc] initWithEventName:@"switch"];
    
    // build the event body
    NSMutableDictionary *eventBody = [[NSMutableDictionary alloc] init];
    [eventBody setValue:mode forKey:EVENT_SWITCH_MODE];
    [appSwitchEvent setEventBody:eventBody];
    
    // pass the event to manager
    [self addSystemEvent:appSwitchEvent];
    [eventBody release];
    [appSwitchEvent release];
}
-(void)logEventAppTerminate:(NSString *)exitType
{
    // create an application launch event
    Event *appTerminateEvent = [[Event alloc] initWithEventName:@"exit"];
    
    // build the event body
    NSMutableDictionary *eventBody = [[NSMutableDictionary alloc] init];
    [eventBody setValue:exitType forKey:EVENT_TERMINATE_TYPE];
    [appTerminateEvent setEventBody:eventBody];
    
    // pass the event to manager
    [self addSystemEvent:appTerminateEvent];
    [eventBody release];
    [appTerminateEvent release];
}

-(void) addSystemEvent:(Event *) event
{
    if (![[EventManager instance] isNeedLog]) {
        return;
    }
    
    [[EventManager instance] performSelector:@selector(addEvent:) onThread:[EventManager threadForOperation] withObject:event waitUntilDone:NO];
}
/*
 * end of internal interfaces
 */

@end
