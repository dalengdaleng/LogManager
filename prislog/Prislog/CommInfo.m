//
//  CommInfo.m
//  PRIS
//
//  Created by reed on 10-12-20.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CommInfo.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <CoreFoundation/CoreFoundation.h>
#import "Util.h"

static NSString* _username = nil;
static NSString* _password = nil;
static int _accountType = 0;
static dispatch_queue_t _syncQueue = NULL;

const static NSString* _entryCacheDir = @"userEntry";
const static NSString* _entryStatusCacheDir = @"userEntryStatus";
const static NSString* _programCoverDir = @"CoverImages";
const static NSString* _portraitDir = @"Portrait";
const static NSString* _fontsDir = @"Fonts";
const static NSString* _booksDir = @"Books";
const static NSString* _templateDir = @"Template";
const static NSString* _videoDir = @"Video";
const static NSString* _magmeDir = @"Magme";
const static NSString* _pdfReflow = @"pdfReflow";

static NSString* _libraryDir = nil;

@implementation CommInfo

+ (void) setUsername:(NSString *)username{
    dispatch_sync(_syncQueue, ^{
        
        if (username == nil)
            return;
        _username = [[NSString alloc] initWithString:username];
    });
}

+ (NSString *) getUsername{
    
    __block NSString *username = nil;
    
    dispatch_sync(_syncQueue, ^{
        
        username = [_username copy];
    });
    
	return username;
}

+ (void) setPassword:(NSString *)password{
    
    dispatch_sync(_syncQueue, ^{
        
        if (password == nil)
            return;
        _password = [[NSString alloc] initWithString:password];
    });
}

+ (NSString *) getPassword{
    
    __block NSString *password = nil;
    
    dispatch_sync(_syncQueue, ^{
        
        password = [_password copy];
    });
    
	return password;
}

+ (void) setAccountType:(int)accountType{
    
    dispatch_sync(_syncQueue, ^{
        _accountType = accountType;
    });
}

+ (int) getAccountType{
    
    __block int accountType = 0;
    
    dispatch_sync(_syncQueue, ^{
        accountType = _accountType;
    });
    
    return accountType;
}



+ (NSString *) getEntryCacheRootPath{
	if (_entryCacheDir == nil)
		return nil;
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/%@/",dir,_entryCacheDir];
    return path;
}

+ (NSString *) getEntryStatusCacheRootPath{
	if (_entryStatusCacheDir == nil)
		return nil;
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/%@/",dir,_entryStatusCacheDir];
    return path;
}

+ (NSString *) getEntryStatusCacheRootPathWithUsername{
	if (_entryStatusCacheDir == nil)
		return nil;
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/%@/%@/",dir,_entryStatusCacheDir,_username];
    return path;
}

+ (NSString *) getProgramCoverDir
{
	if (_programCoverDir == nil)
		return nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
	return [NSString stringWithFormat:@"%@/%@/",libraryDirectory,_programCoverDir];	
}

+ (NSString *) getCustomPortraitDir
{
	if (_portraitDir == nil)
		return nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/%@/",libraryDirectory,_portraitDir];
    return path;
}

+ (NSString *) getFontsDir
{
   	if (_fontsDir == nil)
		return nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/%@/",libraryDirectory,_fontsDir];
    return path;
}

+ (NSString *)getFontsTempDir
{
    if (_fontsDir == nil)
		return nil;
	return [NSString stringWithFormat:@"%@/%@/",NSTemporaryDirectory(),_fontsDir];
}

+ (NSString *) getBooksDir
{
   	if (_booksDir == nil)
		return nil;
    if (!_libraryDir){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        _libraryDir = [paths objectAtIndex:0];
        [_libraryDir copy];
    }
	NSString *path = [NSString stringWithFormat:@"%@/%@/",_libraryDir,_booksDir];
    return path;
}

+ (NSString *) getBooksPreviewDir
{
   	if (_booksDir == nil)
		return nil;
    if (!_libraryDir){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        _libraryDir = [paths objectAtIndex:0];
        [_libraryDir copy];
    }
	NSString *path = [NSString stringWithFormat:@"%@/%@/preview/",_libraryDir,_booksDir];
    return path;
}

+ (NSString *) getBooksTrialDir
{
   	if (_booksDir == nil)
		return nil;
    if (!_libraryDir){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        _libraryDir = [paths objectAtIndex:0];
        [_libraryDir copy];
    }
	NSString *path = [NSString stringWithFormat:@"%@/%@/trial/",_libraryDir,_booksDir];
    return path;
}

+ (NSString *) getVideoDir
{
   	if (_videoDir == nil)
		return nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/%@/",libraryDirectory,_videoDir];
    return path;
}

