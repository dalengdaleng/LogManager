//
//  ViewController.m
//  Prislog
//
//  Created by NetEase on 16/4/25.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "ViewController.h"
#import "PRISLog.h"
#import "ZipArchive.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.textView setText:@"ViewController viewDidLoad"];
    PRISLog(@"ViewController viewDidLoad");
    
    //日志文件上传处理代码
    NSString*filepath;
    ///生成日志文件
    ZipArchive* zip = [[ZipArchive alloc] init];
    NSString *tmpPath = NSTemporaryDirectory();
    NSString* l_zipfile = [tmpPath stringByAppendingString:@"/log.zip"] ;
    NSString* logFile1 = PRISLogGetLogFilepath() ;
    NSString* logFile2 = PRISLogGetLastlogFilepath() ;
    
    BOOL ret = [zip CreateZipFile2:l_zipfile];
    ret = [zip addFileToZip:logFile1 newname:@"log.txt"];
    ret = [zip addFileToZip:logFile2 newname:@"log_last.txt"];
    if( ![zip CloseZipFile2] )
    {
        l_zipfile = @"";
    }

    filepath=l_zipfile;
    
    //下面调用http task上传接口上传即可。
    
    //
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
