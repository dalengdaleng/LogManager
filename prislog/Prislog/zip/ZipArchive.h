//
//  ZipArchive.h
//
//
//  Created by aish on 08-9-11.
//  acsolu@gmail.com
//  Copyright 2008  Inc. All rights reserved.
//
// History:
//    09-11-2008 version 1.0    release
//    10-18-2009 version 1.1    support password protected zip files
//    10-21-2009 version 1.2    fix date bug

#import <UIKit/UIKit.h>

#include "minizip/zip.h"
#include "minizip/unzip.h"



@protocol ZipArchiveDelegate <NSObject>
@optional
-(void) ErrorMessage:(NSString*) msg;
-(BOOL) OverWriteOperation:(NSString*) file;
-(void) UnzipPercent:(float) percent;
@end


@interface ZipArchive : NSObject {
@private
	zipFile		_zipFile;
	unzFile		_unzFile;
	
	NSString*   _password;
	id			_delegate;
}

@property (nonatomic, assign) id delegate;

-(BOOL) CreateZipFile2:(NSString*) zipFile;
-(BOOL) CreateZipFile2:(NSString*) zipFile Password:(NSString*) password;
-(BOOL) addFileToZip:(NSString*) file newname:(NSString*) newname;
-(BOOL) addDataToZip:(NSData*) data newname:(NSString*) newname compressLevel:(int)level;
-(BOOL) CloseZipFile2;

-(BOOL) UnzipOpenFile:(NSString*) zipFile;
-(BOOL) UnzipOpenFile:(NSString*) zipFile Password:(NSString*) password;
-(BOOL) UnzipFileTo:(NSString*) path overWrite:(BOOL) overwrite;
-(BOOL) UnzipCloseFile;
//-(BOOL) UnzipContainerTo:(NSString*) path overWrite:(BOOL) overwrite bookId:(NSString*)bookId dir:(NSString *)localPath processObject:(id)object processFunction:(SEL)pFunction startPercent:(int)nStartPercent endPercent:(int)nEndPercent error:(NSError **)error;

+ (BOOL) UnzipFile:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite;
+ (BOOL) UnzipFile2SameDir:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite;
+ (BOOL) UnzipFile:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite password:(NSString*) password;
+ (BOOL) zipFileIsEncryp: (NSString *)zipFile;

+ (BOOL) zipData2File:(NSString*) zipFile data:(NSData*)data password:(NSString*)password;
+ (NSData *) UnzipFile2Data:(NSString*) zipFile password:(NSString*) password;

+ (BOOL) UnzipContainer:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite bookId:(NSString*)bookId  dir:(NSString *)localPath processObject:(id)object processFunction:(SEL)pFunction startPercent:(int)nStartPercent endPercent:(int)nEndPercent error:(NSError **)error;
+ (BOOL) UnzipContainer:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite password:(NSString*) password bookId:(NSString*)bookId dir:(NSString *)localPath processObject:(id)object processFunction:(SEL)pFunction startPercent:(int)nStartPercent endPercent:(int)nEndPercent error:(NSError **)error;

//+ (BOOL) UnzipMagme:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite password:(NSString*) password bookId:(NSString*)bookId processObject:(id)object processFunction:(SEL)pFunction startPercent:(int)nStartPercent endPercent:(int)nEndPercent error:(NSError **)error;

//+ (BOOL) UnzipCartoonPic:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite password:(NSString*) password bookId:(NSString*)bookId;

@end
