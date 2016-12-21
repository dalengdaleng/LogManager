//
//  Event.m
//  Collector
//
//  Created by lvsheng on 11-11-5.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "Event.h"
#import "DCUtil.h"

@implementation Event

@synthesize eventName = _eventName;
@synthesize eventOpTime;   
@synthesize eventCostTime; 
@synthesize eventBody = _eventBody;
@synthesize eventStatus;
@synthesize timedEventInfoDictionary = _timedEventInfoDictionary;
@synthesize eventAccount = _eventAccount;
@synthesize eventUserId = _eventUserId;

-(id) initWithEventName: (NSString *) eventName
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    // set event name
    [self setEventName:eventName];
    
    // built current date
    [self setEventOpTime:[DCUtil timeToMillionSecond:[NSDate date]]];
    
    NSMutableDictionary *timedEventInfo = [[NSMutableDictionary alloc] init];
    [self setTimedEventInfoDictionary:timedEventInfo]; 
    [timedEventInfo release];
    
    self.eventAccount = @"anonymous";
    self.eventUserId = @"0";
    
    return self;
}

/*
 * Event to Dictionary
 */
-(NSDictionary *) getEventDictionary
{
    NSMutableDictionary *eventData = [[[NSMutableDictionary alloc] init] autorelease];
    [eventData setValue:_eventName forKey:EVENTHEADER_NAME];
    [eventData setValue:[NSNumber numberWithLongLong:[self eventOpTime]] forKey:EVENTHEADER_OPERATE_TIME];
    [eventData setValue:_eventBody forKey:EVENTBODY];
    if (self.eventCostTime!=0) {
        [eventData setValue:[NSNumber numberWithLongLong:self.eventCostTime] forKey:EVENTHEADER_TIMECOST];
    }
    return eventData;
}

-(void) dealloc
{
    [_eventAccount release];
    [_eventUserId release];
    [_eventBody release];
    [_eventName release];
    [_timedEventInfoDictionary release];
    [super dealloc];
}
@end
