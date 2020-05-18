//
//  CircleIndicatorView.m
//  仪表盘
//
//  Created by LWX on 16/8/23.
//  Copyright © 2016年 MyCompany. All rights reserved.
//

#define AngleToRadian(x) (M_PI*(x)/180.0) // 把角度转换成弧度
#define RadianToAngle(x) (180.0*(x)/M_PI) // 把弧度转换成角度
#define SystemVersion [[[UIDevice currentDevice] systemVersion] floatValue]
#define DefaultFont(fontsize) SystemVersion >= 9.0 ? [UIFont fontWithName:@"PingFangSC-Light" size:(fontsize)] : [UIFont systemFontOfSize:(fontsize)]

#define FitValueBaseOnWidth(value) (value) / 375.0 * self.bounds.size.width

#define ApplyRatio(value) ((value) > 0 ? (value) : 1.0)

#import "CircleIndicatorView.h"

@interface CircleIndicatorView ()

@property (nonatomic, strong) CALayer *layer1;
@property (nonatomic, strong) CALayer *layer2;
@property (nonatomic, strong) CALayer *layer3;

@property (nonatomic, assign) CGFloat outerAnnulusInnerCircleRadius; /**< 外圆环内圆半径 */
@property (nonatomic, assign) CGFloat innerAnnulusInnerCircleRadius; /**< 内圆环内圆半径 */

@property (nonatomic, assign) CGFloat outerAnnulusRectangleWidht; /**< 外圆环外部矩形的宽，以圆环中最顶端的矩形为准 */
@property (nonatomic, assign) CGFloat outerAnnulusRectangleHeight; /**< 外圆环外部矩形的高，以圆环中最顶端的矩形为准 */

@property (nonatomic, assign) CGFloat innerAnnulusRectangleWidht; /**< 内圆环外部矩形的宽，以圆环中最顶端的矩形为准 */
@property (nonatomic, assign) CGFloat innerAnnulusRectangleHeight; /**< 内圆环外部矩形的高，以圆环中最顶端的矩形为准 */
@property (nonatomic, assign) CGFloat innerAnnulusScaleRectangleWidht; /**< 内圆环外部刻度矩形的宽，以圆环中最顶端的矩形为准 */
@property (nonatomic, assign) CGFloat innerAnnulusScaleRectangleHeight; /**< 内圆环外部刻度矩形的高，以圆环中最顶端的矩形为准 */

@property (nonatomic, assign) CGFloat startAngle; /**< 起始角度，以圆的水平分割线的右半边为 0 度，往下顺时针旋转 */
@property (nonatomic, assign) CGFloat endAngle;   /**< 结束角度 */

@property (nonatomic, assign) NSUInteger innerAnnulusLineCountToShow; /**< 内圆环要显示的线条数 */

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, assign) CGFloat outerAnnulusAngleEveryLine; /**< 外圆环每条线均分的角度 */
@property (nonatomic, assign) CGFloat innerAnnulusAngleEveryLine; /**< 内圆环每条线均分的角度 */

@property (nonatomic, assign) CGFloat dotRadius; /**< 圆点半径 */

@property (nonatomic, assign) CGFloat outerAnnulusIndicatorLabelOffset; /**< 外圆环显示文字与圆的距离 */
@property (nonatomic, assign) CGFloat outerAnnulusIndicatorLabelFontSize; /**< 外圆环显示文字大小 */

@property (nonatomic, assign) CGFloat innerAnnulusScaleLabelOffset; /**< 内圆环显示文字与圆的距离 */
@property (nonatomic, assign) CGFloat innerAnnulusScaleLabelFontSize; /**< 内圆环显示文字大小 */

@property (nonatomic, assign) CGFloat centerValueLabelFontSize;
@property (nonatomic, assign) CGFloat centerValueLabelXOffset;
@property (nonatomic, assign) CGFloat centerValueLabelYOffset;

@property (nonatomic, assign) CGFloat centerHintLabelFontSize;
@property (nonatomic, assign) CGFloat centerHintLabelXOffset;
@property (nonatomic, assign) CGFloat centerHintLabelYOffset;

@property (nonatomic, strong) UIButton *hotStatusButton; /**< 加热状态，这里用按钮的选中状态来显示不同状态的图片 */
@property (nonatomic, assign) CGFloat hotStatusButtonWidth;
@property (nonatomic, assign) CGFloat hotStatusButtonHeight;
@property (nonatomic, assign) CGFloat hotStatusButtonXOffset;
@property (nonatomic, assign) CGFloat hotStatusButtonYOffset;

@property (nonatomic, strong) UIButton *minusButton; /**< 减按钮 */
@property (nonatomic, strong) UIButton *addButton;   /**< 加按钮 */

@property (nonatomic, assign) CGFloat minusButtonWidth;
@property (nonatomic, assign) CGFloat minusButtonHeight;
@property (nonatomic, assign) CGFloat addButtonWidth;
@property (nonatomic, assign) CGFloat addButtonHeight;

@property (nonatomic, assign) CGFloat minusAndAddButtonAngleOffset;
@property (nonatomic, assign) CGFloat minusAndAddButtonRadiusOffset;

@property (nonatomic, assign) BOOL isStop; /**< 是否立即停止 */

@property (nonatomic, assign) NSTimeInterval animationTimeInterval; /**< 动画的间隔 */

@property (nonatomic, strong) NSMutableArray *scaleLabelArrayM; // 为了防止 label 释放，这里强引用一下
@property (nonatomic, strong) UIView *touchView; // 触摸 View

@property (nonatomic, strong) NSMutableArray<NSOperation *> *operationArrayM; // 作用：方便添加 operation 之间的依赖：方便取消任务。

@end

@implementation CircleIndicatorView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [self setupDefaultDataThatIsNotRelatedToFrame];
    [self initializeUI];
}

- (void)layoutSubviews {
    [self setDataThatIsRelatedToFrameToCustomRatio];
    [self configureDataToFitSize];
    [self updateUI];
}

- (void)drawRect:(CGRect)rect {
    [self.layer1 removeFromSuperlayer];
    [self.layer2 removeFromSuperlayer];
    [self.layer3 removeFromSuperlayer];
    //NSLog(@"%@", [NSThread currentThread]);
    [self addLayer1];
    [self addLayer2];
    [self addLayer3];
}

