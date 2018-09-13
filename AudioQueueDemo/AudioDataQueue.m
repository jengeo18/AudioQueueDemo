//
//  AudioDataQueue.m
//  SmartClass
//
//  Created by jajeo on 2018/9/5.
//  Copyright © 2018 Hber. All rights reserved.
//

#import "AudioDataQueue.h"

@implementation AudioDataQueue {
    NSMutableData *_buffer;
    long _capacitySize;
}

- (instancetype)initWithCapacitySize:(long)size {
    if (self = [super init]) {
        _buffer = [[NSMutableData alloc] init];
        _capacitySize = size;
    }
    return self;
}

- (instancetype)init {
    long capacitySize = 1024 * 1024 * 2;
    return [self initWithCapacitySize:capacitySize];
}

- (void)pushData: (NSData*)data {
    long curLen = _buffer.length;
    long addLen = data.length;
    if (curLen + addLen >= _capacitySize) {
        //删除最先加入长度为addLen的字节,然后将新的加入到最后面
        const void *dataBytes = _buffer.bytes;
        NSMutableData *tempData = [[NSMutableData alloc] initWithBytes:dataBytes + addLen length: curLen - addLen];
        [tempData appendData:data];
        _buffer = tempData;
    }
    else {
        [_buffer appendData:data];
    }
}

- (NSData*)popDataLength:(NSUInteger)length {
    if (_buffer.length < length) {
        return nil;
    }
    const void *dataBytes = _buffer.bytes;
    NSData *data = [[NSData alloc] initWithBytes:dataBytes length:length];
    _buffer = [[NSData alloc] initWithBytes:dataBytes + length length:_buffer.length - length].mutableCopy;
    return data;
}

@end
