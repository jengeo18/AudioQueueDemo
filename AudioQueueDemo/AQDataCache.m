//
//  AQDataCache.m
//  AudioQueueDemo
//
//  Created by jajeo on 2018/9/13.
//  Copyright © 2018 JENGEO. All rights reserved.
//

#import "AQDataCache.h"

@implementation AQDataCache {
    int _size;
    NSMutableArray *_bufArray;
}

- (instancetype)init
{
    return [self initWithCacheSize:10240];
}

- (instancetype) initWithCacheSize: (int) size {
    if (self = [super init]) {
        _size = size;
        _bufArray = @[].mutableCopy;
    }
    return self;
}

- (void)pushData: (NSData*)data {
    if (_bufArray.count == _size) {
        [_bufArray removeObjectAtIndex:0];
    }
    [_bufArray addObject:data];
    
}
- (NSData*)popData {
    NSData *d = _bufArray.firstObject;
    if (_bufArray.count) {
        [_bufArray removeObjectAtIndex:0];
    }
    return d;
}

@end
