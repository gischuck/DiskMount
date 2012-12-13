//
//  MyDiskUtil.h
//  DiskMount
//
//  Created by WenHao on 12-12-10.
//  Copyright (c) 2012年 WenHao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiskInfoStruct.h"

@interface MyDiskUtil : NSObject
{
    NSStatusItem *_statusItem;
    NSMutableArray *myDiskList;
}


@property (unsafe_unretained) IBOutlet NSWindow *window;
- (IBAction)refreshDisk:(id)sender;
- (IBAction)mountDisk:(id)sender;
- (IBAction)unmountDisk:(id)sender;
@property (weak) IBOutlet NSComboBox *listView;
- (IBAction)showApp:(id)sender;
- (IBAction)quit:(id)sender;
@property (weak) IBOutlet NSMenu *statusMenu;


@end