/// 添加子视图
- (void)initializeUI {
    self.centerValueLabel = [[UILabel alloc] init];
    [self addSubview:self.centerValueLabel];
    
    self.centerHintLabel = [[UILabel alloc] init];
    [self addSubview:self.centerHintLabel];
    
    self.hotStatusButton = [UIButton new];
    [self addSubview:self.hotStatusButton];
    [self.hotStatusButton setImage:[UIImage imageNamed:@"icon_heating"] forState:UIControlStateNormal];
    [self.hotStatusButton setImage:[UIImage imageNamed:@"icon_heating"] forState:UIControlStateSelected];
    
    self.minusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:self.minusButton];
    [self.minusButton setImage:[UIImage imageNamed:@"btn_less"] forState:UIControlStateNormal];
    [self.minusButton setImage:[UIImage imageNamed:@"btn_less_close"] forState:UIControlStateDisabled];
    [self.minusButton addTarget:self action:@selector(minusButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    self.addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:self.addButton];
    [self.addButton setImage:[UIImage imageNamed:@"btn_plus"] forState:UIControlStateNormal];
    [self.addButton setImage:[UIImage imageNamed:@"btn_plus_close"] forState:UIControlStateDisabled];
    [self.addButton addTarget:self action:@selector(addButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self addTouchView];
}

- (void)addTouchView {
    UIView *touchView = [UIView new];
    self.touchView = touchView;
    [self insertSubview:touchView atIndex:0];
    touchView.backgroundColor = [UIColor clearColor];
    
    UILongPressGestureRecognizer *pan = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(touchAction:)];
    [self.touchView addGestureRecognizer:pan];
    pan.minimumPressDuration = 0;
    pan.allowableMovement = CGFLOAT_MAX;
}

- (void)touchAction:(UILongPressGestureRecognizer *)pan {
    
    CGPoint point = [pan locationInView:self.touchView];
    CGFloat pointAngle = 0;
    
    CGFloat tanValue = fabs(point.x - self.circleCenter.x) / fabs(point.y - self.circleCenter.y);
    CGFloat tanRadian = atan(tanValue);
    CGFloat tanAgnle = RadianToAngle(tanRadian);
    if (point.y > self.circleCenter.y && tanAgnle < 45) {
        return;
    }
    
    if (point.x > self.circleCenter.x && point.y > self.circleCenter.y) {
        CGFloat tanValue = fabs(point.y - self.circleCenter.y) / fabs(point.x - self.circleCenter.x);
        CGFloat tanRadian = atan(tanValue);
        CGFloat tanAgnle = RadianToAngle(tanRadian);
        pointAngle = 360 + tanAgnle;
    }
    if (point.x > self.circleCenter.x && point.y < self.circleCenter.y) {
        CGFloat tanValue = fabs(point.x - self.circleCenter.x) / fabs(point.y - self.circleCenter.y);
        CGFloat tanRadian = atan(tanValue);
        CGFloat tanAgnle = RadianToAngle(tanRadian);
        pointAngle = 270 + tanAgnle;
    }
    if (point.x < self.circleCenter.x && point.y < self.circleCenter.y) {
        CGFloat tanValue = fabs(point.y - self.circleCenter.y) / fabs(point.x - self.circleCenter.x);
        CGFloat tanRadian = atan(tanValue);
        CGFloat tanAgnle = RadianToAngle(tanRadian);
        pointAngle = 180 + tanAgnle;
    }
    if (point.x < self.circleCenter.x && point.y > self.circleCenter.y) {
        CGFloat tanValue = fabs(point.x - self.circleCenter.x) / fabs(point.y - self.circleCenter.y);
        CGFloat tanRadian = atan(tanValue);
        CGFloat tanAgnle = RadianToAngle(tanRadian);
        pointAngle = 90 + tanAgnle;
    }
    
    CGFloat angleMargin = pointAngle - self.startAngle;
    CGFloat toValue = self.minValue;
    if (360 - self.openAngle != 0) {
        toValue = (self.maxValue - self.minValue) * (angleMargin / (360 - self.openAngle)) + self.minValue;
    }
    
    [self setIndicatorValue:toValue animated:NO];
    
    if (pan.state == UIGestureRecognizerStateEnded && self.touchEndBlock) {
        self.touchEndBlock(self.indicatorValue);
    }
}

/// 更新 UI 以适应视图大小的改变
- (void)updateUI {
    //━━━━━━━━━━━━━━━━━━━━ 中间的数值 ━━━━━━━━━━━━━━━━━━━━
    NSString *valueString = [NSString stringWithFormat:@"%@%@", @(self.centerValue), @"°C"];
    NSMutableAttributedString *stringM = [[NSMutableAttributedString alloc] initWithString:valueString];
    NSRange range = [valueString rangeOfString:@"°C"];
    [stringM addAttribute:NSFontAttributeName value:DefaultFont(self.centerValueLabelFontSize) range:NSMakeRange(0, stringM.length - 2)]; // 设置字体字号
    [stringM addAttribute:NSFontAttributeName value:DefaultFont(36.0 / 56.0 * self.centerValueLabelFontSize) range:NSMakeRange(range.location, 2)]; // 设置字体字号
    self.centerValueLabel.attributedText = stringM;
    [self.centerValueLabel sizeToFit];
    CGFloat fitSizeWidth = self.centerValueLabel.bounds.size.width;
    CGFloat fitSizeHeight = self.centerValueLabel.bounds.size.height;
    self.centerValueLabel.frame = CGRectMake(0, 0, fitSizeWidth, fitSizeHeight);
    self.centerValueLabel.textAlignment = NSTextAlignmentCenter;
    self.centerValueLabel.center = CGPointMake(self.circleCenter.x + self.centerValueLabelXOffset, self.circleCenter.y - self.centerValueLabelYOffset);
    
    //━━━━━━━━━━━━━━━━━━━━ 中间的提示文字 ━━━━━━━━━━━━━━━━━━━━
    self.centerHintLabel.font = DefaultFont(self.centerHintLabelFontSize);
    [self.centerHintLabel sizeToFit];
    CGFloat hintLabelFitSizeWidth = self.centerHintLabel.bounds.size.width;
    CGFloat hintLabelFitSizeHeight = self.centerHintLabel.bounds.size.height;
    self.centerHintLabel.frame = CGRectMake(0, 0, hintLabelFitSizeWidth, hintLabelFitSizeHeight);
    self.centerHintLabel.textAlignment = NSTextAlignmentCenter;
    self.centerHintLabel.center = CGPointMake(self.circleCenter.x + self.centerValueLabelXOffset, self.circleCenter.y - self.centerValueLabelYOffset);
    
    //━━━━━━━━━━━━━━━━━━━━ 加热状态按钮 ━━━━━━━━━━━━━━━━━━━━
    if (!self.enable) {
        self.hotStatusButton.selected = NO;
    }
    CGFloat hotStatusButtonWidth = self.hotStatusButtonWidth;
    CGFloat hotStatusButtonHeight = self.hotStatusButtonHeight;
    CGFloat hotStatusButtonX = self.circleCenter.x - hotStatusButtonWidth / 2 + self.hotStatusButtonXOffset;
    CGFloat hotStatusButtonY = self.circleCenter.y + hotStatusButtonHeight / 2 + self.hotStatusButtonYOffset;
    self.hotStatusButton.frame = CGRectMake(hotStatusButtonX, hotStatusButtonY, hotStatusButtonWidth, hotStatusButtonHeight);
    
    //━━━━━━━━━━━━━━━━━━━━ 减按钮 ━━━━━━━━━━━━━━━━━━━━
    CGFloat minusButtonWidth = self.minusButtonWidth;
    CGFloat minusButtonHeight = self.minusButtonHeight;
    CGFloat minusButtonAngle = self.startAngle - self.minusAndAddButtonAngleOffset;
    CGFloat minusButtonCenterX = self.circleCenter.x + (self.outerAnnulusInnerCircleRadius + self.outerAnnulusRectangleHeight / 2 + self.minusAndAddButtonRadiusOffset) * cos(AngleToRadian(360 - minusButtonAngle));
    CGFloat minusButtonCenterY = self.circleCenter.y - (self.outerAnnulusInnerCircleRadius + self.outerAnnulusRectangleHeight / 2 + self.minusAndAddButtonRadiusOffset) * sin(AngleToRadian(360 - minusButtonAngle));
    self.minusButton.frame = CGRectMake(0, 0, minusButtonWidth, minusButtonHeight);
    self.minusButton.center = CGPointMake(minusButtonCenterX, minusButtonCenterY);
    self.minusButton.enabled = self.enable;
    
    //━━━━━━━━━━━━━━━━━━━━ 加按钮 ━━━━━━━━━━━━━━━━━━━━
    CGFloat addButtonWidth = self.addButtonWidth;
    CGFloat addButtonHeight = self.addButtonHeight;
    CGFloat addButtonAngle = 180 - minusButtonAngle;
    CGFloat addButtonCenterX = self.circleCenter.x + (self.outerAnnulusInnerCircleRadius + self.outerAnnulusRectangleHeight / 2 + self.minusAndAddButtonRadiusOffset) * cos(AngleToRadian(360 - addButtonAngle));
    CGFloat addButtonCenterY = self.circleCenter.y - (self.outerAnnulusInnerCircleRadius + self.outerAnnulusRectangleHeight / 2 + self.minusAndAddButtonRadiusOffset) * sin(AngleToRadian(360 - addButtonAngle));
    self.addButton.frame = CGRectMake(0, 0, addButtonWidth, addButtonHeight);
    self.addButton.center = CGPointMake(addButtonCenterX, addButtonCenterY);
    self.addButton.enabled = self.enable;
    
    // ━━━━━━━━━━━━━━━━━━━━ 触摸 View ━━━━━━━━━━━━━━━━━━━━
    self.touchView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
}

