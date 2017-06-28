//
//  CircleIndicatorView.h
//  仪表盘
//
//  Created by LWX on 16/8/23.
//  Copyright © 2016年 MyCompany. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleIndicatorView : UIView

@property (nonatomic, assign) CGPoint circleCenter; /**< 圆心位置 */
@property (nonatomic, assign) CGFloat radius; /**< 半径 */

@property (nonatomic, assign) NSUInteger outerAnnulusLineCountToShow; /**< 外圆环要显示的线条数 */

@property (nonatomic, assign) CGFloat openAngle; /**< 开口角度 */

@property (nonatomic, assign) NSUInteger minValue; /**< 最小值 */
@property (nonatomic, assign) NSUInteger maxValue;  /**< 最大值 */

@property (nonatomic, assign) NSUInteger indicatorValue; /**< 指示器的值 */

@property (nonatomic, assign) BOOL enable; /**< 是否处于可用状态。enable = YES，处于可用状态。enable = NO，处于不可用状态。 */

@property (nonatomic, assign) NSInteger centerValue; /**< 中间的数值 */

@property (nonatomic, strong) UILabel *centerValueLabel; /**< 中间的数值 */
@property (nonatomic, strong) UILabel *centerHintLabel;  /**< 中间的提示 */

@property (nonatomic, strong) NSArray<NSNumber *> *innerAnnulusValueToShowArray; /**< 数组，其元素为内圆环要显示的数值 */

@property (nonatomic, assign) BOOL hotStatusOnOff;

#pragma mark - ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ 内部元素位置或尺寸比例 ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

@property (nonatomic, assign) CGFloat circleCenterX_ratio; /**< 圆心 X 比例 */
@property (nonatomic, assign) CGFloat circleCenterY_ratio; /**< 圆心 Y 比例 */

@property (nonatomic, assign) CGFloat outerAnnulusInnerCircleRadius_ratio; /**< 外圆环内圆半径 */
@property (nonatomic, assign) CGFloat innerAnnulusInnerCircleRadius_ratio; /**< 内圆环内圆半径 */

@property (nonatomic, assign) CGFloat outerAnnulusRectangleWidht_ratio; /**< 外圆环外部矩形的宽，以圆环中最顶端的矩形为准 */
@property (nonatomic, assign) CGFloat outerAnnulusRectangleHeight_ratio; /**< 外圆环外部矩形的高，以圆环中最顶端的矩形为准 */

@property (nonatomic, assign) CGFloat innerAnnulusRectangleWidht_ratio; /**< 内圆环外部矩形的宽，以圆环中最顶端的矩形为准 */
@property (nonatomic, assign) CGFloat innerAnnulusRectangleHeight_ratio; /**< 内圆环外部矩形的高，以圆环中最顶端的矩形为准 */
@property (nonatomic, assign) CGFloat innerAnnulusScaleRectangleWidht_ratio; /**< 内圆环外部刻度矩形的宽，以圆环中最顶端的矩形为准 */
@property (nonatomic, assign) CGFloat innerAnnulusScaleRectangleHeight_ratio; /**< 内圆环外部刻度矩形的高，以圆环中最顶端的矩形为准 */

@property (nonatomic, assign) CGFloat dotRadius_ratio; /**< 圆点半径 */

@property (nonatomic, assign) CGFloat outerAnnulusIndicatorLabelOffset_ratio; /**< 外圆环显示文字与圆的距离 */
@property (nonatomic, assign) CGFloat outerAnnulusIndicatorLabelFontSize_ratio; /**< 外圆环显示文字大小 */

@property (nonatomic, assign) CGFloat innerAnnulusScaleLabelOffset_ratio; /**< 内圆环显示文字与圆的距离 */
@property (nonatomic, assign) CGFloat innerAnnulusScaleLabelFontSize_ratio; /**< 内圆环显示文字大小 */

@property (nonatomic, assign) CGFloat centerValueLabelFontSize_ratio;
@property (nonatomic, assign) CGFloat centerHintLabelFontSize_ratio;
@property (nonatomic, assign) CGFloat centerValueLabelXOffset_ratio;
@property (nonatomic, assign) CGFloat centerValueLabelYOffset_ratio;
@property (nonatomic, assign) CGFloat centerHintLabelXOffset_ratio;
@property (nonatomic, assign) CGFloat centerHintLabelYOffset_ratio;

@property (nonatomic, assign) CGFloat hotStatusButtonWidth_ratio; /**< 加热状态按钮宽的显示比例 */
@property (nonatomic, assign) CGFloat hotStatusButtonHeight_ratio; /**< 加热状态按钮高的显示比例 */
@property (nonatomic, assign) CGFloat hotStatusButtonXOffset_ratio;
@property (nonatomic, assign) CGFloat hotStatusButtonYOffset_ratio;

@property (nonatomic, assign) CGFloat minusButtonWidth_ratio;
@property (nonatomic, assign) CGFloat minusButtonHeight_ratio;
@property (nonatomic, assign) CGFloat addButtonWidth_ratio;
@property (nonatomic, assign) CGFloat addButtonHeight_ratio;

@property (nonatomic, assign) CGFloat minusAndAddButtonAngleOffset_ratio;
@property (nonatomic, assign) CGFloat minusAndAddButtonRadiusOffset_ratio;

#pragma mark - ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ end ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

@property (nonatomic, copy) void(^minusBlock)();
@property (nonatomic, copy) void(^addBlock)();

/**
 开始闪动
 
 @param timeInterval 从一个彩色条滚动到下一个彩色条的时间间隔
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
