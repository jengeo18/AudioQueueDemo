//
//  AQPlayer.m
//  AudioQueueDemo
//
//  Created by jajeo on 2018/9/11.
//  Copyright © 2018 JENGEO. All rights reserved.
//

#import "AQPlayer.h"
#import "AQ_Header.h"
#import <AVFoundation/AVFoundation.h>

static const int kNumberBuffers = 3;

typedef enum PlayWithType {
    PlayWithFile,  //文件播放
    PlayWithMemory //内存或从流中读取的Data
} PlayWithType;

typedef struct AQPlayerState {
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[kNumberBuffers];
    AudioFileID mAudioFile;
    UInt32 bufferByteSize;
    SInt64 mCurrentPacket;
    UInt32 mNumPacketsToRead;
    AudioStreamPacketDescription *mPacketDesc;
    bool mIsRunning;
} AQPlayerState;


void playerDeriveBufferSize(
    AudioStreamBasicDescription ASBDesc,
    UInt32 maxPacketSize,
    Float64 seconds,
    UInt32 *outBufferSize,
    UInt32 *outNumPacketsToRead
){
 
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize =  0x200;
    
    if (ASBDesc.mFramesPerPacket != 0) {
        Float64 numPacketsForTime = ASBDesc.mSampleRate / ASBDesc.mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        *outBufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize && *outBufferSize > maxPacketSize) {
        *outBufferSize = maxBufferSize;
    }
    else {
        if (*outBufferSize < minBufferSize) {
            *outBufferSize = minBufferSize;
        }
    }
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;
}

@interface AQPlayer() {
    AQPlayerState _aqData;
    NSLock *_aqLock;
    short _curBufferNo;
}

//播放文件路径
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign)AudioStreamBasicDescription streamBasicDesc;
@property (nonatomic, assign) PlayWithType playWith;

@end

@implementation AQPlayer

- (instancetype)init{
    AudioStreamBasicDescription defaultDesc;
    defaultDesc.mFormatID = kAudioFormatLinearPCM;
    defaultDesc.mSampleRate = 16000;
    defaultDesc.mChannelsPerFrame = 1;
    defaultDesc.mBitsPerChannel = 16;
    defaultDesc.mFramesPerPacket = 1;
    defaultDesc.mBytesPerFrame = defaultDesc.mChannelsPerFrame * defaultDesc.mBitsPerChannel / 8;
    defaultDesc.mBytesPerPacket = defaultDesc.mBytesPerFrame * defaultDesc.mFramesPerPacket;
    defaultDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved | kAudioFormatFlagIsPacked;
    return [self initWithDataFormat: defaultDesc];
}

- (instancetype) initWithFilePath: (NSString*)filePath {
    if (self = [super init]) {
        _filePath = filePath;
        [self _doSetup];
    }
    return self;
}

- (instancetype) initWithDataFormat: (AudioStreamBasicDescription)streamBasicDesc {
    if (self = [super init]) {
        _streamBasicDesc = streamBasicDesc;
        [self _doSetup];
    }
    
    return self;
}


- (void)_doSetup {

    _aqData.mIsRunning = true;
    
    [self _setupAudioFileURL];
    [self _setupAudioQueue];
    [self _setupBuffers];
    [self _setupMagicCookie];
    [self _setupAQBuffers];
    [self _setupPlayGain];
    [self _initAudioLock];
}

- (void)_setupAudioFileURL {
    if (!_filePath ||! _filePath.length) {
        self.playWith = PlayWithMemory;
        _aqData.mDataFormat = _streamBasicDesc;
        return;
    }
    
    const char *filePath = [_filePath UTF8String];
    CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *)filePath, strlen(filePath), false);
    OSStatus result = AudioFileOpenURL(audioFileURL, kAudioFileReadPermission, 0, &_aqData.mAudioFile);
    CFRelease(audioFileURL);
    CheckError(result, "AudioFileOpenURL error.");
    
    UInt32 dataFormatSize = sizeof(_aqData.mDataFormat);
    AudioFileGetProperty(_aqData.mAudioFile, kAudioFilePropertyDataFormat, &dataFormatSize, &_aqData.mDataFormat);
}

- (void)_setupAudioQueue {
    AudioQueueNewOutput(&_aqData.mDataFormat, outputBufferCallback, (__bridge void*)self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &_aqData.mQueue);
}