/// 设置那些与尺寸无关的变量的默认值
- (void)setupDefaultDataThatIsNotRelatedToFrame {
    self.openAngle = 110.0;
    self.outerAnnulusLineCountToShow = 51;
    self.innerAnnulusValueToShowArray = @[@30, @40, @50, @60];;
    self.minValue = 30;
    self.maxValue = 60;
    self.centerHintLabel.text = @"已关机";
    
    _enable = YES;
    _isStop = NO;
}

/// 设置成用户自定义的值
- (void)setDataThatIsRelatedToFrameToCustomRatio {
    //━━━━━━━━━━━━━━━━━━━━ 设置关键属性 ━━━━━━━━━━━━━━━━━━━━
    CGFloat circleCenterX = self.bounds.size.width / 2 * ApplyRatio(self.circleCenterX_ratio);
    CGFloat circleCenterY = 168.5 / 294 * self.bounds.size.height * ApplyRatio(self.circleCenterY_ratio);
    self.circleCenter = CGPointMake(circleCenterX, circleCenterY);
    
    self.outerAnnulusInnerCircleRadius = 225.0 * 0.5 * ApplyRatio(self.outerAnnulusInnerCircleRadius_ratio);
    self.innerAnnulusInnerCircleRadius = 192.0 * 0.5 * ApplyRatio(self.innerAnnulusInnerCircleRadius_ratio);
    
    self.outerAnnulusRectangleWidht = 3.0 * ApplyRatio(self.outerAnnulusRectangleWidht_ratio);
    self.outerAnnulusRectangleHeight = 27.0 * ApplyRatio(self.outerAnnulusRectangleHeight_ratio);
    
    self.innerAnnulusRectangleWidht = 2.5 * ApplyRatio(self.innerAnnulusRectangleWidht_ratio);
    self.innerAnnulusRectangleHeight = 4.5 * ApplyRatio(self.innerAnnulusRectangleHeight_ratio);
    self.innerAnnulusScaleRectangleWidht = 2.5 * ApplyRatio(self.innerAnnulusScaleRectangleWidht_ratio);
    self.innerAnnulusScaleRectangleHeight = 10.5 * ApplyRatio(self.innerAnnulusScaleRectangleHeight_ratio);
    
    self.dotRadius = 4.0 * ApplyRatio(self.dotRadius_ratio);
    
    self.outerAnnulusIndicatorLabelFontSize = 13.0 * ApplyRatio(self.outerAnnulusIndicatorLabelFontSize_ratio);
    self.outerAnnulusIndicatorLabelOffset = 13.0 * ApplyRatio(self.outerAnnulusIndicatorLabelOffset_ratio);
    
    self.innerAnnulusScaleLabelFontSize = 13.0 * ApplyRatio(self.innerAnnulusScaleLabelFontSize_ratio);
    self.innerAnnulusScaleLabelOffset = 4.0 * ApplyRatio(self.innerAnnulusScaleLabelOffset_ratio);
    
    self.centerValueLabelFontSize = 56.0 * ApplyRatio(self.centerValueLabelFontSize_ratio);
    self.centerValueLabelXOffset = 5.0 * ApplyRatio(self.centerValueLabelXOffset_ratio);
    self.centerValueLabelYOffset = 11.0 * ApplyRatio(self.centerValueLabelYOffset_ratio);
    self.centerHintLabelFontSize = 30.0 * ApplyRatio(self.centerHintLabelFontSize_ratio);
    self.centerValueLabelXOffset = 5.0 * ApplyRatio(self.centerValueLabelXOffset_ratio);
    self.centerValueLabelYOffset = 11.0 * ApplyRatio(self.centerValueLabelYOffset_ratio);
    
    self.hotStatusButtonWidth = 17.0 * ApplyRatio(self.hotStatusButtonWidth_ratio);
    self.hotStatusButtonHeight = 22.0 * ApplyRatio(self.hotStatusButtonHeight_ratio);
    self.hotStatusButtonXOffset = 0 * ApplyRatio(self.hotStatusButtonXOffset_ratio);
    self.hotStatusButtonYOffset = 18.0 * ApplyRatio(self.hotStatusButtonYOffset_ratio);
    
    self.minusButtonWidth = 52.0 * ApplyRatio(self.minusButtonWidth_ratio);
    self.minusButtonHeight = 52.0 * ApplyRatio(self.minusButtonHeight_ratio);
    self.addButtonWidth = 52.0 * ApplyRatio(self.addButtonWidth_ratio);
    self.addButtonHeight = 52.0 * ApplyRatio(self.addButtonHeight_ratio);
    self.minusAndAddButtonAngleOffset = 16.0 * ApplyRatio(self.minusAndAddButtonAngleOffset_ratio);
    self.minusAndAddButtonRadiusOffset = 0.5 * ApplyRatio(self.minusAndAddButtonRadiusOffset_ratio);
    
    // 以下的数据是根据上面的数据推导出来的
    [self calculateDataAccordingDynamicValue];
}

