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
    NSLock *_audioLock;
}

- (instancetype)init
{
    return [self initWithCacheSize:10240];
}

- (instancetype) initWithCacheSize: (int) size {
    if (self = [super init]) {
        _size = size;
        _bufArray = @[].mutableCopy;
        _audioLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)pushData: (NSData*)data {
    [_audioLock lock];
    if (_bufArray.count == _size) {
        [_bufArray removeObjectAtIndex:0];
    }
    [_bufArray addObject:data];
    [_audioLock unlock];
}
- (NSData*)popData {
    [_audioLock lock];
    if (_bufArray.count == 0) {
        [_audioLock unlock];
        return nil;
    }
    NSData *d = _bufArray.firstObject;
    if (_bufArray.count) {
        [_bufArray removeObjectAtIndex:0];
    }
    [_audioLock unlock];
    return d;
}

@end
