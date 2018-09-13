//
//  AQPlayer.h
//  AudioQueueDemo
//
//  Created by jajeo on 2018/9/11.
//  Copyright © 2018 JENGEO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol AQPlayerDelegate<NSObject>

- (void)playWithAudioBuffer: (AudioQueueBufferRef)buffer;

@end


@interface AQPlayer : NSObject

@property (nonatomic, weak) id<AQPlayerDelegate> delegate;

/**
 实例方法

 @param filePath 播放文件路径
 @return player实例
 */

- (instancetype) initWithFilePath: (NSString*)filePath;


/**
 实例方法

 @param streamBasicDesc 播放文件格式
 @return player实例
 */
- (instancetype) initWithDataFormat: (AudioStreamBasicDescription)streamBasicDesc;

/**
 开始播放
 */
- (void) startPlay;

/**
 结束播放
 */
- (void) stopPlay;

@end
