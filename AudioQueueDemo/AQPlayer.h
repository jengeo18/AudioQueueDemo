//
//  AQPlayer.h
//  AudioQueueDemo
//
//  Created by jajeo on 2018/9/11.
//  Copyright © 2018 JENGEO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AQPlayer : NSObject

//播放文件路径
@property (nonatomic, copy) NSString *filePath;


/**
 实例方法

 @param filePath 播放文件路径
 @return 实例
 */
- (instancetype) initWithFilePath: (NSString*)filePath;

/**
 开始播放
 */
- (void) startPlay;

/**
 结束播放
 */
- (void) stopPlay;

@end
