//
//  AQDataCache.h
//  AudioQueueDemo
//
//  Created by jajeo on 2018/9/13.
//  Copyright © 2018 JENGEO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AQDataCache : NSObject

- (void)pushData: (NSData*)data;
- (NSData*)popData;

@end
