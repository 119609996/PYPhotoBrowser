//
//  PYMoviePlayerView.m
//  80-MPMoviePlayerController的简单使用
//
//  Created by 谢培艺 on 16/6/30.
//  Copyright © 2016年 iphone5solo. All rights reserved.
//

#import "PYMoviePlayerView.h"
#import "UIView+PYExtension.h"
#import "PYConst.h"

@interface PYMoviePlayerView ()
/** 中间的播放按钮 */
@property (weak, nonatomic) IBOutlet UIButton *playerButton;
/** 底部的播放\暂停按钮 */
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;
/** 当前时间 */
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
/** 剩余时间 */
@property (weak, nonatomic) IBOutlet UILabel *leftTimeLabel;
/** 关闭 */
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
/** 更多 */
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

/** 视频总时长 */
@property (nonatomic, assign) CGFloat movieDuration;

/** 计时器*/
@property (nonatomic, strong) NSTimer *timer;

/** 滑动块 */
@property (weak, nonatomic) IBOutlet UIButton *sliderButton;
/** 看过的进度view */
@property (weak, nonatomic) IBOutlet UIView *visitedSliderView;
/** 已下载的进度view */
@property (weak, nonatomic) IBOutlet UIView *downloadSliderView;
/** 总长度 */
@property (weak, nonatomic) IBOutlet UIView *totalSliderView;
/** 看过的进度view的宽度约束 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *visitSliderWidth;
/** 滑块的左边距约束 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *silderButtonLeading;

@end

@implementation PYMoviePlayerView

- (void)setup
{
    self.userInteractionEnabled = NO;
    self.sliderButton.py_width = self.sliderButton.py_height = 15;
    self.sliderButton.py_centerX = 0;
    self.sliderButton.py_centerY = self.superview.py_height * 0.5;
    self.sliderButton.layer.cornerRadius = self.sliderButton.py_width * 0.5;
    self.downloadSliderView.layer.cornerRadius = 1.5;
    self.visitedSliderView.layer.cornerRadius = 1.5;
    self.totalSliderView.layer.cornerRadius = 1.5;
    self.autoresizingMask = UIViewAutoresizingNone;
    // 单击手势
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDidClicked:)];
    [self.totalSliderView addGestureRecognizer:tap];
    [self.bottomView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:nil action:nil]];
    // 滑动手势
    UIGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDidSlide:)];
    [self.sliderButton addGestureRecognizer:pan];
}
- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

+ (instancetype)moviePlayerView
{
    PYMoviePlayerView *playerView = [[[NSBundle mainBundle] loadNibNamed:@"PYMoviePlayerView" owner:nil options:0] lastObject];
    [playerView setup];
    return playerView;
}

- (NSTimer *)timer
{
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    }
    return _timer;
}

- (CGFloat)movieDuration
{
    return (NSInteger)(_movieDuration + 0.5);
}

- (IBAction)close:(id)sender {
    
    NSNotification *notification = [[NSNotification alloc] initWithName:PYSmallgImageDidClikedNotification object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
}
- (IBAction)more:(id)sender {
    NSLog(@"更多...");
}

- (IBAction)playOrPause:(UIButton *)sender {
    // 播放或者暂停
    MPMoviePlaybackState playbackState = 0;
    self.playerButton.hidden = self.playOrPauseButton.selected = !self.playOrPauseButton.selected;
    playbackState = self.playerButton.hidden ? MPMoviePlaybackStatePaused : MPMoviePlaybackStatePlaying;
    if ([self.delegate respondsToSelector:@selector(movicePlayerView:didPlaybackStateChanged:)]) {
        [self.delegate movicePlayerView:self didPlaybackStateChanged:playbackState];
    }
}

// 设置代理
- (void)setDelegate:(id<PYMoviePlayerViewDelegate>)delegate
{
    _delegate = delegate;
    
    if (!_delegate){ // 没有代理移除通知
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } else {
        // 有代理再添加通知
        [self addNotification];
    };
}


// 添加通知监控媒体播放控制器状态
-(void)addNotification{
    NSNotificationCenter *notificationCenter=[NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(mediaPlayerPlaybackStateChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.delegate];
    [notificationCenter addObserver:self selector:@selector(mediaPlayerPlaybackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.delegate];
    [notificationCenter addObserver:self selector:@selector(mediaPlayerThumbnailRequestFinished:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:self.delegate];
    [notificationCenter addObserver:self selector:@selector(movieDurationAvailable:) name:MPMovieDurationAvailableNotification object:self.delegate];
    
}

-(void)dealloc{
    //移除所有通知监控
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 单击手势
- (void)tapDidClicked:(UITapGestureRecognizer *)sender {
    
    CGFloat maxX = self.totalSliderView.py_width;
    // 点击了进度条
    // 获取选中的点
    CGPoint point = [sender locationInView:self.totalSliderView];
    
    if (point.x > maxX) {
        point.x = maxX;
    }
    // 滑动滑块
    self.sliderButton.py_centerX = point.x;
    self.visitedSliderView.py_width = self.sliderButton.py_centerX;
    
    // 设置时间
    ((PYMoviePlayerController *)self.delegate).currentPlaybackTime = self.sliderButton.py_centerX / maxX * self.movieDuration;
    // 刷新进程
    [self updateProgress];
}


// 滑动手势
- (void)panDidSlide:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(movicePlayerView:didPlaybackStateChanged:)] && self.playOrPauseButton.isSelected) {
            [self.delegate movicePlayerView:self didPlaybackStateChanged:MPMoviePlaybackStatePlaying];
        }
    }
    // 判断手势状态
    if(sender.state == UIGestureRecognizerStateEnded ||
       sender.state == UIGestureRecognizerStateFailed ||
       sender.state == UIGestureRecognizerStateCancelled) { // 滑动结束\取消\失败
        if ([self.delegate respondsToSelector:@selector(movicePlayerView:didPlaybackStateChanged:)] && self.playOrPauseButton.isSelected) {
            [self.delegate movicePlayerView:self didPlaybackStateChanged:MPMoviePlaybackStatePaused];
        }
    }
    
    CGFloat maxX = self.totalSliderView.py_width;
    // 获取位移
    CGPoint point = [sender translationInView:self.totalSliderView];
    // 复位
    [sender setTranslation:CGPointZero inView:self.totalSliderView];
    
    self.sliderButton.py_centerX += point.x;
    if (self.sliderButton.py_centerX < 0) {
        self.sliderButton.py_centerX = 0;
    }else if (self.sliderButton.py_centerX > maxX){
        self.sliderButton.py_centerX = maxX;
    }
    
    // 滑动滑块
    self.visitedSliderView.py_width = self.sliderButton.center.x;
    
    // 设置时间
    ((PYMoviePlayerController *)self.delegate).currentPlaybackTime = self.sliderButton.py_centerX / maxX * self.movieDuration;
}

// 添加计时器
- (void)addTimer
{
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

// 移除计时器
- (void)removeTimer
{
    // 移除计时器
    [self.timer invalidate];
    self.timer = nil;
}

// 更新进度
- (void)updateProgress
{
    // 如果没有代理 直接返回
    if (!self.delegate) return;
    
    CGFloat currentPlaybackTime = ((PYMoviePlayerController *)self.delegate).currentPlaybackTime;
    NSInteger currentTime = currentPlaybackTime + 0.5;
    currentTime = currentTime > 0 ? currentTime : 0;
    // 当前时间
    NSInteger currentMinute = currentTime / 60;
    NSInteger currentSecond = currentTime % 60;
    // 剩余时间
    NSInteger leftMinute = (self.movieDuration - currentTime) / 60;
    NSInteger leftSecond = ((NSInteger)(self.movieDuration - currentTime)) % 60;
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%zd:%02zd",currentMinute, currentSecond];
    self.leftTimeLabel.text = [NSString stringWithFormat:@"-%zd:%02zd",leftMinute, leftSecond];
    
    
    // 刷新UI
    CGFloat visitSliderW = (currentPlaybackTime / self.movieDuration) * self.totalSliderView.py_width;
    visitSliderW = visitSliderW > 0 ? visitSliderW : 0;
    self.visitSliderWidth.constant = visitSliderW;
    CGFloat sliderButtonL = (currentPlaybackTime / self.movieDuration) * self.totalSliderView.py_width - 6;
    sliderButtonL = sliderButtonL > 0 ? sliderButtonL : 0;
    self.silderButtonLeading.constant = sliderButtonL;
}

// 播放
- (void)play
{
    // 更新进度
    [self updateProgress];
    // 添加计时器
    [self addTimer];
}

// 暂停播放
- (void)pause
{
    // 更新进度
    [self updateProgress];
    self.playerButton.hidden = NO;
    self.playOrPauseButton.selected = NO;
    [self removeTimer];
}
- (void)mediaPlayerPlaybackStateChange:(NSNotification *)noti
{
    PYMoviePlayerController *playerController = (PYMoviePlayerController *)self.delegate;
    if (playerController.playbackState == MPMoviePlaybackStatePlaying) {
        [self play];
        
        self.playOrPauseButton.selected = YES;
        self.playerButton.hidden = YES;
    } else if (playerController.playbackState == MPMoviePlaybackStatePlaying) {
        [self pause];
    }
}

// 播放结束
- (void)mediaPlayerPlaybackFinished:(NSNotification *)noti
{
    self.playOrPauseButton.selected = NO;
    self.playerButton.hidden = NO;
}

// 播放时间已获取
- (void)movieDurationAvailable:(NSNotification *)noti
{
    PYMoviePlayerController *playerController = (PYMoviePlayerController *)self.delegate;
    self.movieDuration = playerController.duration;
    playerController.currentPlaybackTime = 0;
    // 刷新进程
    [self updateProgress];
    self.userInteractionEnabled = YES;
    // 获取封面图
    // 获取当qian的缩略图
    [playerController requestThumbnailImagesAtTimes:@[@(playerController.currentPlaybackTime)] timeOption:MPMovieTimeOptionNearestKeyFrame];
}


// 缩略图请求完成,此方法每次截图成功都会调用一次
-(void)mediaPlayerThumbnailRequestFinished:(NSNotification *)notification{
    self.movieImage = notification.userInfo[MPMoviePlayerThumbnailImageKey];
}


@end