- (void)configureDataToFitSize {
    //━━━━━━━━━━━━━━━━━━━━ 设置关键属性 ━━━━━━━━━━━━━━━━━━━━
    self.outerAnnulusInnerCircleRadius = FitValueBaseOnWidth(self.outerAnnulusInnerCircleRadius);
    self.innerAnnulusInnerCircleRadius = FitValueBaseOnWidth(self.innerAnnulusInnerCircleRadius);
    
    self.outerAnnulusRectangleWidht = FitValueBaseOnWidth(self.outerAnnulusRectangleWidht);
    self.outerAnnulusRectangleHeight = FitValueBaseOnWidth(self.outerAnnulusRectangleHeight);
    self.innerAnnulusRectangleWidht = FitValueBaseOnWidth(self.innerAnnulusRectangleWidht);
    self.innerAnnulusRectangleHeight = FitValueBaseOnWidth(self.innerAnnulusRectangleHeight);
    self.innerAnnulusScaleRectangleWidht = FitValueBaseOnWidth(self.innerAnnulusScaleRectangleWidht);
    self.innerAnnulusScaleRectangleHeight = FitValueBaseOnWidth(self.innerAnnulusScaleRectangleHeight);
    
    self.dotRadius = FitValueBaseOnWidth(self.dotRadius);
    
    self.outerAnnulusIndicatorLabelOffset = FitValueBaseOnWidth(self.outerAnnulusIndicatorLabelOffset);
    self.outerAnnulusIndicatorLabelFontSize = FitValueBaseOnWidth(self.outerAnnulusIndicatorLabelFontSize);
    self.innerAnnulusScaleLabelOffset = FitValueBaseOnWidth(self.innerAnnulusScaleLabelOffset);
    self.innerAnnulusScaleLabelFontSize = FitValueBaseOnWidth(self.innerAnnulusScaleLabelFontSize);
    
    self.centerValueLabelFontSize = FitValueBaseOnWidth(self.centerValueLabelFontSize);
    self.centerHintLabelFontSize = FitValueBaseOnWidth(self.centerHintLabelFontSize);
    self.centerValueLabelXOffset = FitValueBaseOnWidth(self.centerValueLabelXOffset);
    self.centerValueLabelYOffset = FitValueBaseOnWidth(self.centerValueLabelYOffset);
    self.centerHintLabelFontSize = FitValueBaseOnWidth(self.centerHintLabelFontSize);
    self.centerValueLabelXOffset = FitValueBaseOnWidth(self.centerValueLabelXOffset);
    self.centerValueLabelYOffset = FitValueBaseOnWidth(self.centerValueLabelYOffset);
    
    self.hotStatusButtonWidth = FitValueBaseOnWidth(self.hotStatusButtonWidth);
    self.hotStatusButtonHeight = FitValueBaseOnWidth(self.hotStatusButtonHeight);
    self.hotStatusButtonXOffset = FitValueBaseOnWidth(self.hotStatusButtonXOffset);
    self.hotStatusButtonYOffset = FitValueBaseOnWidth(self.hotStatusButtonYOffset);
    
    self.minusButtonWidth = FitValueBaseOnWidth(self.minusButtonWidth);
    self.minusButtonHeight = FitValueBaseOnWidth(self.minusButtonHeight);
    self.addButtonWidth = FitValueBaseOnWidth(self.addButtonWidth);
    self.addButtonHeight = FitValueBaseOnWidth(self.addButtonHeight);
    self.minusAndAddButtonAngleOffset = FitValueBaseOnWidth(self.minusAndAddButtonAngleOffset);
    self.minusAndAddButtonRadiusOffset = FitValueBaseOnWidth(self.minusAndAddButtonRadiusOffset);
    
    // 以下的数据是根据上面的数据推导出来的
    [self calculateDataAccordingDynamicValue];
}

- (void)calculateDataAccordingDynamicValue {
    if (self.maxValue < self.minValue) {
        return;
    }
    self.innerAnnulusLineCountToShow = self.maxValue - self.minValue + 1;
    self.startAngle = 90.0 + self.openAngle / 2.0;
    self.endAngle = 90.0 - self.openAngle / 2.0;
    self.outerAnnulusAngleEveryLine = (360.0 - self.openAngle) / (self.outerAnnulusLineCountToShow - 1);
    NSUInteger space = self.maxValue - self.minValue == 0 ? 1 : self.maxValue - self.minValue;
    self.innerAnnulusAngleEveryLine = (360.0 - self.openAngle) / space;
}

- (void)addLayer1 {
    //━━━━━━━━━━━━━━━━━━━━ layer1：灰色层 ━━━━━━━━━━━━━━━━━━━━
    CALayer *layer1 = [CALayer layer];
    self.layer1 = layer1;
    layer1.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self.layer addSublayer:layer1];
    layer1.backgroundColor = [UIColor colorWithRed:219.0/255.0 green:219.0/255.0 blue:219.0/255.0 alpha:255.0/255.0].CGColor;
    layer1.mask = [self maskLayerForLayer1];
}

- (void)addLayer2 {
    //━━━━━━━━━━━━━━━━━━━━ layer2：彩色渐变层 ━━━━━━━━━━━━━━━━━━━━
    CAGradientLayer *layer2_GradientLayer = [CAGradientLayer layer];
    self.layer2 = layer2_GradientLayer;
    layer2_GradientLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self.layer addSublayer:layer2_GradientLayer];
    [layer2_GradientLayer setColors:@[(id)[UIColor colorWithRed:72.0/255.0 green:178.0/255.0 blue:220.0/255.0 alpha:255.0/255.0].CGColor,
                                      (id)[UIColor colorWithRed:222.0/255.0 green:215.0/255.0 blue:78.0/255.0 alpha:255.0/255.0].CGColor,
                                      (id)[UIColor colorWithRed:240.0/255.0 green:42.0/255.0 blue:36.0/255.0 alpha:255.0/255.0].CGColor]];
    [layer2_GradientLayer setLocations:@[@0.3, @0.5, @0.7]];
    [layer2_GradientLayer setStartPoint:CGPointMake(0, 0.5)];
    [layer2_GradientLayer setEndPoint:CGPointMake(1, 0.5)];
    layer2_GradientLayer.mask = [CALayer layer];
}

- (void)addLayer3 {
    //━━━━━━━━━━━━━━━━━━━━ layer3：内灰色圈的灰色层 ━━━━━━━━━━━━━━━━━━━━
    CALayer *layer = [CALayer layer];
    self.layer3 = layer;
    layer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self.layer addSublayer:layer];
    layer.backgroundColor = [UIColor colorWithRed:219.0/255.0 green:219.0/255.0 blue:219.0/255.0 alpha:255.0/255.0].CGColor;
    layer.mask = [self maskLayerForLayer3];
}

