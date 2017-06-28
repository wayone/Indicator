//
//  RectangleIndicatorView.h
//  仪表盘
//
//  Created by LWX on 16/8/23.
//  Copyright © 2016年 MyCompany. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RectangleIndicatorView : UIView

@property (nonatomic, assign) NSUInteger lineCountToShow; /**< 要显示的线条数 */

@property (nonatomic, assign) NSInteger minValue; /**< 最小值 */
@property (nonatomic, assign) NSInteger maxValue; /**< 最大值 */

@property (nonatomic, assign) NSInteger indicatorValue; /**< 指示器的值, 默认开启动画，从旧值变化到新值 */

@property (nonatomic, assign) BOOL enable; /**< 是否处于可用状态。enable = YES，处于可用状态。enable = NO，处于不可用状态。 */

@property (nonatomic, assign) NSInteger centerValue; /**< 中间的数值 */

@property (nonatomic, strong) UILabel *centerValueLabel; /**< 中间的数值 */
@property (nonatomic, strong) UILabel *centerHintLabel;  /**< 中间的提示 */

@property (nonatomic, strong) NSArray<NSNumber *> *valueToShowArray; /**< 数组，其元素为要显示的数值 */

@property (nonatomic, assign) CGPoint circleCenter; /**< 圆心位置 */
@property (nonatomic, assign) CGFloat radius; /**< 半径 */
@property (nonatomic, assign) CGFloat openAngle; /**< 开口角度 */

@property (nonatomic, assign) BOOL hotStatusOnOff;

#pragma mark - ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ 内部元素位置或尺寸比例 ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

@property (nonatomic, assign) CGFloat rectangleY_ratio;
@property (nonatomic, assign) CGFloat rectangleWidth_ratio;
@property (nonatomic, assign) CGFloat rectangleHeight_ratio;
@property (nonatomic, assign) CGFloat lineWidth_ratio;
@property (nonatomic, assign) CGFloat lineHeight_ratio;
@property (nonatomic, assign) CGFloat lineProtrudingUpHeight_ratio;
@property (nonatomic, assign) CGFloat lineProtrudingDownHeight_ratio;
@property (nonatomic, assign) CGFloat dotRadius_ratio;
@property (nonatomic, assign) CGFloat minusAddButtonSpaceToCenterX_ratio;
@property (nonatomic, assign) CGFloat minusButtonWidth_ratio;
@property (nonatomic, assign) CGFloat minusButtonHeight_ratio;
@property (nonatomic, assign) CGFloat addButtonWidth_ratio;
@property (nonatomic, assign) CGFloat addButtonHeight_ratio;
@property (nonatomic, assign) CGFloat centerValueLabelFontSize_ratio;
@property (nonatomic, assign) CGFloat centerHintLabelFontSize_ratio;
@property (nonatomic, assign) CGFloat hotStatusButtonWidth_ratio;
@property (nonatomic, assign) CGFloat hotStatusButtonHeight_ratio;
@property (nonatomic, assign) CGFloat hotStatusButtonXOffset_ratio;
@property (nonatomic, assign) CGFloat hotStatusButtonYOffset_ratio;
@property (nonatomic, assign) CGFloat indicatorLabelOffset_ratio;
@property (nonatomic, assign) CGFloat indicatorLabelFontSize_ratio;
@property (nonatomic, assign) CGFloat scaleLabelFontSize_ratio;
@property (nonatomic, assign) CGFloat scaleLabelOffset_ratio;
@property (nonatomic, assign) CGFloat centerValueLabelYOffset_ratio;
@property (nonatomic, assign) CGFloat centerHintLabelYOffset_ratio;
@property (nonatomic, assign) CGFloat minusButtonXOffset_ratio;
@property (nonatomic, assign) CGFloat minusButtonYOffset_ratio;
@property (nonatomic, assign) CGFloat addButtonXOffset_ratio;
@property (nonatomic, assign) CGFloat addButtonYOffset_ratio;

#pragma mark - ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ end ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

@property (nonatomic, copy) void(^minusBlock)();
@property (nonatomic, copy) void(^addBlock)();


/**
 开始闪动

 @param timeInterval 从一个彩色条条滚动到下一个彩色条的时间间隔
 @param pauseDuration 滚动到结尾时的停顿时间
 @param finalValue 第三次滚动的结束值
 @param finishBlock 滚动完成之后的回调
 */
- (void)shineWithTimeInterval:(NSTimeInterval)timeInterval pauseDuration:(NSTimeInterval)pauseDuration finalValue:(NSUInteger)finalValue finishBlock:(void(^)())finishBlock;

/// 清空彩色条，不带动画
- (void)clearIndicatorValue;

/// 设置指示器的值
- (void)setIndicatorValue:(NSInteger)indicatorValue animated:(BOOL)animated;

@end
