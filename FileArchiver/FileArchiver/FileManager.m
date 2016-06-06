//
//  FileManager.m
//  FileArchiver
//
//  Created by Jiao Liu on 12/28/15.
//  Copyright (c) 2015 Jiao. All rights reserved.
//

#import "FileManager.h"
#import <CommonCrypto/CommonCrypto.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation FileManager

+ (id)sharedInstance
{
    //test
    static FileManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FileManager alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _fileDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingFormat:@"/Files"];
        NSLog(@"%@",_fileDirectory);
        _fileManager = [NSFileManager defaultManager];
        if (![_fileManager fileExistsAtPath:_fileDirectory]) {
            [_fileManager createDirectoryAtPath:_fileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        systemKey = 10;
        stamp = 123456;
        AESKey = @"hello world";
    }
    return self;
}

#pragma mark - Open Methods

- (BOOL)saveFile:(NSData *)data Info:(NSDictionary *)fileInfo
{
    if (data == nil) {
        return false;
    }
    
    NSString *indexTablePath = [self getIndexTablePath];
    NSData *indexTableData = [NSData dataWithContentsOfFile:indexTablePath];
    NSMutableDictionary *indexDic = [NSMutableDictionary dictionary];
    NSInteger index = 0;
    NSMutableArray *fileInfoArray = [NSMutableArray array];
    if ([indexTableData length] != 0) {
        NSData *tempData = [self decrypt:indexTableData];
        tempData = [self removeStamp:tempData];
        indexDic = [NSMutableDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:tempData options:NSJSONReadingMutableLeaves error:nil]];
        index = [[indexDic objectForKey:@"lastNode"] integerValue];
        fileInfoArray = [NSMutableArray arrayWithArray:[indexDic objectForKey:@"fileInfo"]];
    }
    
    NSMutableArray *tempBlockArray = [NSMutableArray arrayWithArray:[self separateData:data]];
    for (int i = 0; i < tempBlockArray.count; i++) {
        NSData *tempData = [tempBlockArray objectAtIndex:i];
        tempData = [self addStamp:tempData];
        [tempBlockArray replaceObjectAtIndex:i withObject:[self encrypt:tempData]];
    }
    NSMutableArray *fileBlockArray = [NSMutableArray arrayWithArray:[self archiveData:tempBlockArray lastNode:index]];
    
    NSMutableDictionary *tempInfoDic = [NSMutableDictionary dictionaryWithDictionary:fileInfo];
    [tempInfoDic setObject:fileBlockArray forKey:@"fileBlocks"];
    if ([[fileInfo objectForKey:@"fileMIME"] length] == 0) {
        [tempInfoDic setObject:[self getFileMIMEType:[fileInfo objectForKey:@"fileType"]] forKey:@"fileMIME"];
    }
    [fileInfoArray addObject:tempInfoDic];
    
    [indexDic setObject:fileInfoArray forKey:@"fileInfo"];
    [indexDic setObject:[NSNumber numberWithInteger:(index + fileBlockArray.count)] forKey:@"lastNode"];
    [self updateIndexTable:indexDic];
    return true;
}

- (NSArray *)loadFiles
{
    NSString *indexTablePath = [self getIndexTablePath];
    NSData *indexTableData = [NSData dataWithContentsOfFile:indexTablePath];
    NSMutableDictionary *indexDic = [NSMutableDictionary dictionary];
    NSMutableArray *fileInfoArray = [NSMutableArray array];
    if ([indexTableData length] != 0) {
        NSData *tempData = [self decrypt:indexTableData];
        tempData = [self removeStamp:tempData];
        indexDic = [NSMutableDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:tempData options:NSJSONReadingMutableLeaves error:nil]];
        fileInfoArray = [NSMutableArray arrayWithArray:[indexDic objectForKey:@"fileInfo"]];
    }
    return fileInfoArray;
}

- (NSData *)presentFile:(NSDictionary *)fileInfo
{
    NSMutableArray *fileBlockArray = [self unArchiveFile:[fileInfo objectForKey:@"fileBlocks"]];
    for (int i = 0; i < fileBlockArray.count; i++) {
        NSData *tempData = [fileBlockArray objectAtIndex:i];
        tempData = [self decrypt:tempData];
        tempData = [self removeStamp:tempData];
        [fileBlockArray replaceObjectAtIndex:i withObject:tempData];
    }
    return [self combineData:fileBlockArray];
}

- (BOOL)removeFile:(NSDictionary *)fileInfo
{
    if (fileInfo == nil) {
        return false;
    }
    NSMutableArray *fileBlockArray = [fileInfo objectForKey:@"fileBlocks"];
    for (NSString *archiveName in fileBlockArray) {
        NSString *filePath = [_fileDirectory stringByAppendingString:archiveName];
        [_fileManager removeItemAtPath:filePath error:nil];
    }
    
    NSString *indexTablePath = [self getIndexTablePath];
    NSData *indexTableData = [NSData dataWithContentsOfFile:indexTablePath];
    NSMutableDictionary *indexDic = [NSMutableDictionary dictionary];
    NSMutableArray *fileInfoArray = [NSMutableArray array];
    if ([indexTableData length] != 0) {
        NSData *tempData = [self decrypt:indexTableData];
        tempData = [self removeStamp:tempData];
        indexDic = [NSMutableDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:tempData options:NSJSONReadingMutableLeaves error:nil]];
        fileInfoArray = [NSMutableArray arrayWithArray:[indexDic objectForKey:@"fileInfo"]];
    }
    
    [fileInfoArray removeObject:fileInfo];
    [indexDic setObject:fileInfoArray forKey:@"fileInfo"];
    [self updateIndexTable:indexDic];
    return true;
}

