/*
 
 @header HKWStickView.h
 
 @abstract
 
 @author Created by Kelvin Huang on 15/11/24.
 
 @version 1.00 15/11/24 Creation
 
 Copyright © 2015年 ZSbrother. All rights reserved.
 
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "SpatialVariationModel.h"
#import "HKWStickViewManager.h"

#define AREA_WIDTH          150.0
#define STICK_VIEW_WIDTH    50.0
#define CONTROL_AREA_RADIUS AREA_WIDTH/2

typedef NS_ENUM(NSInteger,StickViewDialType)
{
    /** 横纵坐标皆为(-1~1)*/
    StickViewDialTypeDefault,
    /** 横坐标为(-1~1),纵坐标为(0~1)*/
    StickViewDialTypeZero
    /// sfsadf
};

@interface HKWStickView : UIView
{
    HKWStickViewManager *_manager;
}

/** 背景图片*/
@property (nonatomic, strong) UIImageView *bgImageView;
/** 摇杆图片*/
@property (nonatomic, strong) UIImageView *stickImageView;
/** 摇杆默认位置*/
@property (nonatomic, assign) CGPoint defaultPosition;
/** 摇杆View可以移动的位置*/
@property (nonatomic, assign) CGRect controlRect;
/** 横纵坐标数值类型,默认为StickViewDialTypeDefault(横纵坐标皆为-1~1)*/
@property (nonatomic, assign) StickViewDialType dialType;


/**
 *  以点击会出现摇杆的区域初始化stickView
 *
 *  @param controlRect 点击会出现摇杆的区域
 *
 *  @return stickView
 */
- (instancetype)initWithControlRect:(CGRect)controlRect;

//用户停止触击摇杆
- (void)stickViewResignActive;

@end
