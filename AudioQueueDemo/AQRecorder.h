//
//  AQRecorder.h
//  AudioQueueDemo
//
//  Created by jajeo on 2018/9/11.
//  Copyright © 2018 JENGEO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AQRecorder : NSObject

- (instancetype) initWithRecordDataFormat: (AudioStreamBasicDescription)streamBasicDesc withFilePath:(NSString *)filePath;
- (void)setStreamBasicDesc:(AudioStreamBasicDescription)streamBasicDesc withFilePath: (NSString*)filePath;

- (void)startRecord;

- (void)stopRecord;


@end