- (void)shineWithTimeInterval:(NSTimeInterval)timeInterval pauseDuration:(NSTimeInterval)pauseDuration finalValue:(NSUInteger)finalValue finishBlock:(void(^)())finishBlock {
    
    [self cancelAllOperations];
    
    if (!self.enable) {
        return;
    }
    
    //━━━━━━━━━━━━━━━━━━━━ 前进 0 ~ 1 ━━━━━━━━━━━━━━━━━━━━
    
    NSMutableArray *operation_01_Array = [self makeOperationFromValue:(self.minValue - 1) toValue:self.maxValue timeInterval:timeInterval isShowAccessoryWhenFinished:NO];
    [self.operationArrayM addObjectsFromArray:operation_01_Array];
    
    //━━━━━━━━━━━━━━━━━━━━ 停顿 ━━━━━━━━━━━━━━━━━━━━
    
    NSOperation *operationPause = [NSBlockOperation blockOperationWithBlock:^{
        self.animationTimeInterval = timeInterval;
        [NSThread sleepForTimeInterval:pauseDuration];
    }];
    [operationPause addDependency:self.operationArrayM.lastObject];
    [self.queue addOperation:operationPause];
    [self.operationArrayM addObject:operationPause];
    
    //━━━━━━━━━━━━━━━━━━━━ 后退 1 ~ 0 ━━━━━━━━━━━━━━━━━━━━
    
    NSArray *operation_10_Array = [self makeOperationFromValue:self.maxValue toValue:(self.minValue - 1) timeInterval:timeInterval isShowAccessoryWhenFinished:NO];
    [operation_10_Array.firstObject addDependency:self.operationArrayM.lastObject];
    [self.operationArrayM addObjectsFromArray:operation_10_Array];
    
    //━━━━━━━━━━━━━━━━━━━━ 前进 0 ~ 目标值 ━━━━━━━━━━━━━━━━━━━━
    
    NSArray *operation_0FinalValue_Array = [self makeOperationFromValue:(self.minValue - 1) toValue:finalValue timeInterval:timeInterval isShowAccessoryWhenFinished:YES];
    [operation_0FinalValue_Array.firstObject addDependency:self.operationArrayM.lastObject];
    [self.operationArrayM addObjectsFromArray:operation_0FinalValue_Array];
    
    //━━━━━━━━━━━━━━━━━━━━ 完成回调 ━━━━━━━━━━━━━━━━━━━━
    
    NSOperation *operationFinish = [NSBlockOperation blockOperationWithBlock:^{
        if (finishBlock) {
            finishBlock();
        }
    }];
    [operationFinish addDependency:self.operationArrayM.lastObject];
    [[NSOperationQueue mainQueue] addOperation:operationFinish];
    [self.operationArrayM addObject:operationFinish];
}

/// 创建 operation，并将其放到恰当的队列里，返回创建的所有 operation
- (NSMutableArray *)makeOperationFromValue:(CGFloat)fromValue toValue:(CGFloat)toValue timeInterval:(NSTimeInterval)timeInterval isShowAccessoryWhenFinished:(BOOL)isShowAccessory {
    if (self.isStop) {
        return [NSMutableArray array];
    }
    NSInteger fromLineNumber = [self lineNumberWithIndicatorValue:fromValue];
    NSInteger toLineNumber = [self lineNumberWithIndicatorValue:toValue];

    NSMutableArray *oprationArrayM = [NSMutableArray array];
    
    int minus = (int)(toLineNumber - fromLineNumber);
    
    NSBlockOperation *lastOperation = nil;

    for (int i = 0; i <= abs(minus); i++) {
        
        int nextLineNumber = (int)fromLineNumber + (minus > 0 ? i : -i);
        
        NSBlockOperation *operation_setMask = [NSBlockOperation blockOperationWithBlock:^{
            self.layer2.mask = [self maskLayerForLayer2WithLineNumber:nextLineNumber];
        }];
        if (lastOperation) {
            [operation_setMask addDependency:lastOperation];
        }
        
        NSBlockOperation *operation_sleep = [NSBlockOperation blockOperationWithBlock:^{
            self.animationTimeInterval = timeInterval;
            // 这个任务会被加到非主队列，会在非主线程执行，所以，这里的睡眠不会影响主线程。
            [NSThread sleepForTimeInterval:timeInterval];
        }];
        [operation_sleep addDependency:operation_setMask];

        // 将【 UI 刷新】放到主队列
        [[NSOperationQueue mainQueue] addOperation:operation_setMask];
        
        // 将【睡眠】放到非主队列
        [self.queue addOperation:operation_sleep];
        
        // 将所有的 operation 保存到数组中，后面取消 operation 时需要用到。
        [oprationArrayM addObject:operation_setMask];
        [oprationArrayM addObject:operation_sleep];
        
        lastOperation = operation_sleep;
    }
    
    if (isShowAccessory) {
        _indicatorValue = toValue;
        NSBlockOperation *operation_showAccessory = [NSBlockOperation blockOperationWithBlock:^{
            [self showAccessoryOnLineWitLineNumber:toLineNumber];
        }];
        
        [operation_showAccessory addDependency:oprationArrayM.lastObject];

        // 将【 UI 刷新】放到主队列
        [[NSOperationQueue mainQueue] addOperation:operation_showAccessory];
        // 将所有的 operation 保存到数组中，后面取消 operation 时需要用到。
        [oprationArrayM addObject:operation_showAccessory];
    }

    return [oprationArrayM copy];
}

- (void)changeIndicatorFromValue:(CGFloat)fromValue toValue:(CGFloat)toValue isShowAccessoryWhenFinished:(BOOL)isShowAccessory duration:(CGFloat)duration  {
    
    NSUInteger fromLineNumber = [self lineNumberWithIndicatorValue:fromValue];
    NSUInteger toLineNumber = [self lineNumberWithIndicatorValue:toValue];
    
    int minus = (int)(toLineNumber - fromLineNumber);
    CGFloat durationTemp = duration / (abs(minus) + 1);
    
    NSBlockOperation *lastOperation = nil;

    for (int i = 0; i <= abs(minus); i++) {
        
        int nextLineNumber = (int)fromLineNumber + (minus > 0 ? i : -i);
        
        NSBlockOperation *operation_setMask = [NSBlockOperation blockOperationWithBlock:^{
            self.layer2.mask = [self maskLayerForLayer2WithLineNumber:nextLineNumber];
        }];
        if (lastOperation != nil) {
            [operation_setMask addDependency:lastOperation];
        }
        
        NSBlockOperation *operation_sleep = [NSBlockOperation blockOperationWithBlock:^{
            self.animationTimeInterval = durationTemp;
            [NSThread sleepForTimeInterval:durationTemp];
        }];
        [operation_sleep addDependency:operation_setMask];
        
        // 将【 UI 刷新】放到主队列
        [[NSOperationQueue mainQueue] addOperation:operation_setMask];
        
        // 将【睡眠】放到非主队列
        [self.queue addOperation:operation_sleep];
        
        // 将所有的 operation 保存到数组中，后面取消 operation 时需要用到。
        [self.operationArrayM addObject:operation_setMask];
        [self.operationArrayM addObject:operation_sleep];
        
        lastOperation = operation_sleep;
    }
    
    if (isShowAccessory) {
        _indicatorValue = toValue;
        NSBlockOperation *operation_showAccessory = [NSBlockOperation blockOperationWithBlock:^{
                [self showAccessoryOnLineWitLineNumber:toLineNumber];
        }];
        if (self.operationArrayM.lastObject) {
            [operation_showAccessory addDependency:self.operationArrayM.lastObject];
        }

        // 将【 UI 刷新】放到主队列
        [[NSOperationQueue mainQueue] addOperation:operation_showAccessory];
        // 将所有的 operation 保存到数组中，后面取消 operation 时需要用到。
        [self.operationArrayM addObject:operation_showAccessory];
    }
}

