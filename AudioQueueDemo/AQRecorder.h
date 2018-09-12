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

/**
 构造方法

 @param streamBasicDesc 录制音频的参数设置（采样率，声道数，声道位数等）
 @param filePath  目标文件路径
 @return 实例
 */
- (instancetype) initWithRecordDataFormat: (AudioStreamBasicDescription)streamBasicDesc withFilePath:(NSString *)filePath;

/**
 音频的参数设置

 @param streamBasicDesc 录制音频的参数设置（采样率，声道数，声道位数等）
 @param filePath 目标文件路径
 */
- (void)setStreamBasicDesc:(AudioStreamBasicDescription)streamBasicDesc withFilePath: (NSString*)filePath;


/**
 开始录制
 */
- (void)startRecord;

/**
 结束录制
 */
- (void)stopRecord;




@end
