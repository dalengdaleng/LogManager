//
//  ZipArchive.mm
//
//
//  Created by aish on 08-9-11.
//  acsolu@gmail.com
//  Copyright 2008  Inc. All rights reserved.
//

#import "ZipArchive.h"
#import "zlib.h"
#import "zconf.h"
//#import "PRISContainerParser.h"
//#import "FileScrambleMgr.h"
//#import "DataEngine.h"

@interface ZipArchive (Private)

-(void) OutputErrorMessage:(NSString*) msg;
-(BOOL) OverWrite:(NSString*) file;
-(void) UnzipPerc:(float) percent;
-(NSDate*) Date1980;
-(BOOL) UnzipMagmeTo:(NSString*) path overWrite:(BOOL) overwrite bookId:(NSString*)bookId processObject:(id)object processFunction:(SEL)pFunction startPercent:(int)nStartPercent endPercent:(int)nEndPercent error:(NSError **)error;
-(BOOL) UnzipCartoonPicTo:(NSString*) path overWrite:(BOOL) overwrite bookId:(NSString*)bookId;
@end



@implementation ZipArchive
@synthesize delegate = _delegate;

-(id) init
{
	if( self=[super init] )
	{
		_zipFile = NULL ;
	}
	return self;
}

-(void) dealloc
{
	[self CloseZipFile2];
	[super dealloc];
}

-(BOOL) CreateZipFile2:(NSString*) zipFile
{
	_zipFile = zipOpen( (const char*)[zipFile UTF8String], 0 );
	if( !_zipFile )
		return NO;
	return YES;
}

-(BOOL) CreateZipFile2:(NSString*) zipFile Password:(NSString*) password
{
	_password = password;
	return [self CreateZipFile2:zipFile];
}

-(BOOL) addFileToZip:(NSString*) file newname:(NSString*) newname;
{
	if( !_zipFile )
		return NO;
    //	tm_zip filetime;
	time_t current;
	time( &current );
	
	zip_fileinfo zipInfo = {0};
    //	zipInfo.dosDate = (unsigned long) current;
	
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
	NSDictionary* attr = [fileMgr fileAttributesAtPath:file traverseLink:YES];
    [fileMgr release];
	if( attr )
	{
		NSDate* fileDate = (NSDate*)[attr objectForKey:NSFileModificationDate];
		if( fileDate )
		{
			// some application does use dosDate, but tmz_date instead
            //	zipInfo.dosDate = [fileDate timeIntervalSinceDate:[self Date1980] ];
			NSCalendar* currCalendar = [NSCalendar currentCalendar];
			uint flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
            NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ;
			NSDateComponents* dc = [currCalendar components:flags fromDate:fileDate];
			zipInfo.tmz_date.tm_sec = [dc second];
			zipInfo.tmz_date.tm_min = [dc minute];
			zipInfo.tmz_date.tm_hour = [dc hour];
			zipInfo.tmz_date.tm_mday = [dc day];
			zipInfo.tmz_date.tm_mon = [dc month] - 1;
			zipInfo.tmz_date.tm_year = [dc year];
		}
	}
	
	int ret ;
	NSData* data = nil;
	if( [_password length] == 0 )
	{
		ret = zipOpenNewFileInZip( _zipFile,
								  (const char*) [newname UTF8String],
								  &zipInfo,
								  NULL,0,
								  NULL,0,
								  NULL,//comment
								  Z_DEFLATED,
								  Z_DEFAULT_COMPRESSION);
	}
	else
	{
		data = [ NSData dataWithContentsOfFile:file];
		uLong crcValue = crc32( 0L,NULL, 0L );
		crcValue = crc32( crcValue, (const Bytef*)[data bytes], [data length] );
		ret = zipOpenNewFileInZip3( _zipFile,
                                   (const char*) [newname UTF8String],
                                   &zipInfo,
                                   NULL,0,
                                   NULL,0,
                                   NULL,//comment
                                   Z_DEFLATED,
                                   Z_DEFAULT_COMPRESSION,
                                   0,
                                   15,
                                   8,
                                   Z_DEFAULT_STRATEGY,
                                   [_password cStringUsingEncoding:NSASCIIStringEncoding],
                                   crcValue );
	}
	if( ret!=Z_OK )
	{
		return NO;
	}
	if( data==nil )
	{
		data = [ NSData dataWithContentsOfFile:file];
	}
	unsigned int dataLen = [data length];
	ret = zipWriteInFileInZip( _zipFile, (const void*)[data bytes], dataLen);
	if( ret!=Z_OK )
	{
		return NO;
	}
	ret = zipCloseFileInZip( _zipFile );
	if( ret!=Z_OK )
		return NO;
	return YES;
}

-(BOOL) addDataToZip:(NSData*) data newname:(NSString*) newname compressLevel:(int)level
{
	if (!_zipFile)
		return NO;
    
    zip_fileinfo zipInfo = {0};
    
    int ret ;
	if( [_password length] == 0 )
	{
		ret = zipOpenNewFileInZip( _zipFile,
                                  (const char*) [newname UTF8String],
                                  &zipInfo,
                                  NULL,0,
                                  NULL,0,
                                  NULL,//comment
                                  Z_DEFLATED,
                                  level);
	}
	else
	{
		uLong crcValue = crc32( 0L,NULL, 0L );
		crcValue = crc32( crcValue, (const Bytef*)[data bytes], [data length] );
		ret = zipOpenNewFileInZip3( _zipFile,
                                   (const char*) [newname UTF8String],
                                   &zipInfo,
                                   NULL,0,
                                   NULL,0,
                                   NULL,//comment
                                   Z_DEFLATED,
                                   level,
                                   0,
                                   15,
                                   8,
                                   Z_DEFAULT_STRATEGY,
                                   [_password cStringUsingEncoding:NSASCIIStringEncoding],
                                   crcValue );
	}
	if (ret != Z_OK)
	{
		return NO;
	}
	unsigned int dataLen = [data length];
	ret = zipWriteInFileInZip(_zipFile, (const void*)[data bytes], dataLen);
	if (ret!=Z_OK)
	{
		return NO;
	}
	ret = zipCloseFileInZip(_zipFile);
	if (ret != Z_OK)
		return NO;
	return YES;
}

