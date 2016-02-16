/*
 
 @header HKWStickView.m
 
 @abstract
 
 @author Created by Kelvin Huang on 15/11/24.
 
 @version 1.00 15/11/24 Creation
 
 Copyright © 2015年 ZSbrother. All rights reserved.
 
 */

#import "HKWStickView.h"

@implementation HKWStickView

//初始化方法
- (instancetype)initWithControlRect:(CGRect)controlRect
{
    self = [super initWithFrame:controlRect];
    if (self) {
        [self createViews];
        _dialType = StickViewDialTypeDefault;
        _controlRect = controlRect;
        _bgImageView.center = self.center;
        _manager = [HKWStickViewManager shareManager];
    }
    
    return self;
}

//子视图布局
- (void)createViews
{
    //背景图片
    _bgImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, AREA_WIDTH + STICK_VIEW_WIDTH, AREA_WIDTH + STICK_VIEW_WIDTH)];
    _bgImageView.alpha = 0;
    [self addSubview:_bgImageView];
    
    //摇杆图片
    _stickImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, STICK_VIEW_WIDTH, STICK_VIEW_WIDTH)];
    _stickImageView.center = _bgImageView.center;
    [_bgImageView addSubview:_stickImageView];
    
    //初始化摇杆默认位置
    _defaultPosition = _bgImageView.center;
}

//重新设置摇杆View可以移动的位置区域
- (void)setControlRect:(CGRect)controlRect
{
    _controlRect = controlRect;
    self.frame = _controlRect;
}

#pragma mark - 拖动摇杆触发的方法
//开始拖动
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self stickViewDidBecomeActive];
    
    for (UITouch *touch in [touches allObjects]) {
        
        CGPoint point = [touch locationInView:self];
        _bgImageView.center = point;
    }
    _stickImageView.center = _defaultPosition;//摇杆图片恢复默认位置
    
    //若frequency不为0,开始计时器
    if (_manager.frequency) {
        [_manager stickViewDidBecomeActive];
    }
}

//拖动摇杆过程中
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    SpatialVariationModel *varModel = [[SpatialVariationModel alloc]init];
    NSMutableSet *views = [[NSMutableSet alloc]init];
    for (UITouch *touch in [event allTouches]) {
        //移动中和停留在屏幕上的Touch对象
        if (touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary) {
            
            if ([touch.view isKindOfClass:[HKWStickView class]]) {
                HKWStickView *stickView = (HKWStickView *)touch.view;
                [views addObject:stickView];
                
                CGPoint point = [touch locationInView:stickView.bgImageView];
                
                //触击点离开圆形背景区域时
                if (![self isInControlArea:point]) {
                    point = [self getEdgePoint:point];//以边缘点替代
                }
                
                if (touch.view.tag == self.tag) {
                    _stickImageView.center = point;//摇杆图片跟随点击位置
                }
                
                //计算相对坐标点,并回调返回
                CGPoint variationPoint = [self getVariationPoint:point dialType:stickView.dialType];
                NSAssert(variationPoint.y<=1, @"超出了控制范围");
                
                if (stickView.dialType == StickViewDialTypeZero) {
                    varModel.height = variationPoint.y;
                    varModel.direction = variationPoint.x;
                    
                    [_manager setSpatiality:variationPoint];
                }
                else {
                    varModel.roll = variationPoint.x;
                    varModel.pitch = variationPoint.y;
                    
                    [_manager setRotation:variationPoint];
                }
            }
        }
    }
    _manager.stickViews = views;
    
    //若frequency不为0,则以frequency频率返回点,否则无特定频率直接返回点
    if (!_manager.frequency) {
        [_manager.delegate stickViews:views deviceSpatialVariation:varModel];
    }
}

//拖动结束
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _stickImageView.center = _defaultPosition;//摇杆图片恢复默认位置
    for (UITouch *touch in touches) {
        HKWStickView *stickView = (HKWStickView *)touch.view;
        if (stickView.dialType == StickViewDialTypeZero) {
            [_manager dialTypeZeroResignActive];
        }
        else {
            [_manager dialTypeDefaultResignActive];
        }
    }
    [self stickViewResignActive];
    
    //若frequency不为0,停止计时器
    if (_manager.frequency) {
        
        BOOL touchCancel = YES;
        for (UITouch *touch in [event allTouches]) {//全部都是cancel时停止计时器及相关逻辑
            if (touch.phase != UITouchPhaseEnded) {
                touchCancel = touchCancel && NO;
            }
        }
        
        if (touchCancel) {
            [_manager stickViewResignActive];
        }
    }
}

