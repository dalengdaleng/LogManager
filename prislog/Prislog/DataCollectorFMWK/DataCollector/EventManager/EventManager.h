//
//  EventManager.h
//  Collector
//
//  Created by lvsheng on 11-11-3.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Event.h"
//#import <JasmineUtil/JasmineUtil.h>
#import "zlib.h"
#import "ServerConnection.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "DataCollector.h"
#import "DCReachability.h"
#import "netinet/in.h"
#import "DCUtil.h"

#define SPLIT_TAG @"-------848c2a30-8ff6-4e4a-8e77-a2e8a99d3ce2-dfc1a2a6-d7f4-41a4-aec5-e7ec4fc37508"   // 多个json string之间的分割字符序列
#define XOR_LEN 30              // 消息压缩后加密部分长度
#define SERVER_PATH @"/log"     //发送消息到服务器的路径
#define JSON_STR_LENGTH 1024*29 //单个JSON字符串的长度 29KB
#define USER_SWITCH_KEY @"userSwitchStatus"
#define RELATIVE_DIR @"/Library/Caches/EvtFile/"    // 发送失败的消息文件存放路径
#define LOCATE_RESP_HEADER_CODE @"code"
#define LOCATE_RESP_HEADER_LOGSERVER @"logserver"

// the trigger of sending message
typedef enum _SendActionType {
	AppSwitchBackSend = 0,
    AppTerminateSend = 1,
    AppSwitchFrontSend = 2,
    AppLaunchSend = 3,
    ImmediateSend = 4,
    HeartBeatSend = 5,
    PendingResend = 6,
} SendActionType;

extern NSString *CTSettingCopyMyPhoneNumber();

@interface EventManager : NSObject<ServerConnectionProtocol>
{
    BOOL _isSendingOldFile; // default NO

    BOOL _sendPending;    // true, if any pending post message action; default NO
    
    BOOL _isSwitchBackPending; // 当切到后台事件被阻塞时，标记，用于收到响应后，把因切到后台发起的后台任务关掉
    
    DCNetworkStatus _networkType;
    
    /**
     * 实时统计
     */
    // variables for instant event;
    BOOL _isSendInstantEvent;
    NSString *_lastSendInstantDataInJson;
}
@property (atomic) ModuleStatus moduleStatus; // 统计模块开关
@property (nonatomic, retain) NSString *serverUrl; // 统计服务器地址
@property (nonatomic, retain) NSString *currAccount;
@property (nonatomic, retain) NSString *currUserId;
@property (retain) NSMutableDictionary *msgHeader;
@property (atomic, retain) NSMutableString *jsonCombineString;  // 组装多个json字符串
@property (nonatomic, retain) NSMutableArray *events;           // array of all events, with NSDictionary as element type
@property (retain) NSDate *lastMessageSendTime;                 // used to check that it's time to send the heartbeat message
@property (nonatomic, retain) NSString *lastSendOldFilePath;    // string stores old file path of just sended, which will be deleted when reponse OK return;
@property (nonatomic) SendActionType eventType;

// this variable used to hold the NSData after zip and encryption
// used when connection failure to write to file
@property (nonatomic, retain) NSData *dataToPost;

+ (NSFileManager *)getFileManager;
+(id) instance;
-(id) init;
+ (NSThread *)threadForOperation;// event manager running thread

#pragma mark -  method to produce event and send event
-(void) addHeader:(NSString *) key value:(NSString *) value;// add a header with key and value
-(void) addEvent:(Event *) event; // add a new event data into event array
-(NSString *) composeEventsToJson; // compose a single json string
-(void) transformEventsToJson;
-(NSData *) composeDataForSend; // 组装待发送的数据
-(int) currentEventsLength;
-(void) builtMessageHeader; // method to built all the header values
-(void) parseLocateResult:(NSData *)data;
-(void) storeSendDataToFile;

-(NSMutableDictionary *) returnMessageHeader;
-(void) sendInstantEvent:(Event *)event;

#pragma mark - Message Post Action
-(BOOL) postMessageWithEventType:(SendActionType) type; // called by system monitor to send data
-(BOOL) postLocateMessage;
-(BOOL) postNewMessage;
-(void) postOldMessage;
-(BOOL) isAnyOldMessages;

#pragma mark -  connection callback
-(BOOL) sendMessage:(NSData *)data;
-(void) connectionPostMessageSuccess:(NSURLConnection *) connection;
-(void) connectionPostMessageFail:(NSURLConnection *) connection ;

#pragma mark - others
// condition check before module. 1) Module Switch key check
- (BOOL)isNeedSend;
- (BOOL)isNeedLog;
-(id) JSONValueWithString:(NSString *) string;
-(NSString *) JSONRepresentationCustomWithObject:(NSObject *) obj;// method convert data to json string
-(NSString *) getNetworkType;// return network type: wifi, WWAN
@end
