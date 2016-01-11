//
//  FileManager.h
//  FileArchiver
//
//  Created by Jiao Liu on 12/28/15.
//  Copyright (c) 2015 Jiao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileManager : NSObject
{
    @private
    NSString *_fileDirectory;
    NSFileManager *_fileManager;
    int systemKey;
    int stamp;
    NSString *AESKey;
}

+ (id)sharedInstance;
/*
 Open Methods
 */
- (BOOL)saveFile:(NSData *)data Info:(NSDictionary *)fileInfo;
- (NSArray *)loadFiles;
- (NSData *)presentFile:(NSDictionary *)fileInfo;
- (BOOL)removeFile:(NSDictionary *)fileInfo;
- (BOOL)removeAllFiles;

@end
