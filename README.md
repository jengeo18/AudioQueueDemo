# AudioQueueDemo
 
 - 使用AudioQueue录制音频文件
 
 ```
 _recorder = [[AQRecorder alloc] initWithFilePath:defaultFilePath];
 [_recorder startRecord];
 
 ```

 - 使用AudioQueue录制播放文件
 
 ```
 _playAudioQueue = dispatch_queue_create("top.jengeo.app.AudioQueueDemo.AudioPlay", DISPATCH_QUEUE_SERIAL);
 _recorder = [[AQRecorder alloc] initWithFilePath:defaultFilePath];
  dispatch_async(_playAudioQueue, ^{
      [self.player startPlay];
  });
 ```
 
 
 
 
 - 使用AudioQueue录制音频流
 
 ```
  _recorder = [[AQRecorder alloc] init];
  _recorder.delegate = self;
  [_recorder startRecord];
 ```
 
  - 使用AudioQueue播放文件
  
  ```
  _playAudioQueue = dispatch_queue_create("top.jengeo.app.AudioQueueDemo.AudioPlay", DISPATCH_QUEUE_SERIAL);
_player = [[AQPlayer alloc] init];
_player.delegate = self;
 dispatch_async(_playAudioQueue, ^{
     [self.player startPlay];
 });
  ```
  
  
  具体可以参考下代码