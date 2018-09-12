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

@interface ViewController () {
    dispatch_queue_t _playAudioQueue;
}

@property (nonatomic, strong) AQRecorder *recorder;
@property (nonatomic, strong) AQPlayer *player;
@property (nonatomic, strong) UIButton *startOrStopRecordBtn;
@property (nonatomic, strong) UIButton *startOrStopPlayBtn;
@property (nonatomic, strong) NSString *filePath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setupViews];
    _playAudioQueue = dispatch_queue_create("top.jengeo.app.AudioQueueDemo", DISPATCH_QUEUE_SERIAL);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)_setupViews {
    
    _startOrStopRecordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_startOrStopRecordBtn addTarget:self action:@selector(_startRecordAction) forControlEvents:UIControlEventTouchUpInside];
    [_startOrStopRecordBtn setTitle:@"开始录制" forState:UIControlStateNormal];
    [_startOrStopRecordBtn setTitle:@"停止录制" forState:UIControlStateSelected];
    [_startOrStopRecordBtn setTitle:@"已停止录制" forState:UIControlStateDisabled];
    _startOrStopRecordBtn.frame = CGRectMake(100, 100, 100, 40);
    [_startOrStopRecordBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [_startOrStopRecordBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.view addSubview:_startOrStopRecordBtn];
    
    _startOrStopPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_startOrStopPlayBtn addTarget:self action:@selector(_startPlayAction) forControlEvents:UIControlEventTouchUpInside];
    [_startOrStopPlayBtn setTitle:@"开始播放" forState:UIControlStateNormal];
    [_startOrStopPlayBtn setTitle:@"停止播放" forState:UIControlStateSelected];
    [_startOrStopPlayBtn setTitle:@"已停止播放" forState:UIControlStateDisabled];
    _startOrStopPlayBtn.frame = CGRectMake(100, 160, 100, 40);
    [_startOrStopPlayBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [_startOrStopPlayBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.view addSubview:_startOrStopPlayBtn];
}

- (void)_startRecordAction {
    if (_startOrStopRecordBtn.isSelected) {
        [self.recorder stopRecord];
        _startOrStopRecordBtn.selected = NO;
        [_startOrStopRecordBtn setEnabled:NO];
    }
    else {
        [self.recorder startRecord];
        _startOrStopRecordBtn.selected = YES;
    }
}

- (void)_startPlayAction {
    if (_startOrStopPlayBtn.isSelected) {
        [self.player stopPlay];
        _startOrStopPlayBtn.selected = NO;
        [_startOrStopPlayBtn setEnabled:NO];
    }
    else {
        dispatch_async(_playAudioQueue, ^{
            [self.player startPlay];
        });
        _startOrStopPlayBtn.selected = YES;
    }
}


- (NSString*) filePath {
    if (!_filePath) {
        _filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"123.aiff"];
        //_filePath = [[NSBundle mainBundle] pathForResource:@"test.mp3" ofType:@"mp3"];
    }
    return _filePath;
}

- (AQRecorder *)recorder {
    if (!_recorder) {
        AudioStreamBasicDescription defaultDesc;
        defaultDesc.mFormatID = kAudioFormatLinearPCM;
        defaultDesc.mSampleRate = 16000;
        defaultDesc.mChannelsPerFrame = 1;
        defaultDesc.mBitsPerChannel = 16;
        defaultDesc.mBytesPerPacket = defaultDesc.mChannelsPerFrame * defaultDesc.mBitsPerChannel / 8;
        defaultDesc.mBytesPerFrame = defaultDesc.mBytesPerPacket;
        defaultDesc.mFramesPerPacket = 1;
        defaultDesc.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        _recorder = [[AQRecorder alloc] initWithRecordDataFormat:defaultDesc withFilePath:self.filePath];
    }
    
    return _recorder;
}

- (AQPlayer*)player {
    if (!_player) {
        _player = [[AQPlayer alloc] initWithFilePath:self.filePath];
    }
    return _player;
}

@end
