//
//  AppDelegate.m
//  DiskMount
//
//  Created by WenHao on 12-12-10.
//  Copyright (c) 2012年 WenHao. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // Insert code here to initialize your application   
}

//Click Dock Show App
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    [self.window makeKeyAndOrderFront:self];
    if (flag) {
        return NO;
    }
    return YES;
}
@end
