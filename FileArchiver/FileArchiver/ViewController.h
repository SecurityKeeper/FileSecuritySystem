//
//  ViewController.h
//  FileArchiver
//
//  Created by Jiao Liu on 12/28/15.
//  Copyright (c) 2015 Jiao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    @private
    NSArray *filesArray;
    UITableView *fileTable;
}


@end

