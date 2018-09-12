//
//  AQRecorder.m
//  AudioQueueDemo
//
//  Created by jajeo on 2018/9/11.
//  Copyright © 2018 JENGEO. All rights reserved.
//

#import "AQRecorder.h"
#import "AQ_Header.h"
#import <AVFoundation/AVFoundation.h>

static const int kNumberBuffers = 3;

typedef struct AQRecorderState {
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[kNumberBuffers];
    AudioFileID mAudioFile;
    UInt32 bufferByteSize;
    SInt64 mCurrentPacket;
    bool mIsRunning;
} AQRecorderState;

void deriveBufferSize(
                      AudioQueueRef audioQueue,
                      AudioStreamBasicDescription ASBDDescription,
                      Float64 seconds,
                      UInt32 *outBufferSize
                      ) {
    
    
    static const int maxBufferSize = 0x50000;
    
    int maxPacketSize = ASBDDescription.mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(
                              audioQueue,
                              kAudioQueueProperty_MaximumOutputPacketSize,
                              &maxPacketSize,
                              &maxVBRPacketSize);
    }
    Float64 numBytesForTime = ASBDDescription.mSampleRate * maxPacketSize *seconds;
    *outBufferSize = (UInt32)(numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize );
}

OSStatus setMagicCookieForFile(
                               AudioQueueRef inQueue,
                               AudioFileID inFile
                               )  {
    
    OSStatus result = noErr;
    UInt32 cookieSize;
    
    if (AudioQueueGetPropertySize(inQueue, kAudioQueueProperty_MagicCookie, &cookieSize) == noErr) {
        char* magicCookie = (char*)malloc(cookieSize);
        if (AudioQueueGetProperty(inQueue, kAudioQueueProperty_MagicCookie, magicCookie, &cookieSize) == noErr) {
            result = AudioFileSetProperty(inFile, kAudioFilePropertyMagicCookieData, cookieSize, magicCookie);
        }
        free(magicCookie);
    }
    
    CheckError(result, "setMagicCookieForFile error");
    return result;
    
}

void audioInputBufferCallback(
                                     void * __nullable               inUserData,
                                     AudioQueueRef                   inAQ,
                                     AudioQueueBufferRef             inBuffer,
                                     const AudioTimeStamp *          inStartTime,
                                     UInt32                          inNumberPacketDescriptions,
                                     const AudioStreamPacketDescription * __nullable inPacketDescs) {
    
    struct AQRecorderState *pAqData = inUserData;
    if (inNumberPacketDescriptions == 0 && pAqData->mDataFormat.mBytesPerFrame != 0) {
        inNumberPacketDescriptions = inBuffer->mAudioDataByteSize/pAqData->mDataFormat.mBytesPerPacket;
    }
    
    NSLog(@"---------%d", inBuffer->mAudioDataByteSize);
    
    //Writing an audio queue buffer to disk
    if(AudioFileWritePackets(
                             pAqData->mAudioFile,
                             false,
                             inBuffer->mAudioDataByteSize,
                             inPacketDescs,
                             pAqData->mCurrentPacket,
                             &inNumberPacketDescriptions,
                             inBuffer->mAudioData) == noErr) {
        pAqData->mCurrentPacket += inNumberPacketDescriptions;
    }
    
    if (pAqData->mIsRunning == 0) {
        return;
    }
    //Enqueuing an audio queue buffer after writing to disk
    AudioQueueEnqueueBuffer(pAqData->mQueue,
                            inBuffer,
                            0,
                            NULL);
}

@interface AQRecorder()

@property (nonatomic, assign)AQRecorderState aqData;
@property (nonatomic, copy) NSString *recordFileDestPath;
@property (nonatomic, assign) AudioStreamBasicDescription streamBasicDesc;

@end

@implementation AQRecorder

- (instancetype) init {
    if (self = [super init]) {
    }
    return self;
}

- (instancetype) initWithRecordDataFormat: (AudioStreamBasicDescription)streamBasicDesc withFilePath:(NSString *)filePath {
    if (self = [super init]) {
        _streamBasicDesc = streamBasicDesc;
        _recordFileDestPath = filePath;
        [self _doSetup];
    }
    
    return self;
}

- (void)setStreamBasicDesc:(AudioStreamBasicDescription)streamBasicDesc withFilePath: (NSString*)filePath {
    _streamBasicDesc = streamBasicDesc;
    _recordFileDestPath = filePath;
    [self _doSetup];
}

- (void) _doSetup {
    [self _setupNewInput];
    [self _setupOutputAudioFile];
    [self _setupMagicCookies];
    [self _setupAQBuffer];
}

- (void) _setupNewInput {
    NSAssert(_recordFileDestPath, @"_recordFileDestPath nil");
    _aqData.mDataFormat = _streamBasicDesc;
    OSStatus status = AudioQueueNewInput(&_aqData.mDataFormat, audioInputBufferCallback, &_aqData, NULL, kCFRunLoopCommonModes, 0, &_aqData.mQueue);
    CheckError(status, "AudioQueueNewInput error");
}

- (void)_setupOutputAudioFile {
    const char *cFilePath = _recordFileDestPath.UTF8String;
    CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(NULL, (const uint8_t *)cFilePath, strlen(cFilePath), false);
    AudioFileTypeID fileType = kAudioFileAIFFType;
    OSStatus status = AudioFileCreateWithURL(audioFileURL,
                           fileType,
                           &_aqData.mDataFormat,
                           kAudioFileFlags_EraseFile,
                           &_aqData.mAudioFile);
    CheckError(status, "AudioFileCreateWithURL error");
}

- (void)_setupMagicCookies {
    setMagicCookieForFile(_aqData.mQueue, _aqData.mAudioFile);
}


/**
 默认20ms数据，采样率16k单通道双字节pcm格式每帧大概640byte数据（小于或等于）
 */
- (void) _setupAQBuffer {
    deriveBufferSize(_aqData.mQueue,
                     _aqData.mDataFormat,
                     0.02,
                     &_aqData.bufferByteSize);
    for (int i = 0; i < kNumberBuffers; ++i) {
        OSStatus status = AudioQueueAllocateBuffer(_aqData.mQueue, _aqData.bufferByteSize, &_aqData.mBuffers[i]);
        CheckError(status, "AudioQueueAllocateBuffer error");
        status = AudioQueueEnqueueBuffer(_aqData.mQueue, _aqData.mBuffers[i], 0, NULL);
        CheckError(status, "AudioQueueEnqueueBuffer error");
    }
}


- (void)startRecord {
    _aqData.mCurrentPacket = 0;
    _aqData.mIsRunning = true;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (!session) {
        NSLog(@"sharedInstance error");
    }
    else {
        NSError *error = nil;
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
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
}

- (void)stopRecord {
    AudioQueueStop(_aqData.mQueue, true);
    
    _aqData.mIsRunning = false;
    
    AudioQueueDispose(_aqData.mQueue, true);
    AudioFileClose(_aqData.mAudioFile);
}

@end
