//
//  TTSViewController.m
//  MSCDemo
//
//  Created by iflytek on 13-6-6.
//  Copyright (c) 2013年 iflytek. All rights reserved.
//

#import "TTSViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioSession.h>
#import "iflyMSC/IFlySpeechConstant.h"
#import "iflyMSC/IFlySpeechUtility.h"
#import "iflyMSC/IFlySpeechSynthesizer.h"
#import "iflyMSC/IFlyResourceUtil.h"
#import "Definition.h"
#import "PopupView.h"
#import "AlertView.h"
#import "PcmPlayer.h"

@implementation TTSViewController
{
    PcmPlayer *ttsPlayer;
}

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    //单例模式
    _iFlySpeechSynthesizer = [IFlySpeechSynthesizer sharedInstance];
    _iFlySpeechSynthesizer.delegate = self;
    
    //设置发音人
    [_iFlySpeechSynthesizer setParameter:@"xiaoyan" forKey:[IFlySpeechConstant VOICE_NAME]];
    
    //可以选择的其他设置项
    [self optionalSetting];
    
    self.cancelAlertView =  [[AlertView alloc]initWithFrame:CGRectMake(100, 300, 0, 0)];
    self.bufferAlertView =  [[AlertView alloc]initWithFrame:CGRectMake(100, 300, 0, 0)];
    
    ttsPlayer=[[PcmPlayer alloc]init];
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

-(void) volumeButtonDidClick:(NSNotification *)aNotification
{
    NSLog(@"volumeButtonDidClick");
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeButtonDidClick:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    //adjust the UI for iOS 7
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ( IOS7_OR_LATER )
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
        self.navigationController.navigationBar.translucent = NO;
    }