-(BOOL) CloseZipFile2
{
	_password = nil;
	if( _zipFile==NULL )
		return NO;
	BOOL ret =  zipClose( _zipFile,NULL )==Z_OK?YES:NO;
	_zipFile = NULL;
	return ret;
}

-(BOOL) UnzipOpenFile:(NSString*) zipFile
{
	_unzFile = unzOpen( (const char*)[zipFile UTF8String] );
	if( _unzFile )
	{
		unz_global_info  globalInfo = {0};
		if( unzGetGlobalInfo(_unzFile, &globalInfo )==UNZ_OK )
		{
		}
	}
	return _unzFile!=NULL;
}

-(BOOL) UnzipOpenFile:(NSString*) zipFile Password:(NSString*) password
{
	_password = password;
	return [self UnzipOpenFile:zipFile];
}

-(BOOL) UnzipFileToSameDir:(NSString*) path overWrite:(BOOL) overwrite
{
    uLong uncompressed_size = 0;
    uLong unZipDone_size = 0;
    float percent = 0.0;
	BOOL success = YES;
	int ret = unzGoToFirstFile( _unzFile );
	unsigned char		buffer[4096] = {0};
	NSFileManager* fman = [[NSFileManager alloc] init];
	if( ret!=UNZ_OK )
	{
		[self OutputErrorMessage:@"Failed"];
        return NO;
	}
	
	do{
		if( [_password length]==0 )
			ret = unzOpenCurrentFile( _unzFile );
		else
			ret = unzOpenCurrentFilePassword( _unzFile, [_password cStringUsingEncoding:NSASCIIStringEncoding] );
		if( ret!=UNZ_OK )
		{
			[self OutputErrorMessage:@"Error occurs"];
			success = NO;
			break;
		}
		// reading data and write to file
		int read ;
		unz_file_info	fileInfo ={0};
		ret = unzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
		if( ret!=UNZ_OK )
		{
			[self OutputErrorMessage:@"Error occurs while getting file info"];
			success = NO;
			unzCloseCurrentFile( _unzFile );
			break;
		}
        if (uncompressed_size == 0)
            uncompressed_size = fileInfo.uncompressed_size;
        
		char* filename = (char*) malloc( fileInfo.size_filename +1 );
		unzGetCurrentFileInfo(_unzFile, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
		filename[fileInfo.size_filename] = '\0';
		
		// check if it contains directory
		NSString * strPath = [NSString  stringWithUTF8String:filename];
        /*
         if ([strPath hasPrefix:@"ebook"])
         {
         strPath = [strPath substringFromIndex:[@"ebook" length]];
         }
         */
        BOOL isDirectory = NO;
		if( filename[fileInfo.size_filename-1]=='/' || filename[fileInfo.size_filename-1]=='\\')
        {
			isDirectory = YES;  //4.8.6 去除value stored
            unzCloseCurrentFile( _unzFile );
            ret = unzGoToNextFile( _unzFile );
            free( filename );
            continue;
        }
		free( filename );
		if( [strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location!=NSNotFound )
		{// contains a path
			strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
            strPath = [strPath lastPathComponent];
		}
		NSString* fullPath = [path stringByAppendingPathComponent:strPath];
		
		if( isDirectory )
			[fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
		else
			[fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
		if( [fman fileExistsAtPath:fullPath] && !isDirectory && !overwrite )
		{
			if( ![self OverWrite:fullPath] )
			{
				unzCloseCurrentFile( _unzFile );
				ret = unzGoToNextFile( _unzFile );
				continue;
			}
		}
		FILE* fp = fopen( (const char*)[fullPath UTF8String], "wb");
		while( fp )
		{
			read=unzReadCurrentFile(_unzFile, buffer, 4096);
			if( read > 0 )
			{
				fwrite(buffer, read, 1, fp );
                unZipDone_size += (uLong)read;
                if (uncompressed_size > 0){
                    percent = (float)(unZipDone_size * 100 / uncompressed_size);
                    [self UnzipPerc: percent];
                }
			}
			else if( read<0 )
			{
				[self OutputErrorMessage:@"Failed to reading zip file"];
                ret = UNZ_PARAMERROR;
                success = NO;
				break;
			}
			else
				break;
		}
		if( fp )
		{
			fclose( fp );
			// set the orignal datetime property
			NSDate* orgDate = nil;
			
			//{{ thanks to brad.eaton for the solution
			NSDateComponents *dc = [[NSDateComponents alloc] init];
			
			dc.second = fileInfo.tmu_date.tm_sec;
			dc.minute = fileInfo.tmu_date.tm_min;
			dc.hour = fileInfo.tmu_date.tm_hour;
			dc.day = fileInfo.tmu_date.tm_mday;
			dc.month = fileInfo.tmu_date.tm_mon+1;
			dc.year = fileInfo.tmu_date.tm_year;
			
			NSCalendar *gregorian = [[NSCalendar alloc]
									 initWithCalendarIdentifier:NSGregorianCalendar];
			
			orgDate = [gregorian dateFromComponents:dc] ;
			[dc release];
			[gregorian release];
			//}}
			
			
			NSDictionary* attr = [NSDictionary dictionaryWithObject:orgDate forKey:NSFileModificationDate];
			if( attr )
			{
				//		[attr  setValue:orgDate forKey:NSFileCreationDate];
                NSFileManager *fileMgr = [[NSFileManager alloc] init];
				if( ![fileMgr setAttributes:attr ofItemAtPath:fullPath error:nil] )
				{
					// cann't set attributes
					NSLog(@"Failed to set attributes");
				}
                [fileMgr release];
			}
		}
		unzCloseCurrentFile( _unzFile );
        if (ret == UNZ_OK)
		    ret = unzGoToNextFile( _unzFile );
	}while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
    [fman release];
	return success;
}

-(BOOL) UnzipFileTo:(NSString*) path overWrite:(BOOL) overwrite
{
    uLong uncompressed_size = 0;
    uLong unZipDone_size = 0;
    float percent = 0.0;
	BOOL success = YES;
	int ret = unzGoToFirstFile( _unzFile );
	unsigned char		buffer[4096] = {0};
	NSFileManager* fman = [[NSFileManager alloc] init];
	if( ret!=UNZ_OK )
	{
		[self OutputErrorMessage:@"Failed"];
        return NO;
	}
	
	do{
		if( [_password length]==0 )
			ret = unzOpenCurrentFile( _unzFile );
		else
			ret = unzOpenCurrentFilePassword( _unzFile, [_password cStringUsingEncoding:NSASCIIStringEncoding] );
		if( ret!=UNZ_OK )
		{
			[self OutputErrorMessage:@"Error occurs"];
			success = NO;
			break;
		}
		// reading data and write to file
		int read ;
		unz_file_info	fileInfo ={0};
		ret = unzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
		if( ret!=UNZ_OK )
		{
			[self OutputErrorMessage:@"Error occurs while getting file info"];
			success = NO;
			unzCloseCurrentFile( _unzFile );
			break;
		}
        if (uncompressed_size == 0)
            uncompressed_size = fileInfo.uncompressed_size;
        
		char* filename = (char*) malloc( fileInfo.size_filename +1 );
		unzGetCurrentFileInfo(_unzFile, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
		filename[fileInfo.size_filename] = '\0';
		
		// check if it contains directory
		NSString * strPath = [NSString  stringWithUTF8String:filename];
        /*
         if ([strPath hasPrefix:@"ebook"])
         {
         strPath = [strPath substringFromIndex:[@"ebook" length]];
         }
         */
        BOOL isDirectory = NO;
		if( filename[fileInfo.size_filename-1]=='/' || filename[fileInfo.size_filename-1]=='\\')
			isDirectory = YES;
		free( filename );
		if( [strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location!=NSNotFound )
		{// contains a path
			strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
		}
		NSString* fullPath = [path stringByAppendingPathComponent:strPath];
		
		if( isDirectory )
			[fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
		else
			[fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
		if( [fman fileExistsAtPath:fullPath] && !isDirectory && !overwrite )
		{
			if( ![self OverWrite:fullPath] )
			{
				unzCloseCurrentFile( _unzFile );
				ret = unzGoToNextFile( _unzFile );
				continue;
			}
		}
		FILE* fp = fopen( (const char*)[fullPath UTF8String], "wb");
		while( fp )
		{
			read=unzReadCurrentFile(_unzFile, buffer, 4096);
			if( read > 0 )
			{
				fwrite(buffer, read, 1, fp );
                unZipDone_size += (uLong)read;
                if (uncompressed_size > 0){
                    percent = (float)(unZipDone_size * 100 / uncompressed_size);
                    [self UnzipPerc: percent];
                }
			}
			else if( read<0 )
			{
				[self OutputErrorMessage:@"Failed to reading zip file"];
                ret = UNZ_PARAMERROR;
                success = NO;
				break;
			}
			else
				break;
		}
		if( fp )
		{
			fclose( fp );
			// set the orignal datetime property
			NSDate* orgDate = nil;
			
			//{{ thanks to brad.eaton for the solution
			NSDateComponents *dc = [[NSDateComponents alloc] init];
			
			dc.second = fileInfo.tmu_date.tm_sec;
			dc.minute = fileInfo.tmu_date.tm_min;
			dc.hour = fileInfo.tmu_date.tm_hour;
			dc.day = fileInfo.tmu_date.tm_mday;
			dc.month = fileInfo.tmu_date.tm_mon+1;
			dc.year = fileInfo.tmu_date.tm_year;
			
			NSCalendar *gregorian = [[NSCalendar alloc]
									 initWithCalendarIdentifier:NSGregorianCalendar];
			
			orgDate = [gregorian dateFromComponents:dc] ;
			[dc release];
			[gregorian release];
			//}}
			
			
			NSDictionary* attr = [NSDictionary dictionaryWithObject:orgDate forKey:NSFileModificationDate];
			if( attr )
			{
				//		[attr  setValue:orgDate forKey:NSFileCreationDate];
                NSFileManager *fileMgr = [[NSFileManager alloc] init];
				if( ![fileMgr setAttributes:attr ofItemAtPath:fullPath error:nil] )
				{
					// cann't set attributes
					NSLog(@"Failed to set attributes");
				}
				[fileMgr release];
			}
            
		}
		unzCloseCurrentFile( _unzFile );
        if (ret == UNZ_OK)
		    ret = unzGoToNextFile( _unzFile );
	}while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
    [fman release];
	return success;
}

-(NSData *) UnzipFileToData
{
    BOOL success = YES;
	int ret = unzGoToFirstFile(_unzFile);
	unsigned char buffer[4096] = {0};
	if (ret != UNZ_OK)
	{
		[self OutputErrorMessage:@"Failed"];
        return nil;
	}
	
    NSMutableData *data = [[[NSMutableData alloc] init] autorelease];
	do{
		if ([_password length] == 0)
			ret = unzOpenCurrentFile(_unzFile);
		else
			ret = unzOpenCurrentFilePassword(_unzFile, [_password cStringUsingEncoding:NSASCIIStringEncoding]);
		if (ret != UNZ_OK)
		{
			[self OutputErrorMessage:@"Error occurs"];
			success = NO;
			break;
		}
		// reading data and write to file
		int read;
        
		while (YES)
		{
			read = unzReadCurrentFile(_unzFile, buffer, sizeof(buffer));
			if (read > 0)
			{
                [data appendBytes:buffer length:read];
			}
			else if (read < 0)
			{
				[self OutputErrorMessage:@"Failed to reading zip file"];
                ret = UNZ_PARAMERROR;
                success = NO;
				break;
			}
			else
				break;
		}
		unzCloseCurrentFile(_unzFile);
        if (ret == UNZ_OK)
		    ret = unzGoToNextFile(_unzFile);
	}while(ret == UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE);
    if (success)
        return data;
    return nil;
}

//-(BOOL) UnzipContainerTo:(NSString*) path overWrite:(BOOL) overwrite bookId:(NSString*)bookId dir:(NSString *)localPath processObject:(id)object processFunction:(SEL)pFunction startPercent:(int)nStartPercent endPercent:(int)nEndPercent error:(NSError **)error
//{
//    uLong uncompressed_size = 0;
//    uLong unZipDone_size = 0;
//    float percent = 0.0;
//	BOOL success = YES;
//    BOOL bJsonParsed = NO;
//    PrisContainer *container = nil;
//    BOOL bFirst = YES;
//    BOOL bPathAppended = NO;
//    
//	int ret = unzGoToFirstFile( _unzFile );
//	unsigned char		buffer[4096] = {0};
//	NSFileManager* fman = [[NSFileManager alloc] init];
//	if( ret!=UNZ_OK )
//	{
//		[self OutputErrorMessage:@"Failed"];
//        return NO;
//	}
//    
//    unz_global_info globalInfo = {0};
//	ret = unzGetGlobalInfo(_unzFile, &globalInfo);  //4.8.6 去除value stored 去掉 ret=
//    uLong totalFile = globalInfo.number_entry;
//    uLong doneFile = 0;
//    
//	do{
//		if( [_password length]==0 )
//			ret = unzOpenCurrentFile( _unzFile );
//		else
//			ret = unzOpenCurrentFilePassword( _unzFile, [_password cStringUsingEncoding:NSASCIIStringEncoding] );
//		if( ret!=UNZ_OK )
//		{
//			[self OutputErrorMessage:@"Error occurs"];
//			success = NO;
//			break;
//		}
//		// reading data and write to file
//		int read ;
//		unz_file_info	fileInfo ={0};
//		ret = unzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
//		if( ret!=UNZ_OK )
//		{
//			[self OutputErrorMessage:@"Error occurs while getting file info"];
//			success = NO;
//			unzCloseCurrentFile( _unzFile );
//			break;
//		}
//        if (uncompressed_size == 0)
//            uncompressed_size = fileInfo.uncompressed_size;
//        
//		char* filename = (char*) malloc( fileInfo.size_filename +1 );
//		unzGetCurrentFileInfo(_unzFile, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
//		filename[fileInfo.size_filename] = '\0';
//		
//		NSString* strPath = [NSString  stringWithUTF8String:filename];
//        if (!bJsonParsed)
//        {
//            free(filename);
//            NSString* jsonFile = [[strPath lastPathComponent] lowercaseString];
//            if ([jsonFile isEqualToString:@"container.json"])
//            {
//                bJsonParsed = YES;
//                unsigned char* jsonBuf = (unsigned char *)malloc(fileInfo.uncompressed_size + 1);
//                if (!jsonBuf)
//                {
//                    [self OutputErrorMessage:@"Failed to malloc buf"];
//                    ret = UNZ_PARAMERROR;
//                    success = NO;
//                    unzCloseCurrentFile( _unzFile );
//                    break;
//                }
//                read = unzReadCurrentFile(_unzFile, jsonBuf, fileInfo.uncompressed_size + 1);
//                if (read < 1)
//                {
//                    [self OutputErrorMessage:@"Failed to reading zip file"];
//                    ret = UNZ_PARAMERROR;
//                    success = NO;
//                    unzCloseCurrentFile( _unzFile );
//                    free(jsonBuf);
//                    break;
//                }
//                
//                NSData *data = [NSData dataWithBytes:jsonBuf length:read];
//                container = [PRISContainerParser allocParseContainerData:data];
//                unzCloseCurrentFile( _unzFile );
//                unzGoToFirstFile( _unzFile );
//                free(jsonBuf);
//                continue;
//            }
//            unzCloseCurrentFile( _unzFile );
//            ret = unzGoToNextFile( _unzFile );
//            if (ret != UNZ_OK)
//                break;
//            continue;
//        }
//        
//        if (container && container.folder && [strPath hasPrefix:container.folder])
//        {
//            strPath = [strPath substringFromIndex:[container.folder length]];
//        }
//        
//        // check if it contains directory
//        BOOL isDirectory = NO;
//		if( filename[fileInfo.size_filename-1]=='/' || filename[fileInfo.size_filename-1]=='\\')
//			isDirectory = YES;
//		free( filename );
//		if( [strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location!=NSNotFound )
//		{// contains a path
//			strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
//		}
//        NSString* fileExt = [[strPath pathExtension] lowercaseString];
//        if (container && container.mime && ([container.mime isEqualToString:@"application/prismag"] || [container.mime isEqualToString:@"application/epub+zip"])) {
//        }
//        else if (localPath)
//        {
//            if (bPathAppended == NO)
//            {
//                if (![fileExt isEqualToString:@"json"])
//                {
//                    path = [path stringByAppendingPathComponent:localPath];
//                    bPathAppended = YES;
//                }
//            }
//        }
//		NSString* fullPath = [path stringByAppendingPathComponent:strPath];
//		
//		if( isDirectory )
//			[fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
//		else
//			[fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
//		if( [fman fileExistsAtPath:fullPath] && !isDirectory && !overwrite )
//		{
//			if( ![self OverWrite:fullPath] )
//			{
//				unzCloseCurrentFile( _unzFile );
//				ret = unzGoToNextFile( _unzFile );
//				continue;
//			}
//		}
//		FILE* fp = fopen( (const char*)[fullPath UTF8String], "wb");
//        
//        id *fsb;
//        BOOL needScramble = NO;
//        if ([[container.mime lowercaseString] isEqualToString:@"application/prismag"])
//        {
//            if ([fileExt isEqualToString:@"htm"] || [fileExt isEqualToString:@"html"] || [fileExt isEqualToString:@"jpeg"] || [fileExt isEqualToString:@"png"] || [fileExt isEqualToString:@".bmp"] || [fileExt isEqualToString:@"gif"])
//            {
//                needScramble = YES;
//            }
//        }
//        else if ([fileExt isEqualToString:@"htm"] || [fileExt isEqualToString:@"html"])//html里面嵌入的图片，不能加密，否则无法显示
//        {
//            needScramble = YES;
//        }
//        
//        if (needScramble == YES) {
//            fsb = [FileScrambleMgr createScrambleTransaction];
//        }
//		while (fp)
//		{
//            BOOL bShouldStop = NO;
//            if(object && [object respondsToSelector:@selector(shouldCancelUnzip:)]){
//                NSMutableArray *array = [NSMutableArray array];
//                [object performSelector:@selector(shouldCancelUnzip:) withObject:array];
//                NSNumber *shouldStopNumber = [array objectAtIndex:0];
//                bShouldStop = [shouldStopNumber boolValue];
//            }
//            if(bShouldStop){
//                [self OutputErrorMessage:@"unzip cancelled"];
//                ret = UNZ_CANCELLED;
//                success = NO;
//                break;
//            }
//			read=unzReadCurrentFile(_unzFile, buffer, 4096);
//			if( read > 0 )
//			{
//                if (needScramble == YES)
//                {
//                    //                    NSData *data = [FileScrambleMgr scrambleDataToData:buffer length:read password:bookId isFirst:bFirst];
//                    //                    bFirst = NO;
//                    //                    fwrite([data bytes], [data length], 1, fp);
//                    
//                    int outLen = 0;
//                    unsigned char *out = [FileScrambleMgr blockeScrambleBytesToBytes:fsb bytes:buffer length:read password:bookId isFirst:bFirst outLength:&outLen];
//                    bFirst = NO;
//                    if (outLen > 0){
//                        fwrite(out, outLen, 1, fp);
//                    }
//                    free(out);
//                }
//                else
//                {
//                    fwrite(buffer, read, 1, fp);
//                }
//                unZipDone_size += (uLong)read;
//                if (uncompressed_size > 0){
//                    percent = (float)(unZipDone_size * 100 / uncompressed_size);
//                    [self UnzipPerc: percent];
//                }
//			}
//			else if( read<0 )
//			{
//				[self OutputErrorMessage:@"Failed to reading zip file"];
//                ret = UNZ_PARAMERROR;
//                success = NO;
//				break;
//			}
//			else
//				break;
//		}
//		if( fp )
//		{
//            if (needScramble == YES){
//                int outLen = 0;
//                unsigned char *out = [FileScrambleMgr finishScrambleTransaction:fsb password:bookId outLength:&outLen];
//                if (outLen>0){
//                    fwrite(out, outLen, 1, fp);
//                }
//                free(out);
//                [FileScrambleMgr releaseScrambleTransaction:fsb];
//            }
//            
//			fclose( fp );
//			// set the orignal datetime property
//			NSDate* orgDate = nil;
//			
//			//{{ thanks to brad.eaton for the solution
//			NSDateComponents *dc = [[NSDateComponents alloc] init];
//			
//			dc.second = fileInfo.tmu_date.tm_sec;
//			dc.minute = fileInfo.tmu_date.tm_min;
//			dc.hour = fileInfo.tmu_date.tm_hour;
//			dc.day = fileInfo.tmu_date.tm_mday;
//			dc.month = fileInfo.tmu_date.tm_mon+1;
//			dc.year = fileInfo.tmu_date.tm_year;
//			
//			NSCalendar *gregorian = [[NSCalendar alloc]
//									 initWithCalendarIdentifier:NSGregorianCalendar];
//			
//			orgDate = [gregorian dateFromComponents:dc] ;
//			[dc release];
//			[gregorian release];
//			//}}
//			
//			
//			NSDictionary* attr = [NSDictionary dictionaryWithObject:orgDate forKey:NSFileModificationDate];
//			if( attr )
//			{
//				//		[attr  setValue:orgDate forKey:NSFileCreationDate];
//                NSFileManager *fileMgr = [[NSFileManager alloc] init];
//				if( ![fileMgr setAttributes:attr ofItemAtPath:fullPath error:nil] )
//				{
//					// cann't set attributes
//					NSLog(@"Failed to set attributes");
//				}
//                [fileMgr release];
//			}
//            doneFile++;
//            
//            if (object && pFunction && totalFile > 1)
//            {
//                [object performSelector:pFunction withObject:[NSNumber numberWithInt:(nStartPercent + (nEndPercent - nStartPercent) * doneFile / totalFile)]];
//            }
//		}
//		unzCloseCurrentFile( _unzFile );
//        bFirst = YES;
//        if (ret == UNZ_OK)
//		    ret = unzGoToNextFile( _unzFile );
//	}while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
//    [container release];
//    if(error){
//        *error = [NSError errorWithDomain:@"unknown error" code:ret userInfo:nil];
//    }
//    [fman release];
//	return success;
//}

//-(BOOL) UnzipMagmeTo:(NSString*) path overWrite:(BOOL) overwrite bookId:(NSString*)bookId processObject:(id)object processFunction:(SEL)pFunction startPercent:(int)nStartPercent endPercent:(int)nEndPercent error:(NSError **)error
//{
//    uLong uncompressed_size = 0;
//    uLong unZipDone_size = 0;
//    float percent = 0.0;
//	BOOL success = YES;
//    BOOL bFirst = YES;
//    
//	int ret = unzGoToFirstFile( _unzFile );
//	unsigned char		buffer[4096] = {0};
//	NSFileManager* fman = [[NSFileManager alloc] init];
//	if( ret!=UNZ_OK )
//	{
//		[self OutputErrorMessage:@"Failed"];
//	}
//    
//    unz_global_info globalInfo = {0};
//	ret = unzGetGlobalInfo(_unzFile, &globalInfo); //4.8.6 去除value stored 去掉ret =
//    uLong totalFile = globalInfo.number_entry;
//    uLong doneFile = 0;
//    
//	do{
//		if( [_password length]==0 )
//			ret = unzOpenCurrentFile( _unzFile );
//		else
//			ret = unzOpenCurrentFilePassword( _unzFile, [_password cStringUsingEncoding:NSASCIIStringEncoding] );
//		if( ret!=UNZ_OK )
//		{
//			[self OutputErrorMessage:@"Error occurs"];
//			success = NO;
//			break;
//		}
//		// reading data and write to file
//		int read ;
//		unz_file_info	fileInfo ={0};
//		ret = unzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
//		if( ret!=UNZ_OK )
//		{
//			[self OutputErrorMessage:@"Error occurs while getting file info"];
//			success = NO;
//			unzCloseCurrentFile( _unzFile );
//			break;
//		}
//        if (uncompressed_size == 0)
//            uncompressed_size = fileInfo.uncompressed_size;
//        
//		char* filename = (char*) malloc( fileInfo.size_filename +1 );
//		unzGetCurrentFileInfo(_unzFile, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
//		filename[fileInfo.size_filename] = '\0';
//		
//		NSString* strPath = [NSString  stringWithUTF8String:filename];
//        // check if it contains directory
//        BOOL isDirectory = NO;
//		if( filename[fileInfo.size_filename-1]=='/' || filename[fileInfo.size_filename-1]=='\\')
//			isDirectory = YES;
//		free( filename );
//		if( [strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location!=NSNotFound )
//		{// contains a path
//			strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
//		}
//        NSString* fileExt = [[strPath pathExtension] lowercaseString];
//		NSString* fullPath = [path stringByAppendingPathComponent:strPath];
//		
//		if( isDirectory )
//			[fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
//		else
//			[fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
//		if( [fman fileExistsAtPath:fullPath] && !isDirectory && !overwrite )
//		{
//			if( ![self OverWrite:fullPath] )
//			{
//				unzCloseCurrentFile( _unzFile );
//				ret = unzGoToNextFile( _unzFile );
//				continue;
//			}
//		}
//		FILE* fp = fopen( (const char*)[fullPath UTF8String], "wb");
//        
//        id *fsb;
//        BOOL needScramble = NO;
//        if ([fileExt isEqualToString:@"htm"] || [fileExt isEqualToString:@"html"])//html里面嵌入的图片，不能加密，否则无法显示
//        {
//            needScramble = YES;
//        }
//        
//        if (needScramble == YES) {
//            fsb = [FileScrambleMgr createScrambleTransaction];
//        }
//		while (fp)
//		{
//            BOOL bShouldStop = NO;
//            if(object && [object respondsToSelector:@selector(shouldCancelUnzip:)]){
//                NSMutableArray *array = [NSMutableArray array];
//                [object performSelector:@selector(shouldCancelUnzip:) withObject:array];
//                NSNumber *shouldStopNumber = [array objectAtIndex:0];
//                bShouldStop = [shouldStopNumber boolValue];
//            }
//            if(bShouldStop){
//                [self OutputErrorMessage:@"unzip cancelled"];
//                ret = UNZ_CANCELLED;
//                success = NO;
//                break;
//            }
//			read=unzReadCurrentFile(_unzFile, buffer, 4096);
//			if( read > 0 )
//			{
//                if (needScramble == YES)
//                {
//                    int outLen = 0;
//                    unsigned char *out = [FileScrambleMgr blockeScrambleBytesToBytes:fsb bytes:buffer length:read password:bookId isFirst:bFirst outLength:&outLen];
//                    bFirst = NO;
//                    if (outLen > 0){
//                        fwrite(out, outLen, 1, fp);
//                    }
//                    free(out);
//                }
//                else
//                {
//                    fwrite(buffer, read, 1, fp);
//                }
//                unZipDone_size += (uLong)read;
//                if (uncompressed_size > 0){
//                    percent = (float)(unZipDone_size * 100 / uncompressed_size);
//                    [self UnzipPerc: percent];
//                }
//			}
//			else if( read<0 )
//			{
//				[self OutputErrorMessage:@"Failed to reading zip file"];
//                ret = UNZ_PARAMERROR;
//                success = NO;
//				break;
//			}
//			else
//				break;
//		}
//		if( fp )
//		{
//            if (needScramble == YES){
//                int outLen = 0;
//                unsigned char *out = [FileScrambleMgr finishScrambleTransaction:fsb password:bookId outLength:&outLen];
//                if (outLen>0){
//                    fwrite(out, outLen, 1, fp);
//                }
//                free(out);
//                [FileScrambleMgr releaseScrambleTransaction:fsb];
//            }
//            
//			fclose( fp );
//			// set the orignal datetime property
//			NSDate* orgDate = nil;
//			
//			//{{ thanks to brad.eaton for the solution
//			NSDateComponents *dc = [[NSDateComponents alloc] init];
//			
//			dc.second = fileInfo.tmu_date.tm_sec;
//			dc.minute = fileInfo.tmu_date.tm_min;
//			dc.hour = fileInfo.tmu_date.tm_hour;
//			dc.day = fileInfo.tmu_date.tm_mday;
//			dc.month = fileInfo.tmu_date.tm_mon+1;
//			dc.year = fileInfo.tmu_date.tm_year;
//			
//			NSCalendar *gregorian = [[NSCalendar alloc]
//									 initWithCalendarIdentifier:NSGregorianCalendar];
//			
//			orgDate = [gregorian dateFromComponents:dc] ;
//			[dc release];
//			[gregorian release];
//			//}}
//			
//			
//			NSDictionary* attr = [NSDictionary dictionaryWithObject:orgDate forKey:NSFileModificationDate];
//			if( attr )
//			{
//				//		[attr  setValue:orgDate forKey:NSFileCreationDate];
//                NSFileManager *fileMgr = [[NSFileManager alloc] init];
//				if( ![fileMgr setAttributes:attr ofItemAtPath:fullPath error:nil] )
//				{
//					// cann't set attributes
//					NSLog(@"Failed to set attributes");
//				}
//                [fileMgr release];
//			}
//            doneFile++;
//            
//            if (object && pFunction && totalFile > 1)
//            {
//                [object performSelector:pFunction withObject:[NSNumber numberWithInt:(nStartPercent + (nEndPercent - nStartPercent) * doneFile / totalFile)]];
//            }
//		}
//		unzCloseCurrentFile( _unzFile );
//        bFirst = YES;
//        if (ret == UNZ_OK)
//		    ret = unzGoToNextFile( _unzFile );
//	}while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
//    
//    if(error){
//        *error = [NSError errorWithDomain:@"unknown error" code:ret userInfo:nil];
//    }
//    [fman release];
//	return success;
//}

//-(BOOL) UnzipCartoonPicTo:(NSString*) path overWrite:(BOOL) overwrite bookId:(NSString*)bookId
//{
//    uLong uncompressed_size = 0;
//    uLong unZipDone_size = 0;
//    float percent = 0.0;
//	BOOL success = YES;
//    BOOL bFirst = YES;
//    
//	int ret = unzGoToFirstFile( _unzFile );
//	unsigned char		buffer[4096] = {0};
//	NSFileManager* fman = [[NSFileManager alloc] init];
//	if( ret!=UNZ_OK )
//	{
//		[self OutputErrorMessage:@"Failed"];
//	}
//    
//    unz_global_info globalInfo = {0};
//	ret = unzGetGlobalInfo(_unzFile, &globalInfo); //4.8.6 去除value stored
//    
//	do{
//		if( [_password length]==0 )
//			ret = unzOpenCurrentFile( _unzFile );
//		else
//			ret = unzOpenCurrentFilePassword( _unzFile, [_password cStringUsingEncoding:NSASCIIStringEncoding] );
//		if( ret!=UNZ_OK )
//		{
//			[self OutputErrorMessage:@"Error occurs"];
//			success = NO;
//			break;
//		}
//		// reading data and write to file
//		int read ;
//		unz_file_info	fileInfo ={0};
//		ret = unzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
//		if( ret!=UNZ_OK )
//		{
//			[self OutputErrorMessage:@"Error occurs while getting file info"];
//			success = NO;
//			unzCloseCurrentFile( _unzFile );
//			break;
//		}
//        if (uncompressed_size == 0)
//            uncompressed_size = fileInfo.uncompressed_size;
//        
//		char* filename = (char*) malloc( fileInfo.size_filename +1 );
//		unzGetCurrentFileInfo(_unzFile, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
//		filename[fileInfo.size_filename] = '\0';
//		
//		NSString* strPath = [NSString  stringWithUTF8String:filename];
//        // check if it contains directory
//        BOOL isDirectory = NO;
//		if( filename[fileInfo.size_filename-1]=='/' || filename[fileInfo.size_filename-1]=='\\')
//			isDirectory = YES;
//		free( filename );
//		if( [strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location!=NSNotFound )
//		{// contains a path
//			strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
//		}
//        NSString* fullPath = [path stringByAppendingPathComponent:strPath];
//		
//		if( isDirectory )
//			[fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
//		else
//			[fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
//		if( [fman fileExistsAtPath:fullPath] && !isDirectory && !overwrite )
//		{
//			if( ![self OverWrite:fullPath] )
//			{
//				unzCloseCurrentFile( _unzFile );
//				ret = unzGoToNextFile( _unzFile );
//				continue;
//			}
//		}
//		FILE* fp = fopen( (const char*)[fullPath UTF8String], "wb");
//        
//        id *fsb;
//        fsb = [FileScrambleMgr createScrambleTransaction];
//		while (fp)
//		{
//            read=unzReadCurrentFile(_unzFile, buffer, 4096);
//			if(read > 0)
//			{
//                int outLen = 0;
//                unsigned char *out = [FileScrambleMgr blockeScrambleBytesToBytes:fsb bytes:buffer length:read password:bookId isFirst:bFirst outLength:&outLen];
//                bFirst = NO;
//                if (outLen > 0){
//                    fwrite(out, outLen, 1, fp);
//                }
//                free(out);
//                unZipDone_size += (uLong)read;
//                if (uncompressed_size > 0){
//                    percent = (float)(unZipDone_size * 100 / uncompressed_size);
//                    [self UnzipPerc: percent];
//                }
//			}
//			else if (read < 0)
//			{
//				[self OutputErrorMessage:@"Failed to reading zip file"];
//                ret = UNZ_PARAMERROR;
//                success = NO;
//
//                fclose(fp);
//                fp = NULL;
//                NSFileManager *fileMgr = [[NSFileManager alloc] init];
//				[fileMgr removeItemAtPath:fullPath error:nil];
//                [fileMgr release];
//
//				break;
//			}
//			else
//				break;
//		}
//		if( fp )
//		{
//            int outLen = 0;
//            unsigned char *out = [FileScrambleMgr finishScrambleTransaction:fsb password:bookId outLength:&outLen];
//            if (outLen>0){
//                fwrite(out, outLen, 1, fp);
//            }
//            free(out);
//            [FileScrambleMgr releaseScrambleTransaction:fsb];
//			fclose( fp );
//			// set the orignal datetime property
//			NSDate* orgDate = nil;
//			
//			//{{ thanks to brad.eaton for the solution
//			NSDateComponents *dc = [[NSDateComponents alloc] init];
//			
//			dc.second = fileInfo.tmu_date.tm_sec;
//			dc.minute = fileInfo.tmu_date.tm_min;
//			dc.hour = fileInfo.tmu_date.tm_hour;
//			dc.day = fileInfo.tmu_date.tm_mday;
//			dc.month = fileInfo.tmu_date.tm_mon+1;
//			dc.year = fileInfo.tmu_date.tm_year;
//			
//			NSCalendar *gregorian = [[NSCalendar alloc]
//									 initWithCalendarIdentifier:NSGregorianCalendar];
//			
//			orgDate = [gregorian dateFromComponents:dc] ;
//			[dc release];
//			[gregorian release];
//			//}}
//			
//			
//			NSDictionary* attr = [NSDictionary dictionaryWithObject:orgDate forKey:NSFileModificationDate];
//			if( attr )
//			{
//				//		[attr  setValue:orgDate forKey:NSFileCreationDate];
//                NSFileManager *fileMgr = [[NSFileManager alloc] init];
//				if( ![fileMgr setAttributes:attr ofItemAtPath:fullPath error:nil] )
//				{
//					// cann't set attributes
//					NSLog(@"Failed to set attributes");
//				}
//                [fileMgr release];
//			}
//		}
//		unzCloseCurrentFile( _unzFile );
//        bFirst = YES;
//        if (ret == UNZ_OK)
//		    ret = unzGoToNextFile( _unzFile );
//	}while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
//    
//    [fman release];
//	return success;
//}

-(BOOL) UnzipCloseFile
{
	_password = nil;
	if( _unzFile )
		return unzClose( _unzFile )==UNZ_OK;
	return YES;
}

-(BOOL) zipIsEncrypt
{
	int ret = unzGoToFirstFile(_unzFile);
	if (ret != UNZ_OK)
	{
		return NO;
	}
    unz_file_info fileInfo = {0};
    ret = unzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
    if (ret != UNZ_OK)
    {
        return NO;
    }
    if (fileInfo.flag & 0x0001)
    {
        return YES;
    }
    return NO;
}

#pragma mark wrapper for delegate
-(void) OutputErrorMessage:(NSString*) msg
{
	if( _delegate && [_delegate respondsToSelector:@selector(ErrorMessage:)] )
		[_delegate ErrorMessage:msg];
}

-(BOOL) OverWrite:(NSString*) file
{
	if( _delegate && [_delegate respondsToSelector:@selector(OverWriteOperation:)] )
		return [_delegate OverWriteOperation:file];
	return YES;
}

-(void) UnzipPerc:(float) percent
{
    if( _delegate && [_delegate respondsToSelector:@selector(UnzipPercent:)])
		[_delegate UnzipPercent:percent];
}

#pragma mark get NSDate object for 1980-01-01
-(NSDate*) Date1980
{
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setDay:1];
	[comps setMonth:1];
	[comps setYear:1980];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
	NSDate *date = [gregorian dateFromComponents:comps];
	
	[comps release];
	[gregorian release];
	return date;
}

+ (BOOL) UnzipFile:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite
{
    if ((zipFile == nil) || (path == nil))
        return NO;
    
    ZipArchive* zip = [[[ZipArchive alloc] init] autorelease];
    
    if (![zip UnzipOpenFile:zipFile])
        return NO;
    
    if (![zip UnzipFileTo: path overWrite: overwrite])
        return NO;
    
    return [zip UnzipCloseFile];
}

+ (BOOL) UnzipFile2SameDir:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite
{
    if ((zipFile == nil) || (path == nil))
        return NO;
    
    ZipArchive* zip = [[[ZipArchive alloc] init] autorelease];
    
    if (![zip UnzipOpenFile:zipFile])
        return NO;
    
    if (![zip UnzipFileToSameDir:path overWrite: overwrite])
        return NO;
    
    return [zip UnzipCloseFile];
}

+ (BOOL) UnzipFile:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite password:(NSString*) password
{
    if ((zipFile == nil) || (path == nil))
        return NO;
    
    ZipArchive* zip = [[[ZipArchive alloc] init] autorelease];
    
    if (![zip UnzipOpenFile:zipFile Password:password])
        return NO;
    
    if (![zip UnzipFileTo: path overWrite: overwrite])
        return NO;
    
    return [zip UnzipCloseFile];
}

+ (BOOL) zipFileIsEncryp: (NSString *)zipFile
{
    if (zipFile == nil)
        return NO;
    
    ZipArchive* zip = [[[ZipArchive alloc] init] autorelease];
    if (![zip UnzipOpenFile:zipFile])
        return NO;
    BOOL ret = [zip zipIsEncrypt];
    [zip UnzipCloseFile];
    return ret;
}

+ (BOOL) zipData2File:(NSString*) zipFile data:(NSData*)data password:(NSString*)password
{
    BOOL ret = NO;
    ZipArchive* zip = [[[ZipArchive alloc] init] autorelease];
	if ([zip CreateZipFile2:zipFile Password:password] == NO)
        return NO;
    
	if ([zip addDataToZip:data newname:@"tmp.txt" compressLevel:Z_BEST_SPEED] == NO)
        return NO;
    
	ret = [zip CloseZipFile2];
    return ret;
}

+ (NSData *) UnzipFile2Data:(NSString*) zipFile password:(NSString*) password
{
    if (zipFile == nil)
        return nil;
    
    NSData *data = nil;
    ZipArchive* zip = [[[ZipArchive alloc] init] autorelease];
    
    if ([zip UnzipOpenFile:zipFile Password:password])
    {
        data = [zip UnzipFileToData];
    }
    
    [zip UnzipCloseFile];
    if (data == nil)
    {
        FILE* fp = fopen((const char*)[zipFile UTF8String], "rb");
        unsigned char buf[4];
        if (fp)
        {
            if (4 == fread(buf, 1, sizeof(buf), fp))
            {
                if ((buf[0] == 0x50) && (buf[1] == 0x4B) && (buf[2] == 0x03) && (buf[3] == 0x04))
                {
                    NSLog(@"it is a zip file");
                }
                else {
                    data = [NSData dataWithContentsOfFile:zipFile];
                }
            }
            fclose(fp);
        }
    }
    return data;
}

+ (BOOL) UnzipContainer:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite bookId:(NSString*)bookId  dir:(NSString *)localPath processObject:(id)object processFunction:(SEL)pFunction startPercent:(int)nStartPercent endPercent:(int)nEndPercent error:(NSError **)error
{
    if ((zipFile == nil) || (path == nil))
        return NO;
    
    ZipArchive* zip = [[[ZipArchive alloc] init] autorelease];
    
    if (![zip UnzipOpenFile:zipFile])
        return NO;
    
    if (![zip UnzipContainerTo: path overWrite: overwrite bookId:bookId dir:localPath processObject:object processFunction:pFunction startPercent:nStartPercent endPercent:nEndPercent error:error])
        return NO;
    
    return [zip UnzipCloseFile];
}

+ (BOOL) UnzipContainer:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite password:(NSString*) password bookId:(NSString*)bookId  dir:(NSString *)localPath processObject:(id)object processFunction:(SEL)pFunction startPercent:(int)nStartPercent endPercent:(int)nEndPercent error:(NSError **)error
{
    if ((zipFile == nil) || (path == nil))
        return NO;
    
    ZipArchive* zip = [[[ZipArchive alloc] init] autorelease];
    
    if (![zip UnzipOpenFile:zipFile Password:password])
        return NO;
    
    if (![zip UnzipContainerTo: path overWrite: overwrite bookId:bookId dir:localPath processObject:object processFunction:pFunction startPercent:nStartPercent endPercent:nEndPercent error:error])
        return NO;
    
    return [zip UnzipCloseFile];
}

+ (BOOL) UnzipMagme:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite password:(NSString*) password bookId:(NSString*)bookId processObject:(id)object processFunction:(SEL)pFunction startPercent:(int)nStartPercent endPercent:(int)nEndPercent error:(NSError **)error
{
    if ((zipFile == nil) || (path == nil))
        return NO;
    
    ZipArchive* zip = [[[ZipArchive alloc] init] autorelease];
    
    if (![zip UnzipOpenFile:zipFile Password:password])
        return NO;
    
    if (![zip UnzipMagmeTo: path overWrite: overwrite bookId:bookId processObject:object processFunction:pFunction startPercent:nStartPercent endPercent:nEndPercent error:error])
        return NO;
    
    return [zip UnzipCloseFile];
}

+ (BOOL) UnzipCartoonPic:(NSString*) zipFile unZipDir:(NSString*) path overWrite:(BOOL) overwrite password:(NSString*) password bookId:(NSString*)bookId {
    if ((zipFile == nil) || (path == nil))
        return NO;
    
    ZipArchive* zip = [[[ZipArchive alloc] init] autorelease];
    
    if (![zip UnzipOpenFile:zipFile Password:password])
        return NO;
    
    if (![zip UnzipCartoonPicTo: path overWrite: overwrite bookId:bookId])
        return NO;
    
    return [zip UnzipCloseFile];
}
@end
