
//
//  ServerConnection.m
//  Collector
//
//  Created by shinn on 11-11-3.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "ServerConnection.h"
#import "DCUtil.h"

@implementation ServerConnection

@synthesize serverConnectionDelegate = _connectionDelegate;
@synthesize serverRequest = _serverRequest;
@synthesize urlConnection = _urlConnection;
@synthesize receivedData = _receivedData;
@synthesize isOK = _isOK;
@synthesize isLastPostFinished = _isLastPostFinished;
@synthesize isSending = _isSending;
@synthesize lastResponse;

static ServerConnection *sharedServerConnection = nil;

#pragma mark -- internal interface used to send data

/*
 * send data asynchronize
 */
-(BOOL)sendData:(NSData *) data withUrl:(NSString *) urlString
{
    NSURL *serverUrl;
    
    if (urlString != nil) {
        serverUrl = [NSURL URLWithString:urlString];
    }
    else{
        DCPrint(@"url为nil",nil);
        return NO;
    }
    _isSending = YES;
    
    self.isLastPostFinished = NO;
    self.serverRequest = [NSMutableURLRequest requestWithURL:serverUrl cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:10];
    [self.serverRequest setHTTPMethod: @"POST"];    
    [self.serverRequest setHTTPBody:data];
    _urlConnection = [[NSURLConnection alloc]initWithRequest:self.serverRequest delegate:self] ;
    
    if(!_urlConnection){
        DCPrint(@"error create connection", nil);
        return NO;
    }
    [_urlConnection release];
    //create NSMutableData 
    [self setReceivedData:[NSMutableData data]]; 
    return YES;
}

#pragma mark -- NSURLConnection delegate method
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.lastResponse = response;
    
    // 判断该请求是否成功
    if([response isKindOfClass:[NSHTTPURLResponse class]]){
        [[self receivedData] setLength:0];
        DCPrint(@"connection status code %d",[(NSHTTPURLResponse *)response statusCode]);
        _isSuccess = ([(NSHTTPURLResponse *)response statusCode] == 200)?YES:NO;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    DCPrint(@"connection: Challenge: Not supposed to happen!", nil);
	[[challenge sender] cancelAuthenticationChallenge:challenge];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_receivedData appendData:data];
    return;
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    DCPrint(@"connection fail: %@", error);
    _isSending = NO;
    [_connectionDelegate connectionPostMessageFail:connection];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _isSending = NO;
    if (_isSuccess){
        [_connectionDelegate connectionPostMessageSuccess:connection];
    }else{
        [_connectionDelegate connectionPostMessageFail:connection];
    }
}

#pragma mark - methods overrided for singleton
/*
 * return the single instance of connection
 */
+(id) getServerConnection
{
    if (sharedServerConnection == nil) {
        @synchronized(self) {
            if (sharedServerConnection == nil) {
                sharedServerConnection = [[ServerConnection alloc] init];
            }
        }
    }
    return sharedServerConnection;
}

-(id)init
{
    self = [super init];
    [self setIsLastPostFinished:YES];
    return self;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) 
    {
        if (sharedServerConnection == nil) 
        {
            sharedServerConnection = [super allocWithZone:zone];
            return sharedServerConnection;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

//
-(void)dealloc
{
    [super dealloc];
}

@end

