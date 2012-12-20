//
//  MyDiskUtil.m
//  DiskMount
//
//  Created by WenHao on 12-12-10.
//  Copyright (c) 2012年 WenHao. All rights reserved.
//

#import "MyDiskUtil.h"

@implementation MyDiskUtil

static bool firstRun = NO;

- (void)awakeFromNib
{    
    myDiskList = [[NSMutableArray alloc] init];
    [self refreshDisk:nil];
    firstRun = YES;
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    [_statusItem setImage:[NSImage imageNamed:@"heart"]];
    [_statusItem setToolTip:NSLocalizedString(@"App_Name", nil)];
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:[self statusMenu]];
}
- (void)dealloc
{
	[[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
}

//Task Function
- (NSArray *)doTaskPath:(NSString *)launchPath taskArgumentName:(NSString *)argumentName withParms:(NSString *)parms
{
    //array[0] output
    //array[1] errOutput
    
    @try {
        NSTask *diskutil=[[NSTask alloc] init];
        NSPipe *pipe=[[NSPipe alloc] init];
        NSPipe *pipeError=[[NSPipe alloc] init];
        NSFileHandle *handle;
        NSFileHandle *handleError;
        [diskutil setLaunchPath:@"/usr/sbin/diskutil"];
        [diskutil setArguments:[NSArray arrayWithObjects:argumentName, parms, nil]];
        [diskutil setStandardOutput:pipe];
        [diskutil setStandardError:pipeError];
        handle=[pipe fileHandleForReading];
        handleError=[pipeError fileHandleForReading];
        [diskutil launch];
        NSString *string=[[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
        NSString *stringError=[[NSString alloc] initWithData:[handleError readDataToEndOfFile] encoding:NSUTF8StringEncoding];
        NSArray *arr = [[NSArray alloc]initWithObjects:string, stringError, nil];
        NSLog(@"%@\nError:%@", string, stringError);
        return arr;
    }
    @catch (NSException *exception) {
        NSLog(@"Caught %@%@", [exception name], [exception reason]);
        return NULL;
    }
}

//Get All Volunmes
- (NSMutableArray *)ListMountedVolumeInOpticalDrive
{
    @try {
        NSMutableArray *diskInfo = [[NSMutableArray alloc] init];
        NSMutableArray *disklist = [[NSMutableArray alloc] init];
        NSArray *diskInfoLines;
        NSMutableArray *diskId = [[NSMutableArray alloc] init];
        NSMutableArray *diskName = [[NSMutableArray alloc] init];

        NSArray *output = [self doTaskPath:@"/usr/sbin/diskutil" taskArgumentName:@"list" withParms:nil];
        NSString *standardOut = [output objectAtIndex:0];
        NSString *errOut = [output objectAtIndex:1];
        
        diskInfoLines = [standardOut componentsSeparatedByString:@"\n"];
        for (NSString *str in diskInfoLines) {
            if ([str rangeOfString:@"HFS"].length > 0 || [str rangeOfString:@"FAT"].length > 0 ) {
                NSString *tmp = [str stringByReplacingOccurrencesOfString:@"  " withString:@" "];
                for (int i=0; i<5; i++) {
                    tmp = [tmp stringByReplacingOccurrencesOfString:@"  " withString:@" "];
                }
                [disklist addObject:tmp];
            }
            
        }
        
        
        for (NSString *tmp in disklist) {
            NSArray *arr = [tmp componentsSeparatedByString:@" "];
            [diskId addObject:[arr lastObject]];
        }
        NSLog(@"Disk Count:%ld", diskId.count);
        
        //Processing Infomation
        for (int i=0; i<diskId.count; i++) {
            //Check If Disk is Unmounted before, and don't awake it for checking
            BOOL shouldCheck = YES;
            DiskInfoStruct *infoOld;
            for (infoOld in myDiskList) {
                if (infoOld.diskID == [diskId objectAtIndex:i]) {
                    shouldCheck = NO;
                    break;
                }
            }
            if (shouldCheck) {
                NSArray *output = [self doTaskPath:@"/usr/sbin/diskutil" taskArgumentName:@"info" withParms:[diskId objectAtIndex:i]];
                NSString *standardOut = [output objectAtIndex:0];
                NSString *errOut = [output objectAtIndex:1];
                
                DiskInfoStruct *info = [[DiskInfoStruct alloc]init];
                //Volume Name
                NSArray *listItems = [standardOut componentsSeparatedByString:@"Volume Name:"];
                if ([listItems objectAtIndex:0]) {
                    listItems = [[listItems objectAtIndex:1] componentsSeparatedByString:@"Escaped with Unicode:"];
                    NSString *name = [[listItems objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    [diskName addObject:name];
                    
                    info.diskID = [diskId objectAtIndex:i];
                    info.diskName = name;
                    if (firstRun == NO) {
                        info.isMount = YES;
                    }
                    NSLog(@"%@ - %@", info.diskName, info.diskID);
                }
                //Ejectable
                listItems = [standardOut componentsSeparatedByString:@"Ejectable:"];
                if ([listItems objectAtIndex:0]) {
                    listItems = [[listItems objectAtIndex:1] componentsSeparatedByString:@"Whole:"];
                    NSString *eject = [[listItems objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if ([eject isEqualToString:@"No"]) {
                        info.ejectable = NO;
                    }
                    else
                    {
                        info.ejectable = YES;
                    }
                    
                    NSLog(@"%@ - %@", info.diskName, info.diskID);
                }
                [diskInfo addObject:info];
            }
            else
            {
                if (infoOld) {
                    [diskInfo addObject:infoOld];
                }
            
            }
        }
        return diskInfo;
    }
    @catch (NSException *exception) {
        NSLog(@"Caught %@%@", [exception name], [exception reason]);
        return NULL;
    }
}


//Mount Disk
- (BOOL)MountDiskById:(NSString *)diskName
{
    @try {
        for (DiskInfoStruct *info in myDiskList) {
            if ([info.diskName isEqualToString:diskName]) {
                NSString *parms = [[NSString alloc]initWithFormat:@"/dev/%@", info.diskID];
                NSArray *output = [self doTaskPath:@"/usr/sbin/diskutil" taskArgumentName:@"mountDisk" withParms:parms];
                NSString *standardOut = [output objectAtIndex:0];
                NSString *errOut = [output objectAtIndex:1];

                if ([errOut rangeOfString:@"unable"].length > 0 || [errOut rangeOfString:@"fail"].length > 0) {
                    return NO;
                }
                if ([standardOut rangeOfString:@"successfully"].length > 0) {
                    return YES;
                }
            }
            
        }
        return NO;
    }
    @catch (NSException *exception) {
        NSLog(@"Caught %@%@", [exception name], [exception reason]);
        return NO;
    }
}

//Unmount Disk
- (BOOL)UnMountDiskById:(NSString *)diskName
{
    @try {
        for (DiskInfoStruct *info in myDiskList) {
            if ([info.diskName isEqualToString:diskName]) {
                NSString *parms = [[NSString alloc]initWithFormat:@"/dev/%@", info.diskID];
                NSArray *output = [self doTaskPath:@"/usr/sbin/diskutil" taskArgumentName:@"eject" withParms:parms];
                NSString *standardOut = [output objectAtIndex:0];
                NSString *errOut = [output objectAtIndex:1];
                
                if ([errOut rangeOfString:@"fail"].length > 0) {
                    return NO;
                }
                if ([standardOut rangeOfString:@"ejected"].length > 0) {
                    info.isMount = NO;
                    if (info.ejectable) {
                        [self.listView removeItemWithObjectValue:info.diskName];
                        [myDiskList removeObject:info];
                        
                        
                        if (myDiskList.count > 0) {
                            [self.listView selectItemAtIndex:0];
                        }
                    }
                    return YES;
                }
            }
            
        }
        return NO;
    }
    @catch (NSException *exception) {
        NSLog(@"Caught %@%@", [exception name], [exception reason]);
        return NO;
    }

}
- (IBAction)refreshDisk:(id)sender {
    [self.listView removeAllItems];
    myDiskList = [self ListMountedVolumeInOpticalDrive];
    for (DiskInfoStruct *info in myDiskList) {
        [self.listView addItemWithObjectValue:info.diskName];
    }
    if (myDiskList.count > 0) {
        [self.listView selectItemAtIndex:0];
    }
}

//Alert Window
- (void)InformationWindow:(NSString *)msgTitle withDetail:(NSString *)str
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:msgTitle];
    [alert setInformativeText:str];
    [alert addButtonWithTitle:@"OK"];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(DiscardAlertDidEnd:returnCode:
                                              contextInfo:)
                        contextInfo:nil];

}

- (IBAction)mountDisk:(id)sender {
    if ([self MountDiskById:[self.listView stringValue]]) {
        [self InformationWindow:NSLocalizedString(@"Informaion", nil) withDetail:NSLocalizedString(@"Mount_Disk_Successfully", nil)];
    }
    else
    {
        [self InformationWindow:NSLocalizedString(@"Informaion", nil) withDetail:NSLocalizedString(@"Mount_Disk_Unsuccessfully", nil)];
    }
}
- (void)DiscardAlertDidEnd:(NSAlert *)alert
                returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    //NSLog (@"Button %d clicked",returnCode);
}
- (IBAction)unmountDisk:(id)sender {
    if ([self UnMountDiskById:[self.listView stringValue]]) {
        [self InformationWindow:NSLocalizedString(@"Informaion", nil) withDetail:NSLocalizedString(@"Eject_Disk_Successfully", nil)];
    }
    else
    {
        [self InformationWindow:NSLocalizedString(@"Informaion", nil) withDetail:NSLocalizedString(@"Eject_Disk_Unsuccessfully", nil)]; 
    }
}
- (IBAction)showApp:(id)sender {
    [[self window] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)quit:(id)sender {
    [NSApp terminate: nil];
}
@end
