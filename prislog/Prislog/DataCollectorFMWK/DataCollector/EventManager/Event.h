//
//  Event.h
//  Collector
//
//  Created by lvsheng on 11-11-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataCollector.h"

// Message Header
#define MSGHEADER_DEBUG         @"debug"
#define MSGHEADER_PROTOCOL_VER  @"protocolVersion"
#define MSGHEADER_PRODUCT       @"product"
#define MSGHEADER_PRODUCT_VER   @"product_ver"
#define MSGHEADER_XMID          @"xmid"
#define MSGHEADER_TERMINAL_TYPE @"client"
#define MSGHEADER_TERMINAL_VER  @"ver"
#define MSGHEADER_TERMINAL_UID  @"client_id"
#define MSGHEADER_MAC           @"mac"
#define MSGHEADER_PHONE_NUMBER  @"mobile"
#define MSGHEADER_OS            @"os"
#define MSGHEADER_OS_VER        @"os_ver"
#define MSGHEADER_REPORT_TIME   @"reportTime"
#define MSGHEADER_SCREEN_SIZE   @"scr_res"
#define MSGHEADER_FIRSTEVENTACCOUNT @"firstEventAccount"
#define MSGHEADER_FIRSTUSERID   @"firstUserId"
#define MSGHEADER_ISREALTIME    @"realTime"
#define MSGBODY                 @"events"

#define MSGHEADER_PPI           @"dpi_ppi"
#define MSGHEADER_DEV_TYPE      @"device_type"
#define MSGHEADER_MEMORY        @"memory"

// Message Body
//      Event Header
#define EVENTHEADER_NAME        @"method"
#define EVENTHEADER_OPERATE_TIME @"opTime"
#define EVENTHEADER_TIMECOST    @"costTime"
#define EVENTBODY               @"record"
//      Event Body
#define EVENT_UPGRADE_NEW_VERSION @"update_ver"
#define EVENT_UPGRADE_OLD_VERSION @"old_ver"
#define EVENT_LOGIN_ACCOUNT @"account"
#define EVENT_LOGIN_USERID @"userid"
#define EVENT_LOGIN_LOGINIP @"ip"
#define EVENT_LOGIN_MNO     @"MNO"
#define EVENT_LOGIN_NETWORK_TYPE @"network"
#define EVENT_LOGOUT_ACCOUNT @"account"
#define EVENT_LOGOUT_USERID @"userid"
#define EVENT_PAGEACCESS_CURRPAGE   @"curpage"
#define EVENT_PAGEACCESS_TOPAGE     @"gopage"
#define EVENT_ERROR_ERRCODE @"errorCode"
#define EVENT_ERROR_ERRMSG  @"errorMessage"
#define EVENT_SWITCH_MODE   @"mode"
#define EVENT_TERMINATE_TYPE @"type"


typedef enum _EventSendingStatus {
    toSend = 0,
    beingSending = 1
} EventSendingStatus;

@interface Event : NSObject{
    // event data
    NSString *_eventName;
    NSMutableDictionary *_eventBody;

    // event sending status, toSend or being Sending
    EventSendingStatus eventStatus;
    NSString *_eventAccount;
    NSString *_eventUserId;
    
    // used to store the timed custom event, uid as key while startTime as the value
    NSMutableDictionary *_timedEventInfoDictionary;    
}

@property (nonatomic, retain) NSString *eventName;
@property (nonatomic, assign) long long eventOpTime;
@property (nonatomic, assign) long long eventCostTime;
@property (nonatomic, retain) NSMutableDictionary *eventBody;
@property (nonatomic, retain) NSMutableDictionary *timedEventInfoDictionary;
@property (nonatomic, retain) NSString *eventAccount;
@property (nonatomic, retain) NSString *eventUserId;

@property (nonatomic) EventSendingStatus eventStatus;

- (id)initWithEventName:(NSString *)eventName;
- (NSDictionary *)getEventDictionary;// convert event to a NSDictionary type

@end
