//
//  ServerConnection.h
//  Collector
//
//  Created by shinn on 11-11-3.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataCollector.h"

@class ServerConnection;
@protocol ServerConnectionProtocol

-(void)connectionPostMessageSuccess:(NSURLConnection *) connection;
-(void)connectionPostMessageFail:(NSURLConnection *) connection ;

@end

@interface ServerConnection : NSObject 
{
    NSMutableURLRequest *_serverRequest;
    NSURLConnection *_urlConnection;
    NSMutableData *_receivedData;
    NSString *_method;
    NSInteger _isOK;
    BOOL _isLastPostFinished;
    BOOL _isSuccess;
    BOOL _isSending;
    id<ServerConnectionProtocol> _connectionDelegate; 
}

@property (nonatomic, retain) NSMutableURLRequest *serverRequest;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, assign) NSInteger isOK;
@property (nonatomic, assign) BOOL isLastPostFinished;
@property (nonatomic, retain) id serverConnectionDelegate;
@property (nonatomic, assign) BOOL isSending;
@property (nonatomic, retain) NSURLResponse *lastResponse;

-(BOOL)sendData:(NSData *) data withUrl:(NSString *) urlString;

+(ServerConnection *) getServerConnection;
@end