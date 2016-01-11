//
//  ViewController.m
//  FileArchiver
//
//  Created by Jiao Liu on 12/28/15.
//  Copyright (c) 2015 Jiao. All rights reserved.
//

#import "ViewController.h"
#import "FileManager.h"
#import "FileReaderViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    filesArray = [[FileManager sharedInstance] loadFiles];
    fileTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    fileTable.delegate = self;
    fileTable.dataSource = self;
    fileTable.tableFooterView = [UIView new];
    [self.view addSubview:fileTable];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(inputFileBtnClicked)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashAllClicked)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)trashAllClicked
{
    [[FileManager sharedInstance] removeAllFiles];
    filesArray = nil;
    [fileTable reloadData];
}

- (void)inputFileBtnClicked
{
    [[FileManager sharedInstance] saveFile:[NSData dataWithContentsOfFile:@"/Users/Jiao/Desktop/TouchC_UI/启动/loading.gif"] Info:@{@"fileName":@"loading",@"fileType":@"gif"}];
    filesArray = [[FileManager sharedInstance] loadFiles];
    [fileTable reloadData];
}

#pragma mark - Tableview Delegate&Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return filesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *Cell = [tableView dequeueReusableCellWithIdentifier:@"File_Cell"];
    if (Cell == nil) {
        Cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"File_Cell"];
        Cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    NSString *fileName = [[filesArray objectAtIndex:indexPath.row] objectForKey:@"fileName"];
    Cell.textLabel.text = fileName;
    return Cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *fileInfo = [filesArray objectAtIndex:indexPath.row];
    FileReaderViewController *readerVC = [[FileReaderViewController alloc] init];
    readerVC.title = [fileInfo objectForKey:@"fileName"];
    readerVC.fileMIME = [fileInfo objectForKey:@"fileMIME"];
    readerVC.fileEncodingName = [fileInfo objectForKey:@"fileEncodingName"];
    readerVC.fileData = [[FileManager sharedInstance] presentFile:fileInfo];
    [self.navigationController pushViewController:readerVC animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *fileInfo = [filesArray objectAtIndex:indexPath.row];
        [[FileManager sharedInstance] removeFile:fileInfo];
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:filesArray];
        [tempArray removeObject:fileInfo];
        filesArray = tempArray;
        [fileTable reloadData];
    }
}

@end
