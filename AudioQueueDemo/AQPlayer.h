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

- (instancetype) initWithFilePath: (NSString*)filePath;

- (void) startPlay;
- (void) stopPlay;

@end