/**
 计算矩形的四个顶点坐标
 
 @param cirlceCenter 圆心
 @param innerCircleRadius 内圆半径
 @param rectangleWidht 矩形宽
 @param rectangleHeight 矩形高
 @param angle 矩形绕圆心的角度
 @return 数组，包含四个顶点坐标（顺时针，上左，上右，下右，下左）
 */
- (NSArray *)calculateFourKeyPointForRectangleWithCircleCenter:(CGPoint)cirlceCenter innerCircleRadius:(CGFloat)innerCircleRadius rectangleWidht:(CGFloat)rectangleWidht rectangleHeight:(CGFloat)rectangleHeight angle:(CGFloat)angle {
    CGFloat cirlceCenterX = cirlceCenter.x;
    CGFloat cirlceCenterY = cirlceCenter.y;
    
    CGFloat tempAngle = 360 - angle;
    CGFloat tempRadian = AngleToRadian(tempAngle);
    
    CGFloat middlePointX_LeftLine = cirlceCenterX + innerCircleRadius * cos(tempRadian);
    CGFloat middlePointY_LeftLine = cirlceCenterY - innerCircleRadius * sin(tempRadian);
    
    CGFloat topLeftPointX = middlePointX_LeftLine - rectangleWidht / 2 * sin(tempRadian);
    CGFloat topLeftPointY = middlePointY_LeftLine - rectangleWidht / 2 * cos(tempRadian);
    NSValue *topLeftPointValue = [NSValue valueWithCGPoint:CGPointMake(topLeftPointX, topLeftPointY)];
    
    CGFloat topRightPointX = topLeftPointX + rectangleHeight * cos(tempRadian);
    CGFloat topRightPointY = topLeftPointY - rectangleHeight * sin(tempRadian);
    NSValue *topRightPointValue = [NSValue valueWithCGPoint:CGPointMake(topRightPointX, topRightPointY)];
    
    CGFloat bottomLeftPointX = middlePointX_LeftLine + rectangleWidht / 2 * sin(tempRadian);
    CGFloat bottomLeftPointY = middlePointY_LeftLine + rectangleWidht / 2 * cos(tempRadian);
    NSValue *bottomLeftPointValue = [NSValue valueWithCGPoint:CGPointMake(bottomLeftPointX, bottomLeftPointY)];
    
    CGFloat bottomRightPointX = bottomLeftPointX + rectangleHeight * cos(tempRadian);
    CGFloat bottomRightPointY = bottomLeftPointY - rectangleHeight * sin(tempRadian);
    NSValue *bottomRightPointValue = [NSValue valueWithCGPoint:CGPointMake(bottomRightPointX, bottomRightPointY)];
    
    NSArray *pointArray = @[topLeftPointValue, topRightPointValue, bottomRightPointValue, bottomLeftPointValue];
    
    return pointArray;
}

- (void)showAccessoryOnLineWitLineNumber:(NSUInteger)lineNumber {
    NSInteger minLineNumber = [self lineNumberWithIndicatorValue:self.minValue];
    NSInteger maxLineNumber = [self lineNumberWithIndicatorValue:self.maxValue];
    if (lineNumber < minLineNumber || lineNumber > maxLineNumber) {
        return;
    }
    
    CAShapeLayer *maskLayerForLayer2 = (CAShapeLayer *)self.layer2.mask;
    //━━━━━━━━━━━━━━━━━━━━ 添加圆点和文字 ━━━━━━━━━━━━━━━━━━━━
    // 1.添加圆点
    UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:maskLayerForLayer2.path];
    
    CGFloat angle = self.startAngle + lineNumber * self.outerAnnulusAngleEveryLine;
    CGFloat tempRadian = AngleToRadian(360 - angle);
    
    CGPoint innerCircleCenterInMaskLayer = [self.layer convertPoint:self.circleCenter toLayer:maskLayerForLayer2];
    
    CGFloat redDotCenterX = innerCircleCenterInMaskLayer.x + (self.outerAnnulusInnerCircleRadius + self.outerAnnulusRectangleHeight) * cos(tempRadian);
    CGFloat redDotCenterY = innerCircleCenterInMaskLayer.y - (self.outerAnnulusInnerCircleRadius + self.outerAnnulusRectangleHeight) * sin(tempRadian);
    
    CGPoint dotCircleCenter = CGPointMake(redDotCenterX, redDotCenterY);
    
    UIBezierPath *dotPath = [UIBezierPath bezierPathWithArcCenter:dotCircleCenter radius:self.dotRadius startAngle:AngleToRadian(0) endAngle:AngleToRadian(360) clockwise:YES];
    [path appendPath:dotPath];
    maskLayerForLayer2.path = path.CGPath;
    self.layer2.mask = maskLayerForLayer2;
    
    // 2.添加文字
    UILabel *indicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 32, 20)];
    CGFloat indicatorLabelWidth = 32 / 13 * self.outerAnnulusIndicatorLabelFontSize;
    CGFloat indicatorLabelHeight = 20 / 13 * self.outerAnnulusIndicatorLabelFontSize;
    
    indicatorLabel.font = [UIFont systemFontOfSize:self.outerAnnulusIndicatorLabelFontSize];
    indicatorLabel.textAlignment = NSTextAlignmentCenter;
    indicatorLabel.text = [NSString stringWithFormat:@"%@°C", @(self.indicatorValue)];
    indicatorLabel.center = CGPointMake(150, 150);
    // 这句话只是为了持有 indicatorLabel，防止因它释放而导致 indicatorLabel 没有机会往 layer 上绘制文字，从而导致 indicatorLabel.layer 是没有内容的，透明的遮罩是不能显示出遮罩盖住的内容的
    [self addSubview:indicatorLabel];
    [maskLayerForLayer2 addSublayer:indicatorLabel.layer];
    
    CGFloat indicatorLabelCenterX = innerCircleCenterInMaskLayer.x + (self.outerAnnulusInnerCircleRadius + self.outerAnnulusRectangleHeight + self.outerAnnulusIndicatorLabelOffset) * cos(tempRadian) + indicatorLabelWidth / 2 * cos(AngleToRadian(angle));
    
    CGFloat indicatorLabelCenterY = innerCircleCenterInMaskLayer.y - (self.outerAnnulusInnerCircleRadius + self.outerAnnulusRectangleHeight + self.outerAnnulusIndicatorLabelOffset) * sin(tempRadian) + indicatorLabelHeight / 2 * sin(AngleToRadian(angle));
    indicatorLabel.center = CGPointMake(indicatorLabelCenterX, indicatorLabelCenterY);
}

