//
//  CommInfo.h
//  PRIS
//
//  Created by reed on 10-12-20.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface CommInfo : NSObject {

}
+ (void)globalInit;
+ (void)globalUninit;

+ (void) setUsername:(NSString *)username;

+ (NSString *) getUsername;

+ (void) setPassword:(NSString *)password;

+ (NSString *) getPassword;

+ (void) setAccountType:(int)accountType;

+ (int) getAccountType;

+ (NSString *) getEntryCacheRootPath;

+ (NSString *) getEntryStatusCacheRootPath;

+ (NSString *) getEntryStatusCacheRootPathWithUsername;

+ (NSString *) getProgramCoverDir;

+ (NSString *) getCustomPortraitDir;

+ (NSString *) getFontsDir;

+ (NSString *) getFontsTempDir;

+ (NSString *) getBooksDir;

+ (NSString *) getBooksPreviewDir;

+ (NSString *) getBooksTrialDir;

+ (NSString *) getVideoDir;

+ (NSString *) getBuildForModel;

+ (void) setCustomKey:(NSString *)KeyName :(NSString *)KeyValue;

+ (NSString *) getCustomKey:(NSString *)KeyName;

+ (void) setCustomObjectKey:(NSString *)KeyName :(NSObject *)KeyValue;

+ (NSObject *) getCustomObjectKey:(NSString *)KeyName;

+ (void) setCustomIntKey:(NSString *)KeyName :(long long)KeyValue;

+ (long long) getCustomIntKey:(NSString *)KeyName;

+ (NSString *) getMagmeDir;
+ (NSString *) getMagmeTrialDir;
+ (NSString *) getMagmePreviewDir;
+ (NSString *) getTemplateDir;
+ (NSString *)getBookContentTempFilePath:(NSString *)aBookId sectionId:(NSString *)aSectionId;
+ (NSString *)getBookContentTempFileDir:(NSString *)aBookId;
+ (NSString *) getPdfReflowTempFileDir;
@end
