//
//  FileReaderViewController.h
//  FileArchiver
//
//  Created by Jiao Liu on 12/29/15.
//  Copyright (c) 2015 Jiao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileReaderViewController : UIViewController

@property (nonatomic, strong)NSData *fileData;
@property (nonatomic, strong)NSString *fileMIME;
@property (nonatomic, strong)NSString *fileEncodingName;

@end