- (NSInteger)lineNumberWithIndicatorValue:(CGFloat)indicatorValue {
    
    if (indicatorValue < self.minValue) {
        return -1;
    }
    
    if (indicatorValue > self.maxValue) {
        return self.outerAnnulusLineCountToShow - 1;
    }
    
    CGFloat valueEveryLine = (self.maxValue - self.minValue) / (CGFloat)(self.outerAnnulusLineCountToShow - 1);
    CGFloat quotientFloat = (CGFloat)(indicatorValue - self.minValue) / valueEveryLine;
    CGFloat remainder = quotientFloat - (int)quotientFloat;
    NSInteger numberReturn = remainder > (valueEveryLine / 2) ? ceil(quotientFloat) : floorf(quotientFloat);
    return numberReturn;
}

/// layer1 的 maskLayer
- (CAShapeLayer *)maskLayerForLayer1 {

    CAShapeLayer * maskLayer= [CAShapeLayer layer];
    maskLayer.frame = CGRectMake(0, 0, self.layer1.bounds.size.width, self.layer1.bounds.size.height);
    
    UIBezierPath *basePath = [UIBezierPath bezierPath];
    
    for (int i = 0; i < self.outerAnnulusLineCountToShow; i++) {
        
        CGFloat angleTemp = self.startAngle + i * self.outerAnnulusAngleEveryLine;
        
        NSArray *rectanglePointArray = [self calculateFourKeyPointForRectangleWithCircleCenter:self.circleCenter innerCircleRadius:self.outerAnnulusInnerCircleRadius rectangleWidht:self.outerAnnulusRectangleWidht rectangleHeight:self.outerAnnulusRectangleHeight angle:angleTemp];
        CGPoint topLeftPoint = ((NSValue *)rectanglePointArray[0]).CGPointValue;
        CGPoint topRightPoint = ((NSValue *)rectanglePointArray[1]).CGPointValue;
        CGPoint bottomRightPoint = ((NSValue *)rectanglePointArray[2]).CGPointValue;
        CGPoint bottomLeftPoint = ((NSValue *)rectanglePointArray[3]).CGPointValue;
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:topLeftPoint];
        [path addLineToPoint:topRightPoint];
        [path addLineToPoint:bottomRightPoint];
        [path addLineToPoint:bottomLeftPoint];
        [path closePath];
        
        // 画在当前的 layer
//        UIColor *strokeColor = [UIColor blackColor];
//        [strokeColor set];
//        [path stroke];
        
        [basePath appendPath:path];
    }
    
    maskLayer.path = basePath.CGPath;
    return maskLayer;
}

/**
 layer2 的 maskLayer

 @param lineNumber 线条的编号。编号从 0 开始，例如：总共显示 10 根彩条，则对应编号分别为 0，1，2 ... 9。如果传入的编号小于 0，则不显示彩色条。
 @return maskLayer
 */
- (CAShapeLayer *)maskLayerForLayer2WithLineNumber:(NSInteger)lineNumber {
    
    if (lineNumber < 0) {
        return [CAShapeLayer layer];
    }
    
    CAShapeLayer * maskLayer= [CAShapeLayer layer];
    maskLayer.frame = CGRectMake(0, 0, self.layer2.bounds.size.width, self.layer2.bounds.size.height);
    
    UIBezierPath *basePath = [UIBezierPath bezierPath];
    
    for (int i = 0; i <= lineNumber; i++) {
        
        CGFloat angleTemp = self.startAngle + i * self.outerAnnulusAngleEveryLine;
        
        NSArray *rectanglePointArray = [self calculateFourKeyPointForRectangleWithCircleCenter:self.circleCenter innerCircleRadius:self.outerAnnulusInnerCircleRadius rectangleWidht:self.outerAnnulusRectangleWidht rectangleHeight:self.outerAnnulusRectangleHeight angle:angleTemp];
        CGPoint topLeftPoint = ((NSValue *)rectanglePointArray[0]).CGPointValue;
        CGPoint topRightPoint = ((NSValue *)rectanglePointArray[1]).CGPointValue;
        CGPoint bottomRightPoint = ((NSValue *)rectanglePointArray[2]).CGPointValue;
        CGPoint bottomLeftPoint = ((NSValue *)rectanglePointArray[3]).CGPointValue;
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:topLeftPoint];
        [path addLineToPoint:topRightPoint];
        [path addLineToPoint:bottomRightPoint];
        [path addLineToPoint:bottomLeftPoint];
        [path closePath];
        
        //        UIColor *strokeColor = [UIColor blackColor];
        //        [strokeColor set];
        //        [path stroke];
        
        [basePath appendPath:path];
    }
    
    maskLayer.path = basePath.CGPath;
    return maskLayer;
}

