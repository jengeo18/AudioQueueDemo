//
//  ViewController.m
//  AudioQueueDemo
//
//  Created by jajeo on 2018/9/11.
//  Copyright © 2018 JENGEO. All rights reserved.
//

#import "ViewController.h"
#import "AQRecorder.h"
#import "AQPlayer.h"
#import "AQ_Header.h"
#import "AQDataCache.h"


@interface ViewController () <AQRecorderDelegate, AQPlayerDelegate>{
    dispatch_queue_t _playAudioQueue;
}

@property (nonatomic, strong) AQRecorder *recorder;
@property (nonatomic, strong) AQPlayer *player;
@property (nonatomic, strong) UIButton *startPCMRecordBtn;
@property (nonatomic, strong) UIButton *startPCMPlayBtn;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) AQDataCache *audioCache;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setupViews];
    [self _setupDatas];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)_setupViews {

    _startPCMRecordBtn = [self _createButtonWithFrame:CGRectMake(100, 100, 150, 40)
                                          normalTitle:@"开始录制PCM"
                                        selectedTitle:@"停止录制PCM"
                                        disabledTitle:@"已停止录制PCM"
                                             selector:@selector(_startRecordPCM)];
     [self.view addSubview:_startPCMRecordBtn];
    
    _startPCMPlayBtn = [self _createButtonWithFrame:CGRectMake(100, 160, 150, 40)
                                        normalTitle:@"开始播放PCM"
                                      selectedTitle:@"停止播放PCM"
                                      disabledTitle:@"已停止播放PCM"
                                           selector:@selector(_startPlayPCM)];
    [self.view addSubview:_startPCMPlayBtn];
}

- (UIButton*)_createButtonWithFrame: (CGRect)frame
                   normalTitle: (NSString*)normalTitle
                 selectedTitle: (NSString*)selectedTitle
                 disabledTitle: (NSString*)disableTitle
                      selector: (SEL)selector {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle: normalTitle forState:UIControlStateNormal];
    [btn setTitle: selectedTitle forState:UIControlStateSelected];
    [btn setTitle: disableTitle forState:UIControlStateDisabled];
    [btn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    return btn;
}


- (void)_setupDatas {
    _playAudioQueue = dispatch_queue_create("top.jengeo.app.AudioQueueDemo.AudioPlay", DISPATCH_QUEUE_SERIAL);
    _audioCache = [[AQDataCache alloc] init];
}

- (void)_startRecordPCM {
    if (_startPCMRecordBtn.isSelected) {
        [self.recorder stopRecord];
        _startPCMRecordBtn.selected = NO;
        [_startPCMRecordBtn setEnabled:NO];
    }
    else {
        [self.recorder startRecord];
        _startPCMRecordBtn.selected = YES;
    }
}

- (void)_startPlayPCM {
    if (_startPCMPlayBtn.isSelected) {
        [self.player stopPlay];
        _startPCMPlayBtn.selected = NO;
        [_startPCMPlayBtn setEnabled:NO];
    }
    else {
        dispatch_async(_playAudioQueue, ^{
            [self.player startPlay];
        });
       
        _startPCMPlayBtn.selected = YES;
    }
}

#pragma mark - getters

- (NSString*) filePath {
    if (!_filePath) {
        _filePath = defaultFilePath;
        //_filePath = [[NSBundle mainBundle] pathForResource:@"test.mp3" ofType:@"mp3"];
    }
    return _filePath;
}

- (AQRecorder *)recorder {
    if (!_recorder) {
        //_recorder = [[AQRecorder alloc] initWithFilePath:defaultFilePath];
        _recorder = [[AQRecorder alloc] init];
        _recorder.delegate = self;
    }
    
    return _recorder;
}

- (AQPlayer*)player {
    if (!_player) {
       //_player = [[AQPlayer alloc] initWithFilePath:defaultFilePath];
        _player = [[AQPlayer alloc] init];
        _player.delegate = self;
    }
    return _player;
}

#pragma mark - AQRecorderDelegate

- (void)recordAudioData: (NSData*)data {
    [_audioCache pushData:data];
}


- (void)playWithAudioBuffer: (AudioQueueBufferRef)buffer {
    NSData *data = [_audioCache popData];
    memset(buffer->mAudioData, 0, buffer->mAudioDataByteSize);
    if (data && data.length ) {
        UInt32 len = (UInt32)data.length;
        buffer->mAudioDataByteSize = len;
        memcpy(buffer->mAudioData, data.bytes, len);
    }
    else {
        buffer->mAudioDataByteSize = 0;
    }
}


@end
