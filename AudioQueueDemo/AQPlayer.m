//
//  AQPlayer.m
//  AudioQueueDemo
//
//  Created by jajeo on 2018/9/11.
//  Copyright © 2018 JENGEO. All rights reserved.
//

#import "AQPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import "AQ_Header.h"

static const int kNumberBuffers = 3;

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

void outputBufferCallback(
    void *inUserData,
    AudioQueueRef inAQ,
    AudioQueueBufferRef inBuffer){
    
    AQPlayerState *pAqData = inUserData;
    if (pAqData->mIsRunning == 0) {
        return;
    }
    UInt32 numPackets = pAqData->mNumPacketsToRead;
    UInt32 bufferSize = pAqData->bufferByteSize;
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
    else {
        inBuffer->mAudioDataByteSize = bufferSize;
        AudioQueueEnqueueBuffer(pAqData->mQueue,
                                inBuffer,
                                pAqData->mPacketDesc ? numPackets : 0 ,
                                pAqData->mPacketDesc);
        pAqData->mCurrentPacket += numPackets;
    }
}

void playerDeriveBufferSize(
    AudioStreamBasicDescription ASBDesc,
    UInt32 maxPacketSize,
    Float64 seconds,
    UInt32 *outBufferSize,
    UInt32 *outNumPacketsToRead
){
 
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize =  0x4000;
    
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
}

@end

@implementation AQPlayer

- (instancetype)init{
    self = [super init];
    return self;
}

- (instancetype) initWithFilePath: (NSString*)filePath {
    if (self = [super init]) {
        _filePath = filePath;
        [self _doSetup];
    }
    return self;
}

- (void)setFilePath:(NSString *)filePath {
    _filePath = filePath;
    [self _doSetup];
}


- (void)_doSetup {
    NSAssert(_filePath, @"filePath  error: nil");
    _aqData.mIsRunning = true;
    
    [self _setupAudioFileURL];
    [self _setupAudioQueue];
    [self _setupBuffers];
    [self _setupMagicCookie];
    [self _setupAQBuffers];
    [self _setupPlayGain];
}

- (void)_setupAudioFileURL {
    
    const char *filePath = [_filePath UTF8String];
    CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *)filePath, strlen(filePath), false);
    OSStatus result = AudioFileOpenURL(audioFileURL, kAudioFileReadPermission, 0, &_aqData.mAudioFile);
    CFRelease(audioFileURL);
    CheckError(result, "AudioFileOpenURL error.");
    
    UInt32 dataFormatSize = sizeof(_aqData.mDataFormat);
    AudioFileGetProperty(_aqData.mAudioFile, kAudioFilePropertyDataFormat, &dataFormatSize, &_aqData.mDataFormat);
}

- (void)_setupAudioQueue {
    AudioQueueNewOutput(&_aqData.mDataFormat, outputBufferCallback, &_aqData, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &_aqData.mQueue);
}

- (void)_setupBuffers {
    //Setting playback audio queue buffer size and number of packets to read
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof(maxPacketSize);
    
    AudioFileGetProperty(_aqData.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &propertySize, &maxPacketSize);
    playerDeriveBufferSize(_aqData.mDataFormat, maxPacketSize, 0.5, &_aqData.bufferByteSize, &_aqData.mNumPacketsToRead);
    
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
    UInt32 cookieSize = sizeof(UInt32);
    
    OSStatus couldNotGetproperty = AudioFileGetPropertyInfo(_aqData.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize, NULL);
    //CheckError(couldNotGetproperty, "AudioFileGetPropertyInfo error");
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
        outputBufferCallback(&_aqData, _aqData.mQueue, _aqData.mBuffers[i]);
    }
}

- (void)_setupPlayGain {
    Float32 gain = 1.0;
    
    AudioQueueSetParameter(_aqData.mQueue, kAudioQueueParam_Volume, gain);
}

- (void) startPlay {
    _aqData.mIsRunning = true;
    
    OSStatus status = AudioQueueStart(_aqData.mQueue, NULL);
    CheckError(status, "AudioQueueStart error");
    
    do {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
    }while (_aqData.mIsRunning);
    
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);
}

- (void) stopPlay {
    AudioQueueStop(_aqData.mQueue, true);
    
    AudioFileClose(_aqData.mAudioFile);
    free(_aqData.mPacketDesc);
}

@end