- (void)_setupBuffers {
    
        //Setting playback audio queue buffer size and number of packets to read
        UInt32 maxPacketSize;
        UInt32 propertySize = sizeof(maxPacketSize);
        if (self.playWith == PlayWithFile) {
            AudioFileGetProperty(_aqData.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &propertySize, &maxPacketSize);
        }
        else {
            maxPacketSize = 2;
        }
    
        playerDeriveBufferSize(_aqData.mDataFormat, maxPacketSize, 0.02, &_aqData.bufferByteSize, &_aqData.mNumPacketsToRead);
        
        //Allocating memory for a packet descriptions array
        bool isFormatVBR = (
            _aqData.mDataFormat.mBytesPerPacket == 0 ||
                            _aqData.mDataFormat.mFramesPerPacket == 0
                            );
        if (isFormatVBR) {
            _aqData.mPacketDesc = (AudioStreamPacketDescription*)malloc(_aqData.mNumPacketsToRead * sizeof(AudioStreamPacketDescription));
        }
        else {
            _aqData.mPacketDesc = NULL;
        }
}

- (void)_setupMagicCookie {
    if (self.playWith == PlayWithMemory) {
        return;
    }
    UInt32 cookieSize = sizeof(UInt32);
    
    AudioFileGetPropertyInfo(_aqData.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize, NULL);
    if (cookieSize) {
        char* magicCookie = (char*)malloc(cookieSize);
        AudioFileGetProperty(_aqData.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize, magicCookie);
        AudioQueueSetProperty(_aqData.mQueue, kAudioFilePropertyMagicCookieData, magicCookie, cookieSize);
    }
}

- (void)_setupAQBuffers {
    _aqData.mCurrentPacket = 0;
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(_aqData.mQueue, _aqData.bufferByteSize, &_aqData.mBuffers[i]);
        outputBufferCallback((__bridge void*)self, _aqData.mQueue, _aqData.mBuffers[i]);
    }
}

- (void)_setupPlayGain {
    Float32 gain = 1.0;
    
    AudioQueueSetParameter(_aqData.mQueue, kAudioQueueParam_Volume, gain);
}

- (void)_initAudioLock {
    _aqLock = [[NSLock alloc] init];
    _curBufferNo = 0;
}

- (void) startPlay {
    _aqData.mIsRunning = true;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (!session) {
        NSLog(@"sharedInstance error");
    }
    else {
        NSError *error = nil;
        [session setCategory:AVAudioSessionCategoryPlayback error:&error];
        if (error) {
            NSLog(@"setCategoryError: %@", error.localizedDescription);
        }
        else {
            [session setActive:YES error:&error];
            if (error) {
                NSLog(@"setActive: %@", error.localizedDescription);
            }
        }
    }
    
    
    OSStatus status = AudioQueueStart(_aqData.mQueue, NULL);
    CheckError(status, "AudioQueueStart error");
    
    do {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.65, false);
        if (self.playWith == PlayWithMemory) {
            [_aqLock lock];
            if (self.playWith == PlayWithMemory) {
                for( int i = 0; i < kNumberBuffers; i++) {
                    outputBufferCallback((__bridge void*)self, _aqData.mQueue, _aqData.mBuffers[i++]);
                    if (_curBufferNo >= kNumberBuffers) {
                        _curBufferNo = 0;
                    }
                }
            }
            [_aqLock unlock];
        }
    }while (_aqData.mIsRunning);
    
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);
}

- (void) stopPlay {
    _aqData.mIsRunning = NO;
    
    AudioQueueStop(_aqData.mQueue, true);
    if (self.playWith == PlayWithFile) {
        AudioFileClose(_aqData.mAudioFile);
    }
    if (_aqData.mPacketDesc) {
        free(_aqData.mPacketDesc);
    }
}

void outputBufferCallback(
                          void *inUserData,
                          AudioQueueRef inAQ,
                          AudioQueueBufferRef inBuffer){
    
    AQPlayer *player = (__bridge AQPlayer *)(inUserData);
    AQPlayerState *pAqData = &(player->_aqData);
    if (pAqData->mIsRunning == 0) {
        return;
    }
    UInt32 numPackets = pAqData->mNumPacketsToRead;
    UInt32 bufferSize = pAqData->bufferByteSize;
    
    if (player.playWith == PlayWithMemory) {
        if (player.delegate && [player.delegate respondsToSelector:@selector(playWithAudioBuffer:)]) {
            [player.delegate playWithAudioBuffer: inBuffer];
        }
    }
    else {
        AudioFileReadPacketData(pAqData->mAudioFile,
                            false,
                            &bufferSize,
                            pAqData->mPacketDesc,
                            pAqData->mCurrentPacket,
                            &numPackets,
                            inBuffer->mAudioData);
        if (numPackets == 0) {
            AudioQueueStop(pAqData->mQueue, false);
            pAqData->mIsRunning = false;
        }
        inBuffer->mAudioDataByteSize = bufferSize;
    }
    if (inBuffer->mAudioDataByteSize == 0) {
        return;
    }
    
    AudioQueueEnqueueBuffer(pAqData->mQueue,
                            inBuffer,
                            pAqData->mPacketDesc ? numPackets : 0,
                            pAqData->mPacketDesc);
    pAqData->mCurrentPacket += numPackets;
}


@end
