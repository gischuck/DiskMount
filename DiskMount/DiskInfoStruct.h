//
//  DiskInfoStruct.h
//  DiskMount
//
//  Created by WenHao on 12-12-11.
//  Copyright (c) 2012年 WenHao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DiskInfoStruct : NSObject

@property (strong, nonatomic) NSString *diskName;
@property (strong, nonatomic) NSString *diskID;
@property (nonatomic) BOOL isMount;
@property (nonatomic) BOOL ejectable;

@end
