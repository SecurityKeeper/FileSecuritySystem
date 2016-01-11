//
//  FileReaderViewController.m
//  FileArchiver
//
//  Created by Jiao Liu on 12/29/15.
//  Copyright (c) 2015 Jiao. All rights reserved.
//

#import "FileReaderViewController.h"

@interface FileReaderViewController ()

@end

@implementation FileReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [webView loadData:_fileData MIMEType:_fileMIME textEncodingName:_fileEncodingName baseURL:nil];
    [webView setScalesPageToFit:YES];
    [self.view addSubview:webView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
