//
//  AudioDataQueue.h
//  SmartClass
//
//  Created by jajeo on 2018/9/5.
//  Copyright © 2018 Hber. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioDataQueue : NSObject

- (instancetype)initWithCapacitySize:(long)size;

- (void)pushData: (NSData*)data;
- (NSData*)popDataLength:(NSUInteger)length;

@end