+ (NSString *) getMagmeDir
{
   	if (_magmeDir == nil)
		return nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/%@/", libraryDirectory, _magmeDir];
    return path;
}

+ (NSString *) getMagmeTrialDir
{
   	if (_booksDir == nil)
		return nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/%@/trial/", libraryDirectory, _magmeDir];
    return path;
}

+ (NSString *) getMagmePreviewDir
{
   	if (_booksDir == nil)
		return nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/%@/preview/", libraryDirectory, _magmeDir];
    return path;
}

+ (NSString *) getBuildForModel
{
    NSString *buildForModel = nil;
#ifdef BUILD_FOR_IPAD        
    buildForModel = @"iPad";
#else
    buildForModel = @"iPhone";
#endif
    return buildForModel;
}

+ (void)globalInit
{
    _syncQueue = dispatch_queue_create(NULL, NULL);
}

+ (void)globalUninit
{
    dispatch_sync(_syncQueue, ^{
        
        if (_username)
        {
            _username = nil;
        }
        if (_password)
        {
            _password = nil;
        }
    });
	
    _syncQueue = NULL;
}

+ (void) setCustomKey:(NSString *)KeyName:(NSString *)KeyValue{
    
    dispatch_sync(_syncQueue, ^{
        
        NSUserDefaults *persistentDefaults = [NSUserDefaults standardUserDefaults];
        [persistentDefaults setObject:KeyValue forKey:KeyName];
        [persistentDefaults synchronize];
    });
}

+ (NSString *) getCustomKey:(NSString *)KeyName{
    
    __block NSString *UnpersistentString = nil;
    
    dispatch_sync(_syncQueue, ^{
        
        NSUserDefaults *persistentDefaults = [NSUserDefaults standardUserDefaults];
        UnpersistentString = [persistentDefaults objectForKey:KeyName];
    });
	
	return UnpersistentString;	
}

+ (void) setCustomObjectKey:(NSString *)KeyName :(NSObject *)KeyValue
{
    dispatch_sync(_syncQueue, ^{
        
        NSUserDefaults *persistentDefaults = [NSUserDefaults standardUserDefaults];
        [persistentDefaults setObject:KeyValue forKey:KeyName];
        [persistentDefaults synchronize];
    });
}

+ (NSObject *) getCustomObjectKey:(NSString *)KeyName
{
    __block NSObject *UnpersistentObj = nil;
    
    dispatch_sync(_syncQueue, ^{
        
        NSUserDefaults *persistentDefaults = [NSUserDefaults standardUserDefaults];
        UnpersistentObj = [persistentDefaults objectForKey:KeyName];
    });
    
	return UnpersistentObj;	
}

+ (void) setCustomIntKey:(NSString *)KeyName :(long long)KeyValue
{
	NSString *keyValueStr = [[NSString alloc] initWithFormat:@"%lli",KeyValue];
	[CommInfo setCustomKey:KeyName :keyValueStr];
}

+ (long long) getCustomIntKey:(NSString *)KeyName
{
	NSString * value = [CommInfo getCustomKey:KeyName];
	return [value longLongValue];
}

+ (NSString *) getTemplateDir
{
   	if (_templateDir == nil)
		return nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
	return [NSString stringWithFormat:@"%@/%@/", dir, _templateDir];	 
}

//+ (NSString *)getBookContentTempFilePath:(NSString *)aBookId sectionId:(NSString *)aSectionId
//{
//    NSString* tmpFilePath;
//    NSString *md5BookId = [Md5 encode:aBookId];
//    NSString *tmpPath = NSTemporaryDirectory();
//    if (aSectionId)
//    {
//        NSString *md5SectionId = [Md5 encode:aSectionId];
//        tmpFilePath = [NSString stringWithFormat:@"%@%@/%@.zip", tmpPath, md5BookId, md5SectionId];
//        
//        return tmpFilePath;
//    }
//	tmpFilePath = [NSString stringWithFormat:@"%@%@/%@.zip", tmpPath, md5BookId, md5BookId];
//    
//    return tmpFilePath;
//}

//+ (NSString *)getBookContentTempFileDir:(NSString *)aBookId
//{
//    NSString* tmpFileDir;
//    NSString *md5BookId = [Md5 encode:aBookId];
//    NSString *tmpPath = NSTemporaryDirectory();
//    
//	tmpFileDir = [NSString stringWithFormat:@"%@%@/", tmpPath, md5BookId];
//    
//    return tmpFileDir;
//}

+ (NSString *) getPdfReflowTempFileDir
{
    NSString* tmpFileDir;
    NSString *tmpPath = NSTemporaryDirectory();
    
	tmpFileDir = [NSString stringWithFormat:@"%@%@/", tmpPath, _pdfReflow];
    
    return tmpFileDir;
}
@end