- (BOOL)removeAllFiles
{
    return [_fileManager removeItemAtPath:_fileDirectory error:nil];
}

#pragma mark - Inner Methods

- (NSString *)convertIntToBase64:(NSInteger)Num
{
    NSString *intStr = [NSString stringWithFormat:@"%ld",Num];
    NSData *originalData = [intStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *encodeStr = [originalData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    return encodeStr;
}

- (NSInteger)convertBase64ToInt:(NSString *)String
{
    NSData *decodeData = [[NSData alloc] initWithBase64EncodedString:String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSString *decodeString = [[NSString alloc] initWithData:decodeData encoding:NSASCIIStringEncoding];
    return [decodeString intValue];
}

- (NSString *)getFileMIMEType:(NSString *)extension
{
    if (extension == nil) {
        return @"";
    }
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    NSString *retStr = (__bridge NSString *)MIMEType;
    CFAutorelease(UTI);
    if (retStr == nil) {
        return @"";
    }
    CFAutorelease(MIMEType);
    return retStr;
}

#pragma mark - Index Table

- (NSString *)getIndexTablePath
{
    int remain = stamp % systemKey;
    remain = remain == 0 ? systemKey : remain;
    NSString *filePath = [_fileDirectory stringByAppendingFormat:@"/%@.archive",[self convertIntToBase64:remain]];
    if (![_fileManager fileExistsAtPath:_fileDirectory]) {
        [_fileManager createDirectoryAtPath:_fileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (![_fileManager fileExistsAtPath:filePath]) {
        [_fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    return filePath;
}

- (void)updateIndexTable:(NSDictionary *)dic
{
    NSData *tempData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSData *IndexData = tempData;
    IndexData = [self addStamp:IndexData];
    NSString *indexTablePath = [self getIndexTablePath];
    [[self encrypt:IndexData] writeToFile:indexTablePath atomically:YES];
}

#pragma mark - Separator

- (NSArray *)separateData:(NSData *)data
{
    NSUInteger dataLength = [data length];
    NSUInteger randomNum = random();
    NSUInteger blockNum = randomNum % systemKey;
    blockNum = blockNum == 0 ? systemKey : blockNum;
    NSUInteger maxLength = dataLength / blockNum;
    if (dataLength < blockNum) {
        return [NSArray arrayWithObject:data];
    }
    else
    {
        NSMutableArray *retArray = [NSMutableArray array];
        NSUInteger currentLoc = 0;
        for (int index = 0; index < blockNum - 1; index++) {
            NSUInteger getDataLength = random() % maxLength;
            getDataLength = getDataLength == 0 ? maxLength : getDataLength;
            NSData *subData = [data subdataWithRange:NSMakeRange(currentLoc, getDataLength)];
            currentLoc += getDataLength;
            [retArray addObject:subData];
        }
        NSData *lastData = [data subdataWithRange:NSMakeRange(currentLoc, dataLength - currentLoc)];
        [retArray addObject:lastData];
        return retArray;
    }
}

- (NSData *)combineData:(NSArray *)array
{
    NSMutableData *retData = [NSMutableData data];
    for (NSData *data in array) {
        [retData appendData:data];
    }
    return retData;
}

#pragma mark - Stamper

- (NSData *)addStamp:(NSData *)data
{
    if (data == nil) {
        data = [NSData data];
    }
    NSMutableData *retData = [NSMutableData dataWithData:data];
    NSString *stampStr = [NSString stringWithFormat:@"%d",stamp];
    NSData *stampData = [stampStr dataUsingEncoding:NSUTF8StringEncoding];
    [retData appendData:stampData];
    return retData;
}

- (NSData *)removeStamp:(NSData *)data
{
    NSString *stampStr = [NSString stringWithFormat:@"%d",stamp];
    NSData *stampData = [stampStr dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        return nil;
    }
    NSUInteger dataLength = [data length];
    return [data subdataWithRange:NSMakeRange(0, dataLength - [stampData length])];
}

#pragma mark - D/Encryptor

- (NSData *)encrypt:(NSData *)data
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [AESKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

- (NSData *)decrypt:(NSData *)data
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [AESKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}

#pragma mark - Archiver

- (NSMutableArray *)archiveData:(NSArray *)dataArray lastNode:(NSInteger)index
{
    NSMutableArray *retArray = [NSMutableArray array];
    int remain = stamp % systemKey;
    remain = remain == 0 ? systemKey : remain;
    int currentLoc = 0;
    for (NSData *data in dataArray) {
        if (index < remain) {
            NSString *archiveName = [NSString stringWithFormat:@"/%@.archive",[self convertIntToBase64:(index + currentLoc)]];
            NSString *filePath = [_fileDirectory stringByAppendingString:archiveName];
            [_fileManager createFileAtPath:filePath contents:data attributes:nil];
            [retArray addObject:archiveName];
        }
        else
        {
            NSString *archiveName = [NSString stringWithFormat:@"/%@.archive",[self convertIntToBase64:(index + currentLoc + 1)]];
            NSString *filePath = [_fileDirectory stringByAppendingString:archiveName];
            [_fileManager createFileAtPath:filePath contents:data attributes:nil];
            [retArray addObject:archiveName];
        }
        currentLoc++;
    }
    return retArray;
}

- (NSMutableArray *)unArchiveFile:(NSArray *)fileArray
{
    NSMutableArray *retArray = [NSMutableArray array];
    for (NSString *archiveName in fileArray) {
        NSData *blockData = [NSData dataWithContentsOfFile:[_fileDirectory stringByAppendingString:archiveName]];
        if ([blockData length] == 0) {
            continue;
        }
        [retArray addObject:blockData];
    }
    return retArray;
}

@end
