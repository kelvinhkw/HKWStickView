/*
 
 @header HKWStickViewManager.h
 
 @abstract
 
 @author Created by zsbrother on 15/12/14.
 
 @version 1.00 15/12/14 Creation
 
  Copyright © 2015年 ZSbrother. All rights reserved.
 
 */

#import <Foundation/Foundation.h>
#import "SpatialVariationModel.h"

@class HKWStickView;

@protocol HKWStickViewDelegate;

UIKIT_EXTERN NSString * const HKWStickViewDidBecomeActiveNotification;//StickView激活状态时的通知
UIKIT_EXTERN NSString * const HKWStickViewResignActiveNotification;   //StickView隐藏时的通知

@interface HKWStickViewManager : NSObject
{
    CGFloat _roll;
    CGFloat _pitch;
    CGFloat _height;
    CGFloat _direction;
    
    NSTimer *_sendPointTimer;
}

@property (nonatomic, weak) id <HKWStickViewDelegate> delegate;
/** 返回点频率,默认为0;若frequency不为0,则以此频率返回点,否则默认返回所以点*/
@property (nonatomic, assign) CGFloat frequency;
/** 所有的StickViews*/
@property (nonatomic, copy) NSSet *stickViews;
/** 计时器是否在运行中*/
@property (nonatomic, assign, getter=isTicking) BOOL ticking;


//单例
+ (HKWStickViewManager *)shareManager;

//刷新设备的空间中的状态
- (void)setSpatiality:(CGPoint)spatialityPoint;
- (void)setRotation:(CGPoint)rotationPoint;

//开始计时器
- (void)startTick;
//停止计时器
- (void)stopTick;

//用户开始触击摇杆
- (void)stickViewDidBecomeActive;
//用户停止触击摇杆
- (void)stickViewResignActive;

- (void)dialTypeDefaultResignActive;
- (void)dialTypeZeroResignActive;

@end


/**
 *  stickView摇杆信息代理
 */
@protocol HKWStickViewDelegate <NSObject>
@optional

/**
 *  返回摇杆拖拽后的位移变化量
 *
 *  @param stickView           stickView对象
 *  @param variationModel      设备空间变化量转换为-1~1或0~1间的值
 */
- (void)stickViews:(NSSet<HKWStickView *> *)stickViews deviceSpatialVariation:(SpatialVariationModel *)variationModel;

@end