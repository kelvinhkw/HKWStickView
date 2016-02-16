/*
 
 @header HKWStickViewManager.m FlyingControl
 
 @abstract
 
 @author Created by zsbrother on 15/12/14.
 
 @version 1.00 15/12/14 Creation
 
  Copyright © 2015年 ZSbrother. All rights reserved.
 
 */

#import "HKWStickViewManager.h"

@implementation HKWStickViewManager

//销毁timer对象
- (void)dealloc
{
    if ([_sendPointTimer isValid]) {
        [_sendPointTimer invalidate];
        _sendPointTimer = nil;
    };
}

#pragma mark - init
//单例
+ (HKWStickViewManager *)shareManager
{
    //创建StickView管理对象
    static HKWStickViewManager *instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        instance = [[HKWStickViewManager alloc]init];
        
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _roll      = 0;
        _pitch     = 0;
        _height    = 0.5;
        _direction = 0;
    }
    return self;
}

#pragma mark - 公有方法
//返回点频率,默认为0;若frequency不为0,则以此频率返回点,否则默认返回所以点
- (void)setFrequency:(CGFloat)frequency
{
    _frequency = frequency;
    //当设置了频率时,才会初始化计时器
    _sendPointTimer = [NSTimer scheduledTimerWithTimeInterval:_frequency target:self selector:@selector(sendPointWithFrequency) userInfo:nil repeats:YES];
    [_sendPointTimer setFireDate:[NSDate distantFuture]];
}

//刷新设备的空间中的状态
- (void)setRotation:(CGPoint)rotationPoint
{
    _roll = rotationPoint.x;
    _pitch = rotationPoint.y;
}

- (void)setSpatiality:(CGPoint)spatialityPoint
{
    _height = spatialityPoint.y;
    _direction = spatialityPoint.x;
}

//开始计时器
- (void)startTick
{
    if (!_ticking) {
        [_sendPointTimer setFireDate:[NSDate date]];
        _ticking = YES;
    }
}

//停止计时器
- (void)stopTick
{
    [_sendPointTimer setFireDate:[NSDate distantFuture]];
    _ticking = NO;
}

//用户开始触击摇杆
- (void)stickViewDidBecomeActive
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HKWStickViewDidBecomeActiveNotification object:nil];
}

//用户停止触击摇杆
- (void)stickViewResignActive
{
    _roll = 0;
    _pitch = 0;
    _height = 0.5;
    _direction = 0;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HKWStickViewResignActiveNotification object:nil];
}

- (void)dialTypeDefaultResignActive
{
    _roll = 0;
    _pitch = 0;
}

- (void)dialTypeZeroResignActive
{
    _height = 0.5;
    _direction = 0;
}

#pragma mark - 私有方法
//初始化静态的通知变量
NSString * const HKWStickViewDidBecomeActiveNotification = @"HKWStickViewDidBecomeActiveNotification";
NSString * const HKWStickViewResignActiveNotification    = @"HKWStickViewResignActiveNotification";

//设置一个bufferArr缓冲区,按一定频率回调点坐标
- (void)sendPointWithFrequency
{
    SpatialVariationModel *model = [[SpatialVariationModel alloc]init];
    model.roll = _roll;
    model.pitch = _pitch;
    model.height = _height;
    model.direction = _direction;

    [_delegate stickViews:_stickViews deviceSpatialVariation:model];
}


@end