/// layer3 的 maskLayer
- (CAShapeLayer *)maskLayerForLayer3 {
    
    CAShapeLayer * maskLayer= [CAShapeLayer layer];
    maskLayer.frame = CGRectMake(0, 0, self.layer3.bounds.size.width, self.layer3.bounds.size.height);
    
    UIBezierPath *basePath = [UIBezierPath bezierPath];
    
    // 1.添加矩形
    for (int i = 0; i < self.innerAnnulusLineCountToShow; i++) {
        
        CGFloat angleTemp = self.startAngle + i * self.innerAnnulusAngleEveryLine;
        
        NSArray *rectangleFourKeyPointArray = nil;
        
        BOOL isScaleLine = NO;
        
        for (NSNumber *scaleValue in self.innerAnnulusValueToShowArray) {
            if ((i + self.minValue) == scaleValue.integerValue) {
                isScaleLine = YES;
                break;
            }
        }
        
        if (!isScaleLine) {
            rectangleFourKeyPointArray = [self calculateFourKeyPointForRectangleWithCircleCenter:self.circleCenter innerCircleRadius:self.innerAnnulusInnerCircleRadius rectangleWidht:self.innerAnnulusRectangleWidht rectangleHeight:self.innerAnnulusRectangleHeight angle:angleTemp];
        } else {
            CGFloat innerCircleRadius = self.innerAnnulusInnerCircleRadius - (self.innerAnnulusScaleRectangleHeight - self.innerAnnulusRectangleHeight);
            rectangleFourKeyPointArray = [self calculateFourKeyPointForRectangleWithCircleCenter:self.circleCenter innerCircleRadius:innerCircleRadius rectangleWidht:self.innerAnnulusScaleRectangleWidht rectangleHeight:self.innerAnnulusScaleRectangleHeight angle:angleTemp];
        }
        
        CGPoint topLeftPoint = ((NSValue *)rectangleFourKeyPointArray[0]).CGPointValue;
        CGPoint topRightPoint = ((NSValue *)rectangleFourKeyPointArray[1]).CGPointValue;
        CGPoint bottomRightPoint = ((NSValue *)rectangleFourKeyPointArray[2]).CGPointValue;
        CGPoint bottomLeftPoint = ((NSValue *)rectangleFourKeyPointArray[3]).CGPointValue;
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:topLeftPoint];
        [path addLineToPoint:topRightPoint];
        [path addLineToPoint:bottomRightPoint];
        [path addLineToPoint:bottomLeftPoint];
        [path closePath];
        
        // 画在当前的 layer
        //        UIColor *strokeColor = [UIColor blackColor];
        //        [strokeColor set];
        //        [path stroke];
        
        [basePath appendPath:path];
    }
    
    // 2.添加文字
    CGPoint innerCircleCenterInMaskLayer = [self.layer convertPoint:self.circleCenter toLayer:self.layer3];
    
    self.scaleLabelArrayM = [NSMutableArray array];
    
    for (int i = 0; i < self.innerAnnulusValueToShowArray.count; i++) {
        CGFloat value = self.innerAnnulusValueToShowArray[i].integerValue;
        if (value < self.minValue || value > self.maxValue) {
            continue;
        }
        UILabel *scaleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 18, 12)];
        scaleLabel.text = [NSString stringWithFormat:@"%@°C", self.innerAnnulusValueToShowArray[i]];
        scaleLabel.font = [UIFont systemFontOfSize:self.innerAnnulusScaleLabelFontSize];
        scaleLabel.adjustsFontSizeToFitWidth = YES;
        scaleLabel.textAlignment = NSTextAlignmentCenter;
        [scaleLabel sizeToFit]; // 使用sizeToFit
        CGFloat indicatorLabelWidth = scaleLabel.bounds.size.width;
        CGFloat indicatorLabelHeight = scaleLabel.bounds.size.height;
        
        scaleLabel.textAlignment = NSTextAlignmentCenter;
        scaleLabel.center = CGPointMake(150, 150);
        //NSLog(@"++++++++++++%@", [NSThread currentThread]);

        [self.scaleLabelArrayM addObject:scaleLabel];
        [maskLayer addSublayer:scaleLabel.layer]; // 添加文字的 Layer
        
        CGFloat scaleValue = ((NSNumber *)self.innerAnnulusValueToShowArray[i]).floatValue;
        CGFloat angle = self.startAngle + (scaleValue - self.minValue) * self.innerAnnulusAngleEveryLine;
        CGFloat tempRadian = AngleToRadian(360 - angle);
        CGFloat minus = self.innerAnnulusScaleRectangleHeight - self.innerAnnulusRectangleHeight;
        
        CGFloat indicatorLabelCenterX = innerCircleCenterInMaskLayer.x + (self.innerAnnulusInnerCircleRadius - minus - self.innerAnnulusScaleLabelOffset) * cos(tempRadian) - indicatorLabelWidth / 2 * cos(AngleToRadian(angle));
        
        CGFloat indicatorLabelCenterY = innerCircleCenterInMaskLayer.y - (self.innerAnnulusInnerCircleRadius - minus - self.innerAnnulusScaleLabelOffset) * sin(tempRadian) - indicatorLabelHeight / 2 * sin(AngleToRadian(angle));
        scaleLabel.center = CGPointMake(indicatorLabelCenterX, indicatorLabelCenterY);
    }
    
    maskLayer.path = basePath.CGPath;
    return maskLayer;
}

- (void)minusButtonClick {
    if (self.minusBlock) {
        self.minusBlock();
    }
}

- (void)addButtonClick {
    if (self.addBlock) {
        self.addBlock();
    }
}

- (void)clearIndicatorValue {
    self.isStop = YES;
    [self.queue cancelAllOperations];
    self.layer2.mask = [self maskLayerForLayer2WithLineNumber:-1];
    _indicatorValue = self.minValue - 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.animationTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isStop = NO;
    });
}

- (void)cancelAllOperations {
    [self.operationArrayM enumerateObjectsUsingBlock:^(NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
    [self.operationArrayM removeAllObjects];
}

- (void)setIndicatorValue:(NSInteger)indicatorValue animated:(BOOL)animated {
    if (!self.enable) {
        return;
    }
    
    [self cancelAllOperations];
    
    if (indicatorValue < self.minValue) {
        indicatorValue = self.minValue;
    }
    if (indicatorValue > self.maxValue) {
        indicatorValue = self.maxValue;
    }
    
    NSUInteger oldIndicatorValue = _indicatorValue;
    
    _indicatorValue = indicatorValue;
    
    CGFloat durationTemp = 0;
    if (animated) {
        NSInteger fromLineNumber = [self lineNumberWithIndicatorValue:oldIndicatorValue];
        NSInteger toLineNumber = [self lineNumberWithIndicatorValue:indicatorValue];
        int minus = (int)(toLineNumber - fromLineNumber);
        durationTemp = abs(minus) * 0.02;
    }
    
    [self changeIndicatorFromValue:oldIndicatorValue toValue:indicatorValue isShowAccessoryWhenFinished:YES duration:durationTemp];
    
//    if (animated) {
//        [self setIndicatorValue:indicatorValue];
//    } else {
//        [self.queue cancelAllOperations];
//        NSInteger toLineNumber = [self lineNumberWithIndicatorValue:indicatorValue];
//        self.layer2.mask = [self maskLayerForLayer2WithLineNumber:toLineNumber];
//    }
}

#pragma mark - ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ Getter and Setter ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

- (NSOperationQueue *)queue {
    if (_queue == nil) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
    }
    return _queue;
}

- (void)setIndicatorValue:(NSUInteger)indicatorValue {
    
    if (!self.enable) {
        return;
    }
    
    [self cancelAllOperations];
    
    if (indicatorValue > self.maxValue) {
        indicatorValue = self.maxValue;
    }
    
    NSUInteger oldIndicatorValue = _indicatorValue;
    
    _indicatorValue = indicatorValue;
    
    NSInteger fromLineNumber = [self lineNumberWithIndicatorValue:oldIndicatorValue];
    NSInteger toLineNumber = [self lineNumberWithIndicatorValue:indicatorValue];
    
    int minus = (int)(toLineNumber - fromLineNumber);
    CGFloat durationTemp = abs(minus) * 0.02;
    
    [self changeIndicatorFromValue:oldIndicatorValue toValue:indicatorValue isShowAccessoryWhenFinished:YES duration:durationTemp];
}

- (void)setCenterValue:(NSInteger)centerValue {
    _centerValue = centerValue;
    [self updateUI];
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    
    if (enable == NO) {
        [self changeIndicatorFromValue:self.indicatorValue toValue:self.minValue - 1 isShowAccessoryWhenFinished:NO duration:0.02];
    }
}

- (void)setHotStatusOnOff:(BOOL)hotStatusOnOff {
    _hotStatusOnOff = hotStatusOnOff;
    self.hotStatusButton.hidden = hotStatusOnOff;
}

- (void)setInnerAnnulusValueToShowArray:(NSArray<NSNumber *> *)innerAnnulusValueToShowArray {
    _innerAnnulusValueToShowArray = innerAnnulusValueToShowArray;
    if (self.maxValue < self.minValue) {
        return;
    }
    [self calculateDataAccordingDynamicValue];
    
    [self.layer1 removeFromSuperlayer];
    [self.layer2 removeFromSuperlayer];
    [self.layer3 removeFromSuperlayer];
    
    [self addLayer1];
    [self addLayer2];
    [self addLayer3];
}

- (NSMutableArray<NSOperation *> *)operationArrayM {
    if (_operationArrayM == nil) {
        _operationArrayM = [NSMutableArray array];
    }
    return _operationArrayM;;
}

@end