#endif
    
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[UIView alloc] initWithFrame:frame];
    mainView.backgroundColor = [UIColor whiteColor];
    if (!self) {
        return;
    }
    self.view = mainView;
    self.title = @"语音合成";
    self.view.backgroundColor = [UIColor whiteColor];
    int height;
    height = self.view.frame.size.height - ButtonHeight*3 - Margin*6-NavigationBarHeight-3;
    UITextView * textView;
    textView = [[UITextView alloc] initWithFrame:
                CGRectMake(Margin*2, Margin*2, self.view.frame.size.width-Margin*4, height)];
    [self.view addSubview:textView];
    self.toBeSynthersedTextView = textView;
    textView.layer.cornerRadius = 8;
    textView.layer.borderWidth = 1;
    textView.font = [UIFont systemFontOfSize:17.0f];
    
    textView.text = @"       科大讯飞作为中国最大的智能语音技术提供商，在智能语音技术领域有着长期的研究积累、\
    并在中文语音合成、语音识别、口语评测等多项技术上拥有国际领先的成果。科大讯飞是我国唯一以语音技术为产业化方\
    向的“国家863计划成果产业化基地”、“国家规划布局内重点软件企业”、“国家火炬计划重点高新技术企业”、\
    “国家高技术产业化示范工程”，并被信息产业部确定为中文语音交互技术标准工作组组长单位，\
    牵头制定中文语音技术标准。2003年，科大讯飞获迄今中国语音产业唯一的“国家科技进步奖（二等）”，\
    2005年获中国信息产业自主创新最高荣誉“信息产业重大技术发明奖”。2006年至2009年，\
    连续四届英文语音合成国际大赛（Blizzard Challenge ）荣获第一名。2008年获国际说话人识别评测大赛\
    （美国国家标准技术研究院—NIST 2008）桂冠，2009年获得国际语种识别评测大赛（NIST 2009）高难度混淆方言\
    测试指标冠军、通用测试指标亚军";
    
    
    textView.textAlignment = IFLY_ALIGN_CENTER;
    self.textViewHeight = _toBeSynthersedTextView.frame.size.height;
    //_toBeSynthersedTextView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    //键盘
    UIBarButtonItem *spaceBtnItem= [[ UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem * hideBtnItem = [[UIBarButtonItem alloc] initWithTitle:@"隐藏" style:UIBarButtonItemStylePlain target:self action:@selector(onKeyBoardDown:)];
    UIToolbar * toolbar = [[ UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.barStyle = UIBarStyleBlackTranslucent;
    NSArray * array = [NSArray arrayWithObjects:spaceBtnItem,hideBtnItem, nil];
    [toolbar setItems:array];
    textView.inputAccessoryView = toolbar;
    //[_toBeSynthersedTextView sizeToFit];
    
    //开始合成
    UIButton*  startBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [startBtn setTitle:@"开始合成" forState:UIControlStateNormal];
    int startBtnTop;
    startBtnTop = _toBeSynthersedTextView.frame.size.height + _toBeSynthersedTextView.frame.origin.y + Margin;
    startBtn.frame = CGRectMake(Padding, startBtnTop, (self.view.frame.size.width-Padding*3)/2, ButtonHeight);
    [self.view addSubview:startBtn];
    [startBtn addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchUpInside];
    self.startBtn =startBtn;
    
    //取消
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    cancelBtn.frame = CGRectMake(startBtn.frame.origin.x+ Padding +  startBtn.frame.size.width, startBtn.frame.origin.y, startBtn.frame.size.width ,startBtn.frame.size.height);
    [self.view addSubview: cancelBtn];
    [cancelBtn addTarget:self action:@selector(onCancel:) forControlEvents:UIControlEventTouchUpInside];
    cancelBtn.enabled = NO;
    self.cancelBtn = cancelBtn;
    
    //暂停播放
    UIButton *pauseBtn= [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [pauseBtn setTitle:@"暂停播放" forState:UIControlStateNormal];
    pauseBtn.frame = CGRectMake(Padding, startBtn.frame.origin.y + startBtn.frame.size.height + Margin, (self.view.frame.size.width-Padding*3)/2, ButtonHeight);
    [self.view addSubview:pauseBtn];
    [pauseBtn addTarget:self action:@selector(onPause:) forControlEvents:UIControlEventTouchUpInside];
    pauseBtn.enabled = NO;
    self.pauseBtn = pauseBtn;
    
    //恢复播放
    UIButton *resumeBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [resumeBtn setTitle:@"继续播放" forState:UIControlStateNormal];
    resumeBtn.frame = CGRectMake(pauseBtn.frame.origin.x+ Padding + pauseBtn.frame.size.width, pauseBtn.frame.origin.y, pauseBtn.frame.size.width, pauseBtn.frame.size.height);
    [self.view addSubview:resumeBtn];
    [resumeBtn addTarget:self action:@selector(onResume:) forControlEvents:UIControlEventTouchUpInside];
    resumeBtn.enabled = NO;
    self.resumeBtn = resumeBtn;
    
    
    UIButton *synthesizeToUriBtn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [synthesizeToUriBtn setTitle:@"合成后播放" forState:UIControlStateNormal];
    synthesizeToUriBtn.frame = CGRectMake(pauseBtn.frame.origin.x,pauseBtn.frame.origin.y+pauseBtn.frame.size.height+Margin,pauseBtn.frame.size.width*2+Padding,pauseBtn.frame.size.height);
    [synthesizeToUriBtn addTarget:self action:@selector(onSynthesizeToUri:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:synthesizeToUriBtn];
    self.synthesizeBtn=synthesizeToUriBtn;
    
    self.popUpView = [[PopupView alloc]initWithFrame:CGRectMake(100, 300, 0, 0)];
    _popUpView.ParentView = self.view;
}

/*
 * @隐藏键盘
 */
-(void)onKeyBoardDown:(id) sender
{
    [_toBeSynthersedTextView resignFirstResponder];
}

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad
 {
 [super viewDidLoad];
 }
 */

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL) shouldAutorotate
{
    return NO;
}


-(void)keyboardWillShow:(NSNotification *)aNotification {
    [self setViewSize:YES Notification:aNotification];
}

-(void)keyboardWillHide :(NSNotification *)aNotification{
    [self setViewSize:NO Notification:aNotification ];
}


//method to change the size of view whenever the keyboard is shown/dismissed
-(void)setViewSize:(BOOL)show Notification:(NSNotification*) notification
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    //获取键盘的高度
    NSDictionary *userInfo = [notification userInfo];
    int height = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    CGRect rect = _toBeSynthersedTextView.frame;
    if (show) {
        rect.size.height = self.view.frame.size.height - height- Margin*4;
    }
    else
    {
        rect.size.height = _textViewHeight;
    }
    _toBeSynthersedTextView.frame = rect;
    
    [UIView commitAnimations];
}


- (void)viewWillAppear:(BOOL)animated
{
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    //可选设置,设置音频队列的工作模式为播放模式
    [self changeAudioSessionWithPlayback: kAudioSessionCategory_MediaPlayback];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.isViewDidDisappear = true;
    
    //停止合成
    [_iFlySpeechSynthesizer stopSpeaking];
    
    //不再接收回调
    _iFlySpeechSynthesizer.delegate = nil;
    
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    //可选设置
    [self changeAudioSessionWithPlayback: kAudioSessionCategory_PlayAndRecord];
    
    [super viewWillDisappear:animated];
}

- (void)changeAudioSessionWithPlayback:(UInt32) sessionCategory1
{
    //优化蓝牙播放音质，去杂音
    OSStatus error ;
    error = AudioSessionSetProperty (
                                     kAudioSessionProperty_AudioCategory,
                                     sizeof (sessionCategory1),
                                     &sessionCategory1
                                     );
    if (error) {
        NSLog(@"%s| AudioSessionSetProperty kAudioSessionProperty_AudioCategory error",__func__);
        return;
    }
    
    // check the audio route
    UInt32 size = sizeof(CFStringRef);
    CFStringRef route;
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &route);
    
    NSLog(@"route = %@", route);
    
    CFRelease(route);
    // if bluetooth headset connected, should be "HeadsetBT"
    // if not connected, will be "ReceiverAndMicrophone"
}

#pragma mark - Button Handler

/*
 * @选择发音人
 */
- (void) onChooseVoiceNameBtn:(id) sender
{
    NSArray *voiceNames = @[@"小燕", @"小宇", @"小研", @"小琪",@"小峰"];
    
    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:@"选择发音人" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    
    actionSheet.tag = 1;
    
    for (NSString* type in voiceNames) {
        [actionSheet addButtonWithTitle:type];
    }
    
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
    
    [actionSheet showInView:self.view];
}

/*
 * @开始播放
 */
- (void) onStart:(id) sender
{
    if (_state == NotStart)
    {
        self.hasError = NO;
        
        _bufferAlertView.ParentView = self.view;
        
        [_bufferAlertView setText: @"正在缓冲..."];
        
        [_popUpView removeFromSuperview];
        [self.view addSubview:_bufferAlertView];
        
        _cancelBtn.enabled = YES;
        _startBtn.enabled = NO;
        
        self.isCanceled = NO;
        self.synthesizeNotPlay=NO;
        
        [_iFlySpeechSynthesizer startSpeaking:_toBeSynthersedTextView.text];
        if (_iFlySpeechSynthesizer.isSpeaking) {
            _state = Playing;
        }
    }
    
    NSLog(@"onStart end");
}



-(void)onSynthesizeToUri:(id)sender
{
    if (_state == NotStart)
    {
        self.hasError = NO;
        
        _bufferAlertView.ParentView = self.view;
        
        [_bufferAlertView setText: @"正在缓冲..."];
        
        [_popUpView removeFromSuperview];
        [self.view addSubview:_bufferAlertView];
        
        _cancelBtn.enabled = YES;
        _startBtn.enabled = NO;
        
        self.isCanceled = NO;
        self.synthesizeNotPlay=YES;
        
        [_iFlySpeechSynthesizer  synthesize: _toBeSynthersedTextView.text toUri:nil];
        if (_iFlySpeechSynthesizer.isSpeaking)
        {
            _state = Playing;
        }
        
    }
    NSLog(@"onSynthesizeToUri end");
}


/*
 * @ 暂停播放
 */
- (void) onPause:(id) sender
{
    if (_hasError) {
        return;
    }
    
    [_iFlySpeechSynthesizer pauseSpeaking];
    
    _resumeBtn.enabled = YES;
    _pauseBtn.enabled = NO;
}

/*
 * @恢复播放
 */
- (void) onResume:(id) sender
{
    if (_hasError) {
        return;
    }
    
    [_iFlySpeechSynthesizer resumeSpeaking];
    
    _resumeBtn.enabled = NO;
    _pauseBtn.enabled = YES;
}

/*
 * @取消播放
 */
- (void) onCancel:(id) sender
{
    [_iFlySpeechSynthesizer stopSpeaking];
    
    _cancelBtn.enabled = NO;
    _startBtn.enabled = NO;
}

#pragma mark - IFlySpeechSynthesizerDelegate

/**
 * @fn      onSpeakBegin
 * @brief   开始播放
 *
 * @see
 */
- (void) onSpeakBegin
{
    [_bufferAlertView dismissModalView];
    [_cancelAlertView dismissModalView];
    
    self.isCanceled = NO;
    
    [_popUpView setText:@"开始播放"];
    
    [self.view addSubview:_popUpView];
    
    _cancelBtn.enabled = YES;
    _pauseBtn.enabled = YES;
    _resumeBtn.enabled = NO;
}

/**
 * @fn      onBufferProgress
 * @brief   缓冲进度
 *
 * @param   progress            -[out] 缓冲进度
 * @param   msg                 -[out] 附加信息
 * @see
 */
- (void) onBufferProgress:(int) progress message:(NSString *)msg
{
}

/**
 * @fn      onSpeakProgress
 * @brief   播放进度
 *
 * @param   progress            -[out] 播放进度
 * @see
 */
- (void) onSpeakProgress:(int) progress
{
}

/**
 * @fn      onSpeakPaused
 * @brief   暂停播放
 *
 * @see
 */
- (void) onSpeakPaused
{
    [_bufferAlertView dismissModalView];
    [_cancelAlertView dismissModalView];
    
    _state = Paused;
    
    [_popUpView setText:@"播放暂停"];
    
    [self.view addSubview:_popUpView];
}

/**
 * @fn      onSpeakResumed
 * @brief   恢复播放
 *
 * @see
 */
- (void) onSpeakResumed
{
    [_popUpView setText:@"播放继续"];
    [self.view addSubview:_popUpView];
    _state = Playing;
    
}

/**
 * @fn      onCompleted
 * @brief   结束回调
 *
 * @param   error               -[out] 错误对象
 * @see
 */
- (void) onCompleted:(IFlySpeechError *) error
{
    NSLog(@"onCompleted error=%d",[error errorCode]);
    
    NSString *text = nil;
    
    if (self.isCanceled)
    {
        text = @"合成已取消";
    }
    else if (error.errorCode ==0 )
    {
        text = @"合成结束";
    }
    else
    {
        text = [NSString stringWithFormat:@"发生错误：%d %@",error.errorCode,error.errorDesc];
        self.hasError = YES;
        NSLog(@"%@",text);
    }
    
    [_cancelAlertView dismissModalView];
    [_bufferAlertView dismissModalView];
    [_popUpView setText: text];
    [self.view addSubview:_popUpView];
    
    //20019表示上次会话还没有结束错误
    if([error errorCode] != 20019)
    {
        _startBtn.enabled = YES;
        _cancelBtn.enabled = NO;
        _pauseBtn.enabled = NO;
        _resumeBtn.enabled = NO;
        _state = NotStart;
        
    }
    
    if( self.synthesizeNotPlay == YES )    //对于synthesizeToUri接口，这里提供一个合成后，播放的功能
    {
        [ttsPlayer stop];               //首先停止播放器
        NSString *dir=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        dir=[dir stringByAppendingPathComponent:@"synthesizeToUri.pcm"];   //找到synthesizeToUri默认的保存文件路径 XXX/lib/caches/syntehsizeToUri.pcm
        NSLog(@"dir is %@",dir);
        [ttsPlayer setAudioData:dir];   //设置播放器的音频本地路径
        [ttsPlayer play];               //播放器开始播放音频
        
    }
    
    //循环合成,注意waitUntilDone需要为NO，因为一次完整的合成会话实在本回调完全结束才终止的
    //    [self performSelectorOnMainThread:@selector(onStart:) withObject:nil waitUntilDone:NO];
}


/**
 * @fn      onSpeakCancel
 * @brief   正在取消
 *
 * @see
 */
- (void) onSpeakCancel
{
    if (_isViewDidDisappear) {
        return;
    }
    
    self.isCanceled = YES;
    
    [_bufferAlertView dismissModalView];
    
    _cancelAlertView.ParentView = self.view;
    
    [_cancelAlertView setText: @"正在取消..."];
    
    [_popUpView removeFromSuperview];
    [self.view addSubview:_cancelAlertView];
}


#pragma mark Set Engine UIActionSheetDelegate

/**
 此方法为一些demo中没有用到的设置，可以根据需要进行选择
 */
-(void) optionalSetting
{
    // 可以自定义音频队列的配置（可选)，例如以下是配置连接非A2DP蓝牙耳机的代码
    //注意：
    //1. iOS 6.0 以上有效，6.0以下按类似方法配置
    //2. 如果仅仅使用语音合成TTS，并配置AVAudioSessionCategoryPlayAndRecord，可能会被拒绝上线appstore
    //    AVAudioSession * avSession = [AVAudioSession sharedInstance];
    //    NSError * setCategoryError;
    //    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0f) {
    //        [avSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&setCategoryError];
    //    }
    
    /*
     // 设置语音合成的参数【可选】
     
     //合成的语速,取值范围 0~100
     [_iFlySpeechSynthesizer setParameter:@"50" forKey:[IFlySpeechConstant SPEED]];
     
     //合成的音量;取值范围 0~100
     [_iFlySpeechSynthesizer setParameter:@"50" forKey:[IFlySpeechConstant VOLUME]];
     
     //发音人,默认为”xiaoyan”;可以设置的参数列表可参考个 性化发音人列表;
     [_iFlySpeechSynthesizer setParameter:@"xiaoyan" forKey:[IFlySpeechConstant VOICE_NAME]];
     
     //音频采样率,目前支持的采样率有 16000 和 8000;
     [_iFlySpeechSynthesizer setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
     
     //设置是否返回事件
     [_iFlySpeechSynthesizer setParameter:@"1" forKey:@"tts_data_notify"];
     
     //设置音频保存，如果不需要则指定为nil
     [_iFlySpeechSynthesizer setParameter:@"tts.pcm" forKey:[IFlySpeechConstant TTS_AUDIO_PATH]];
     
     */
    
    //    [_iFlySpeechSynthesizer setParameter:@"vixx" forKey:[IFlySpeechConstant VOICE_NAME]];
}

@end
