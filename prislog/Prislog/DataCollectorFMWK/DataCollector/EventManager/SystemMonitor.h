//
//  SystemMonitor.h
//  Collector
//
//  Created by lvsheng on 11-11-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "EventManager.h"
#import "Event.h"
#import "DataCollector.h"

/*
 * values stored in UserDefault
 * 1.time of last switching to background
 * 2.is fisrt time using the app in this device
 */
#define USR_DEFAULT_LAST_ENTER_BACK_TIME    @"AnalyzerlastEnterBackTime"
#define USR_DEFAULT_IS_FISRT_USE    @"AnalyzerIsFirstUse"

@interface SystemMonitor : NSObject
{
    NSTimer *_heartBeatTimer;// used to check that it's time to send heartbeat
    UIBackgroundTaskIdentifier _collectorBgTask;// the background task to keep connection to server
    SendActionType _currentSystemEventType;
}
@property (nonatomic, retain) NSTimer *heartBeatTimer;
@property SendActionType currentSystemEventType;

/*
 * 用于记录系统事件
 */ 
-(void) logEventHeartBeat;
-(void) logEventAppLanuched;
-(void) logEventAppSwitchToMode:(NSString *) mode;
-(void) logEventAppTerminate:(NSString *)exitType;
-(void) logEventAppActivate;
-(void) addSystemEvent:(Event *) event;

/*
 * 用于向EventManager提出发送请求
 */
-(void) sendSystemMessageWithEventType:(SendActionType) type;
-(void) performSendAction;

/*
 * 系统事件触发的发送回调和处理
 */
-(void) startBgTask;//start a background task, used when will enter background event arrived, to offer more time for sending message
-(void) endCollectorBgTask;// end the background that started by self
-(void) sendSystemMessageSuccess:(id)sender;

/*
 * methods to add obersver for application notification and setup timer
 * application notification
 */
-(void) registerAppEvent;//register system event notificaiton
- (void)startHeartBeat;
-(void) appDidFinishLaunchingWithOptions: (NSNotification*) notification;
-(void) appDidEnterBackground: (NSNotification*) notification;
-(void) appWillTerminate: (NSNotification*) notification;
-(void) appWillEnterForeground: (NSNotification*) notification;
-(void) appDidBecomeActive: (NSNotification*) notification;
-(void) appWillResignActive: (NSNotification*) notification;
-(void) handleHeartBeatTimer:(id) sender;//heartbeat NSTimer callback
-(void) checkHeartBeatTime;//do the check if it's time to send heartbeat message

@end