#pragma mark - 私有方法
//限制摇杆的移动区域
- (BOOL)isInControlArea:(CGPoint)point
{
    //获取相对中心点坐标的距离
    CGFloat relativeX = fabs(point.x - _defaultPosition.x);
    CGFloat relativeY = fabs(point.y - _defaultPosition.y);
    
    //利用勾股定理判断点是否在圆内
    if ((relativeX * relativeX) + (relativeY * relativeY) <= (CONTROL_AREA_RADIUS * CONTROL_AREA_RADIUS)) {
        return YES;
    }
    
    return NO;
}

//获取边缘点
- (CGPoint)getEdgePoint:(CGPoint)point
{
    //获取相对中心点坐标的距离
    CGFloat relativeX = fabs(point.x - _defaultPosition.x);
    CGFloat relativeY = fabs(point.y - _defaultPosition.y);
    
    //利用勾股定理获取当前触击点的弦的长度
    CGFloat chord = sqrt(relativeX * relativeX + relativeY * relativeY);
    
    //利用三角函数计算边缘点的相对坐标
    CGFloat cosine = relativeX/chord;
    CGFloat edgeReletiveX = CONTROL_AREA_RADIUS * cosine;
    CGFloat edgeReletiveY = sqrt(CONTROL_AREA_RADIUS * CONTROL_AREA_RADIUS - edgeReletiveX * edgeReletiveX);
    
    //恢复原坐标系坐标
    CGFloat edgePointX = (point.x >= _defaultPosition.x) ? _defaultPosition.x + edgeReletiveX : _defaultPosition.x - edgeReletiveX;
    CGFloat edgePointY = (point.y >= _defaultPosition.y) ? _defaultPosition.y + edgeReletiveY : _defaultPosition.y - edgeReletiveY;
    
    return CGPointMake(edgePointX, edgePointY);
}

/**
 *  计算点的位移变化量
 *  1.StickViewDialTypeDefault: 转换为-1~1间的值
 *  2.StickViewDialTypeZero:    转换为0~1间的值
 */
- (CGPoint)getVariationPoint:(CGPoint)point dialType:(StickViewDialType)dialType
{
    CGFloat variationX = (point.x - _defaultPosition.x)/(AREA_WIDTH/2);
    
    CGFloat variationY = (dialType == StickViewDialTypeDefault) ? (_defaultPosition.y - point.y)/(AREA_WIDTH/2) : (AREA_WIDTH - (point.y - STICK_VIEW_WIDTH/2))/AREA_WIDTH;
    
    return CGPointMake(variationX, variationY);
}

//限制摇杆显示在屏幕内,当前未使用该方法
- (CGPoint)limitControlAreaInScreen:(CGPoint)point
{
    CGFloat pointX = point.x;
    CGFloat pointY = point.y;
    CGFloat stickViewWidth = _bgImageView.frame.size.width;
    CGFloat controlRectWidth = _controlRect.size.width;
    CGFloat controlRectHeight = _controlRect.size.height;
    
    //左边缘不在屏幕内
    if ((point.x - stickViewWidth/2) < 0) {
        pointX = stickViewWidth/2;
    }
    //上边缘不在屏幕内
    if ((point.y - stickViewWidth/2) < 0) {
        pointY = stickViewWidth/2;
    }
    //右边缘不在屏幕内
    if ((point.x + stickViewWidth/2) > controlRectWidth) {
        pointX = controlRectWidth - stickViewWidth/2;
    }
    //下边缘不在屏幕内
    if ((point.y + stickViewWidth/2) > controlRectHeight) {
        pointY = controlRectHeight - stickViewWidth/2;
    }
    
    return CGPointMake(pointX, pointY);
}

//用户开始触击摇杆
- (void)stickViewDidBecomeActive
{
    [UIView animateWithDuration:0.1 animations:^{
        
        _bgImageView.alpha = 1.0;
    }];
}

//用户停止触击摇杆
- (void)stickViewResignActive
{
    [UIView animateWithDuration:0.3 animations:^{
        
        _bgImageView.alpha = 0;
    }];
}

@end
