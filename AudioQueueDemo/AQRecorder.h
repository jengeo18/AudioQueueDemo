//
//  AQRecorder.h
//  AudioQueueDemo
//
//  Created by jajeo on 2018/9/11.
//  Copyright © 2018 JENGEO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


@protocol AQRecorderDelegate<NSObject>

- (void)recordAudioData: (NSData*)data;

@end

@interface AQRecorder : NSObject

@property (nonatomic, weak) id<AQRecorderDelegate> delegate;

/**
 构造方法

 @param streamBasicDesc 录制音频的参数设置（采样率，声道数，声道位数等）
 @return 实例
 */
- (instancetype) initWithRecordDataFormat: (AudioStreamBasicDescription)streamBasicDesc;


/**
 构造方法

 @param filePath  录制到文件路径
 @return recorder实例
 */
- (instancetype) initWithFilePath: (NSString*)filePath;


/**
 开始录制
 */
- (void)startRecord;

/**
 结束录制
 */
- (void)stopRecord;



@end
