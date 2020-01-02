//
//  RectangleIndicatorView.m
//  仪表盘
//
//  Created by LWX on 16/8/23.
//  Copyright © 2016年 MyCompany. All rights reserved.
//

#define AngleToRadian(x) (M_PI*(x)/180.0) // 把角度转换成弧度
#define SystemVersion [[[UIDevice currentDevice] systemVersion] floatValue]
#define DefaultFont(fontsize) SystemVersion >= 9.0 ? [UIFont fontWithName:@"PingFangSC-Light" size:(fontsize)] : [UIFont systemFontOfSize:(fontsize)]

#define FitValueBaseOnWidth(value) (value) / 375.0 * self.bounds.size.width

#define ApplyRatio(value) ((value) > 0 ? (value) : 1.0)

#import "RectangleIndicatorView.h"

typedef NS_ENUM(NSUInteger, LineProtrudingOrientation) {
    LineProtrudingOrientation_None,
    LineProtrudingOrientation_Up,
    LineProtrudingOrientation_Down,
};

@interface RectangleIndicatorView ()

@property (nonatomic, strong) CALayer *layer1;
@property (nonatomic, strong) CALayer *layer2;

#pragma mark - ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ 开始 ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

@property (nonatomic, assign) CGFloat rectangleY; /**< 矩形条 Y，默认 139 */

@property (nonatomic, assign) CGFloat rectangleWidth; /**< 矩形条宽 */
@property (nonatomic, assign) CGFloat rectangleHeight; /**< 矩形条高 */

@property (nonatomic, assign) CGFloat lineWidth; /**< 线条宽 */
@property (nonatomic, assign) CGFloat lineHeight; /**< 线条高 */

@property (nonatomic, assign) CGFloat lineProtrudingUpHeight; /**< 向上突出的线条高 */
@property (nonatomic, assign) CGFloat lineProtrudingDownHeight; /**< 向下突出的线条高 */

@property (nonatomic, assign) CGFloat dotRadius; /**< 圆点半径 */
@property (nonatomic, assign) CGFloat indicatorLabelFontSize; /**< 指针文字大小 */
@property (nonatomic, assign) CGFloat indicatorLabelOffset;
@property (nonatomic, assign) CGFloat scaleLabelFontSize;
@property (nonatomic, assign) CGFloat scaleLabelOffset;

@property (nonatomic, strong) UIButton *minusButton; /**! 减按钮 */
@property (nonatomic, strong) UIButton *addButton;   /**< 加按钮 */

@property (nonatomic, assign) CGFloat minusAddButtonSpaceToCenterX;

@property (nonatomic, assign) CGFloat minusButtonWidth;
@property (nonatomic, assign) CGFloat minusButtonHeight;
@property (nonatomic, assign) CGFloat addButtonWidth;
@property (nonatomic, assign) CGFloat addButtonHeight;

@property (nonatomic, strong) UIButton *hotStatusButton; /**< 加热状态，这里用按钮的选中状态来显示不同状态的图片 */
@property (nonatomic, assign) CGFloat hotStatusButtonWidth;
@property (nonatomic, assign) CGFloat hotStatusButtonHeight;

@property (nonatomic, assign) CGFloat hotStatusButtonXOffset;
@property (nonatomic, assign) CGFloat hotStatusButtonYOffset;

@property (nonatomic, assign) CGFloat centerValueLabelFontSize;
@property (nonatomic, assign) CGFloat centerValueLabelYOffset;
@property (nonatomic, assign) CGFloat centerHintLabelFontSize;
@property (nonatomic, assign) CGFloat centerHintLabelYOffset;

@property (nonatomic, assign) CGFloat minusButtonXOffset;
@property (nonatomic, assign) CGFloat minusButtonYOffset;
@property (nonatomic, assign) CGFloat addButtonXOffset;
@property (nonatomic, assign) CGFloat addButtonYOffset;

@property (nonatomic, assign) CGFloat startX; /**< 起始位置 X，由左向右 */
@property (nonatomic, assign) CGFloat xEveryLine; /**< 每条线占均分的 x 长度 */

#pragma mark - ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

@property (nonatomic, assign) CGFloat startAngle; /**< 起始角度，从圆的中垂线下半部半径开始，顺时针计算 */
@property (nonatomic, assign) CGFloat endAngle;   /**< 结束角度 */

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, assign) BOOL isStop; /**< 是否立即停止 */

@property (nonatomic, assign) NSTimeInterval animationTimeInterval; /**< 动画的间隔 */
@property (nonatomic, strong) UIView *touchView; // 触摸 View

@end

@implementation RectangleIndicatorView

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
    
    [self addLayer1];
    [self addLayer2];
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
    [self.hotStatusButton setImage:[UIImage imageNamed:@""] forState:UIControlStateSelected];
    
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
    [self addSubview:touchView];
    touchView.backgroundColor = [UIColor clearColor];
    
    UILongPressGestureRecognizer *pan = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(touchAction:)];
    [self.touchView addGestureRecognizer:pan];
    pan.minimumPressDuration = 0;
    pan.allowableMovement = CGFLOAT_MAX;
}

- (void)touchAction:(UILongPressGestureRecognizer *)pan {
    CGPoint point = [pan locationInView:self.touchView];
    CGFloat x = point.x - self.startX;
    if (x < 0) {
        x = 0;
    }
    if (x > self.rectangleWidth) {
        x = self.rectangleWidth;
    }
    
    CGFloat indicatorValue = self.minValue;
    if (self.rectangleWidth != 0) {
        indicatorValue = x / self.rectangleWidth * (self.maxValue - self.minValue) + self.minValue;
    }
    
    [self setIndicatorValue:indicatorValue animated:NO];
}

/// 更新 UI , 包含了对子视图位置的更新、样式的更新、状态的更新
- (void)updateUI {
    //━━━━━━━━━━━━━━━━━━━━ 中间的数值 ━━━━━━━━━━━━━━━━━━━━
    NSString *valueString = [NSString stringWithFormat:@"%@%@", @(self.centerValue), @"°C"];
    NSMutableAttributedString *stringM = [[NSMutableAttributedString alloc] initWithString:valueString];
    NSRange range = [valueString rangeOfString:@"°C"];
    [stringM addAttribute:NSFontAttributeName value:DefaultFont(self.centerValueLabelFontSize) range:NSMakeRange(0, stringM.length - 2)]; //设置字体字号
    [stringM addAttribute:NSFontAttributeName value:DefaultFont(36.0 / 56.0 * self.centerValueLabelFontSize) range:NSMakeRange(range.location, 2)]; //设置字体字号
    self.centerValueLabel.attributedText = stringM;
    [self.centerValueLabel sizeToFit];
    CGFloat fitSizeWidth = self.centerValueLabel.bounds.size.width;
    CGFloat fitSizeHeight = self.centerValueLabel.bounds.size.height;
    self.centerValueLabel.frame = CGRectMake(0, 0, fitSizeWidth, fitSizeHeight);
    self.centerValueLabel.textAlignment = NSTextAlignmentCenter;
    self.centerValueLabel.center = CGPointMake(self.bounds.size.width / 2, self.rectangleY - self.centerValueLabelYOffset);

    //━━━━━━━━━━━━━━━━━━━━ 中间的提示文字 ━━━━━━━━━━━━━━━━━━━━
    self.centerHintLabel.font = DefaultFont(self.centerHintLabelFontSize);
    [self.centerHintLabel sizeToFit];
    CGFloat hintLabelFitSizeWidth = self.centerHintLabel.bounds.size.width;
    CGFloat hintLabelFitSizeHeight = self.centerHintLabel.bounds.size.height;
    self.centerHintLabel.frame = CGRectMake(0, 0, hintLabelFitSizeWidth, hintLabelFitSizeHeight);
    self.centerHintLabel.textAlignment = NSTextAlignmentCenter;
    self.centerHintLabel.center = CGPointMake(self.bounds.size.width / 2, self.rectangleY - self.centerHintLabelYOffset);
    
    //━━━━━━━━━━━━━━━━━━━━ 加热状态按钮 ━━━━━━━━━━━━━━━━━━━━
    if (!self.enable) {
        self.hotStatusButton.selected = NO;
    }
    CGFloat hotStatusButtonWidth = self.hotStatusButtonWidth;
    CGFloat hotStatusButtonHeight = self.hotStatusButtonHeight;
    CGFloat hotStatusButtonCenterX = self.hotStatusButtonXOffset;
    CGFloat hotStatusButtonCenterY = self.rectangleY - self.hotStatusButtonYOffset;
    self.hotStatusButton.frame = CGRectMake(0, 0, hotStatusButtonWidth, hotStatusButtonHeight);
    self.hotStatusButton.center = CGPointMake(hotStatusButtonCenterX, hotStatusButtonCenterY);
    
    //━━━━━━━━━━━━━━━━━━━━ 减按钮 ━━━━━━━━━━━━━━━━━━━━
    CGFloat minusButtonWidth = self.minusButtonWidth;
    CGFloat minusButtonHeight = self.minusButtonHeight;
    CGFloat minusButtonX = self.minusButtonXOffset;
    CGFloat minusButtonY = self.rectangleY - self.minusButtonYOffset - self.minusButtonHeight;
    self.minusButton.frame = CGRectMake(minusButtonX, minusButtonY, minusButtonWidth, minusButtonHeight);
    self.minusButton.enabled = self.enable;
    
    //━━━━━━━━━━━━━━━━━━━━ 加按钮 ━━━━━━━━━━━━━━━━━━━━
    CGFloat addButtonWidth = self.addButtonWidth;
    CGFloat addButtonHeight = self.addButtonWidth;
    CGFloat addButtonCenterX = self.bounds.size.width - self.addButtonXOffset - self.addButtonWidth;
    CGFloat addButtonCenterY = self.rectangleY - self.addButtonYOffset - self.addButtonHeight;
    self.addButton.frame = CGRectMake(addButtonCenterX, addButtonCenterY, addButtonWidth, addButtonHeight);
    self.addButton.enabled = self.enable;
    
    // ━━━━━━━━━━━━━━━━━━━━ 触摸 View ━━━━━━━━━━━━━━━━━━━━
    self.touchView.frame = CGRectMake(0, self.rectangleY, self.bounds.size.width, self.rectangleHeight);
}

/// 设置那些与尺寸无关的变量的默认值
- (void)setupDefaultDataThatIsNotRelatedToFrame {
    _minValue = 40;
    _maxValue = 70;
    _lineCountToShow = 51;
    _centerHintLabel.text = @"已关机";
    
    _enable = YES;
    _isStop = NO;
}

/// 设置成用户自定义的值
- (void)setDataThatIsRelatedToFrameToCustomRatio {
    self.rectangleY = 139.0 * ApplyRatio(self.rectangleY_ratio);
    self.rectangleWidth = 325.0 * ApplyRatio(self.rectangleWidth_ratio);
    self.rectangleHeight = 27.5 * ApplyRatio(self.rectangleHeight_ratio);
    
    self.lineWidth = 3.0 * ApplyRatio(self.lineWidth_ratio);
    self.lineHeight = 27.5 * ApplyRatio(self.lineHeight_ratio);
    self.lineProtrudingUpHeight = 35.5 * ApplyRatio(self.lineProtrudingUpHeight_ratio);
    self.lineProtrudingDownHeight = 32.5 * ApplyRatio(self.lineProtrudingDownHeight_ratio);
    
    self.dotRadius = 4.0 * ApplyRatio(self.dotRadius_ratio);
    self.indicatorLabelOffset = 4.0 * ApplyRatio(self.indicatorLabelOffset_ratio);
    self.indicatorLabelFontSize = 14.0 * ApplyRatio(self.indicatorLabelFontSize_ratio);
    self.scaleLabelOffset = 8.5 * ApplyRatio(self.scaleLabelOffset_ratio);
    
    self.minusAddButtonSpaceToCenterX = 156.5 * ApplyRatio(self.minusAddButtonSpaceToCenterX_ratio);
    self.minusButtonWidth = 52.0 * ApplyRatio(self.minusButtonWidth_ratio);
    self.minusButtonHeight = 52.0 * ApplyRatio(self.minusButtonHeight_ratio);
    self.minusButtonXOffset = 10.0 * ApplyRatio(self.minusButtonXOffset_ratio);
    self.minusButtonYOffset = 15.0 * ApplyRatio(self.minusButtonYOffset_ratio);
    self.addButtonWidth = 52.0 * ApplyRatio(self.addButtonWidth_ratio);
    self.addButtonHeight = 52.0 * ApplyRatio(self.addButtonHeight_ratio);
    self.addButtonXOffset = 10.0 * ApplyRatio(self.addButtonXOffset_ratio);
    self.addButtonYOffset = 15.0 * ApplyRatio(self.addButtonXOffset_ratio);
    
    self.centerValueLabelFontSize = 56.0 * ApplyRatio(self.centerValueLabelFontSize_ratio);
    self.centerValueLabelYOffset = 70.0 * ApplyRatio(self.centerValueLabelYOffset_ratio);
    self.centerHintLabelFontSize = 30.0 * ApplyRatio(self.centerHintLabelFontSize_ratio);
    self.centerHintLabelYOffset = 70.0 * ApplyRatio(self.centerHintLabelYOffset_ratio);
    self.scaleLabelFontSize = 14.0 * ApplyRatio(self.scaleLabelFontSize_ratio);
    
    self.hotStatusButtonWidth = 17.0 * ApplyRatio(self.hotStatusButtonWidth_ratio);
    self.hotStatusButtonHeight = 22.0 * ApplyRatio(self.hotStatusButtonHeight_ratio);
    self.hotStatusButtonXOffset = 256.0 * ApplyRatio(self.hotStatusButtonXOffset_ratio);
    self.hotStatusButtonYOffset = 66.5 * ApplyRatio(self.hotStatusButtonYOffset_ratio);
    
    // 以下的数据是根据上面的数据推导出来的
    [self calculateDataAccordingDynamicValue];
}

- (void)configureDataToFitSize {
    //━━━━━━━━━━━━━━━━━━━━ 设置关键属性 ━━━━━━━━━━━━━━━━━━━━
    self.rectangleWidth = FitValueBaseOnWidth(self.rectangleWidth);
    self.rectangleHeight = FitValueBaseOnWidth(self.rectangleHeight);
    self.rectangleY = FitValueBaseOnWidth(self.rectangleY);
    
    self.lineWidth = FitValueBaseOnWidth(self.lineWidth);
    self.lineHeight = FitValueBaseOnWidth(self.lineHeight);
    self.lineProtrudingUpHeight = FitValueBaseOnWidth(self.lineProtrudingUpHeight);
    self.lineProtrudingDownHeight = FitValueBaseOnWidth(self.lineProtrudingDownHeight);
    
    self.scaleLabelOffset = FitValueBaseOnWidth(self.scaleLabelOffset);
    self.scaleLabelFontSize = FitValueBaseOnWidth(self.scaleLabelFontSize);
    
    self.dotRadius = FitValueBaseOnWidth(self.dotRadius);
    self.indicatorLabelFontSize = FitValueBaseOnWidth(self.indicatorLabelFontSize);
    self.indicatorLabelOffset = FitValueBaseOnWidth(self.indicatorLabelOffset);
    
    self.centerValueLabelFontSize = FitValueBaseOnWidth(self.centerValueLabelFontSize);
    self.centerValueLabelYOffset = FitValueBaseOnWidth(self.centerValueLabelYOffset);
    self.centerHintLabelFontSize = FitValueBaseOnWidth(self.centerHintLabelFontSize);
    self.centerHintLabelYOffset = FitValueBaseOnWidth(self.centerHintLabelYOffset);
    
    self.hotStatusButtonWidth = FitValueBaseOnWidth(self.hotStatusButtonWidth);
    self.hotStatusButtonHeight = FitValueBaseOnWidth(self.hotStatusButtonHeight);
    self.hotStatusButtonXOffset = FitValueBaseOnWidth(self.hotStatusButtonXOffset);
    self.hotStatusButtonYOffset = FitValueBaseOnWidth(self.hotStatusButtonYOffset);
    
    self.minusButtonWidth = FitValueBaseOnWidth(self.minusButtonWidth);
    self.minusButtonHeight = FitValueBaseOnWidth(self.minusButtonHeight);
    self.minusButtonXOffset = FitValueBaseOnWidth(self.minusButtonXOffset);
    self.minusButtonYOffset = FitValueBaseOnWidth(self.minusButtonYOffset);
    
    self.addButtonWidth = FitValueBaseOnWidth(self.addButtonWidth);
    self.addButtonHeight = FitValueBaseOnWidth(self.addButtonHeight);
    self.addButtonXOffset = FitValueBaseOnWidth(self.addButtonXOffset);
    self.addButtonYOffset = FitValueBaseOnWidth(self.addButtonYOffset);
    
    // 以下的数据是根据上面的数据推导出来的
    [self calculateDataAccordingDynamicValue];
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
    CAGradientLayer *layer2_GradientLayer =  [CAGradientLayer layer];
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

- (void)shineWithTimeInterval:(NSTimeInterval)timeInterval pauseDuration:(NSTimeInterval)pauseDuration finalValue:(NSUInteger)finalValue finishBlock:(void(^)())finishBlock {

    [self.queue cancelAllOperations];
    
    if (!self.enable) {
        return;
    }
    
    //━━━━━━━━━━━━━━━━━━━━ 前进 0 ~ 1 ━━━━━━━━━━━━━━━━━━━━
    
    NSMutableArray *operationArrayM = [self operationFromValue:(self.minValue - 1) toValue:self.maxValue timeInterval:timeInterval isShowAccessoryWhenFinished:NO];
    
    //━━━━━━━━━━━━━━━━━━━━ 暂停 ━━━━━━━━━━━━━━━━━━━━
    
    NSOperation *oprationPause = [NSBlockOperation blockOperationWithBlock:^{
        self.animationTimeInterval = timeInterval;
        [NSThread sleepForTimeInterval:pauseDuration];
    }];
    NSOperation *lastOperationGo = operationArrayM.lastObject;
    if (lastOperationGo) {
        [oprationPause addDependency:lastOperationGo];
    }
    
    [operationArrayM addObject:oprationPause];
    
    //━━━━━━━━━━━━━━━━━━━━ 后退 1 ~ 0 ━━━━━━━━━━━━━━━━━━━━
    
    NSMutableArray *operationGoBackArrayM = [self operationFromValue:self.maxValue toValue:(self.minValue - 1) timeInterval:timeInterval isShowAccessoryWhenFinished:NO];
    NSOperation *firstGoBackOperation = operationGoBackArrayM.firstObject;
    [firstGoBackOperation addDependency:oprationPause];
    
    [operationArrayM addObjectsFromArray:operationGoBackArrayM];
    
    //━━━━━━━━━━━━━━━━━━━━ 前进 0 ~ 目标值 ━━━━━━━━━━━━━━━━━━━━
    
    NSMutableArray *operationGoToFinalValueArrayM = [self operationFromValue:(self.minValue - 1) toValue:finalValue timeInterval:timeInterval isShowAccessoryWhenFinished:YES];
    NSOperation *firstOperationGoToFinalValue = operationGoToFinalValueArrayM.firstObject;
    NSOperation *lastOperationGoBack = operationArrayM.lastObject;
    
    if (lastOperationGoBack) {
        [firstOperationGoToFinalValue addDependency:lastOperationGoBack];
    }
    [operationArrayM addObjectsFromArray:operationGoToFinalValueArrayM];
    
    //━━━━━━━━━━━━━━━━━━━━ 完成回调 ━━━━━━━━━━━━━━━━━━━━
    
    NSOperation *oprationFinishBlock = [NSBlockOperation blockOperationWithBlock:^{
        if (finishBlock) {
            finishBlock();
        }
    }];
    NSOperation *lastOperation2 = operationArrayM.lastObject;
    if (lastOperation2) {
        [oprationFinishBlock addDependency:lastOperation2];
    }
    
    [operationArrayM addObject:oprationFinishBlock];
    
    //━━━━━━━━━━━━━━━━━━━━ 将所有任务添加到队列 ━━━━━━━━━━━━━━━━━━━━
    
    [operationArrayM enumerateObjectsUsingBlock:^(NSOperation * _Nonnull operation, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.queue addOperation:operation];
    }];
}

- (NSMutableArray *)operationFromValue:(CGFloat)fromValue toValue:(CGFloat)toValue timeInterval:(CGFloat)timeInterval isShowAccessoryWhenFinished:(BOOL)isShowAccessory {
    if (self.isStop) {
        return [NSMutableArray array];
    }
    NSInteger fromLineNumber = [self lineNumberWithIndicatorValue:fromValue];
    NSInteger toLineNumber = [self lineNumberWithIndicatorValue:toValue];

    NSMutableArray *oprationArrayM = [NSMutableArray array];
    
    int minus = (int)(toLineNumber - fromLineNumber);

    NSOperation *lastOperation = nil;
    
    for (int i = 0; i <= abs(minus); i++) {
        
        int nextLineNumber = (int)fromLineNumber + (minus > 0 ? i : -i);
        
        NSBlockOperation *operation_AddNewLayer2 = [NSBlockOperation blockOperationWithBlock:^{
            self.animationTimeInterval = timeInterval;
            [NSThread sleepForTimeInterval:timeInterval];
            NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
            [mainQueue addOperationWithBlock:^{
                // 因为前面有不可暂停的延时，所以这里要加一个强行停止的开关
                if (!self.isStop) {
                    //YYLog(@"正在滚动");
                    self.layer2.mask = [self maskLayerForLayer2WithLineNumber:nextLineNumber];
                } else {
                    //YYLog(@"遇到锁，取消执行");
                }
            }];
        }];
        if (lastOperation) {
            // 依赖前一个任务
            [operation_AddNewLayer2 addDependency:lastOperation];
        }
        [oprationArrayM addObject:operation_AddNewLayer2];
        
        lastOperation = operation_AddNewLayer2;
    }
    
    if (isShowAccessory) {
        _indicatorValue = toValue;
        NSBlockOperation *operation_ShowAccessory = [NSBlockOperation blockOperationWithBlock:^{
            NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
            [mainQueue addOperationWithBlock:^{
                [self showAccessoryOnLineWitLineNumber:toLineNumber];
            }];
        }];
        if (lastOperation) {
            // 依赖前一个任务
            [operation_ShowAccessory addDependency:lastOperation];
        }
        [oprationArrayM addObject:operation_ShowAccessory];
    }

    return oprationArrayM;
}

- (void)changeIndicatorFromValue:(CGFloat)fromValue toValue:(CGFloat)toValue isShowAccessoryWhenFinished:(BOOL)isShowAccessory duration:(CGFloat)duration {
    
    NSUInteger fromLineNumber = [self lineNumberWithIndicatorValue:fromValue];
    NSUInteger toLineNumber = [self lineNumberWithIndicatorValue:toValue];
    
    int minus = (int)(toLineNumber - fromLineNumber);
    CGFloat durationTemp = duration / (abs(minus) + 1);
    
    NSOperation *lastOperation = nil;
    
    for (int i = 0; i <= abs(minus); i++) {
        
        int nextLineNumber = (int)fromLineNumber + (minus > 0 ? i : -i);
        
        NSBlockOperation *operation_AddNewLayer2 = [NSBlockOperation blockOperationWithBlock:^{
            self.animationTimeInterval = durationTemp;
            [NSThread sleepForTimeInterval:durationTemp];
            NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
            [mainQueue addOperationWithBlock:^{
                // 因为前面有不可暂停的延时，所以这里要加一个强行停止的开关
                // 这个方案有误差，最好的方案应该用信号量
                if (!self.isStop) {
                    self.layer2.mask = [self maskLayerForLayer2WithLineNumber:nextLineNumber];
                }
            }];
        }];
        if (lastOperation) {
            [operation_AddNewLayer2 addDependency:lastOperation];
        }
        [self.queue addOperation:operation_AddNewLayer2];
        
        lastOperation = operation_AddNewLayer2;
    }
    
    if (isShowAccessory) {
        _indicatorValue = toValue;
        NSBlockOperation *operation_ShowAccessory = [NSBlockOperation blockOperationWithBlock:^{
            NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
            [mainQueue addOperationWithBlock:^{
                [self showAccessoryOnLineWitLineNumber:toLineNumber];
            }];
        }];
        if (lastOperation) {
            [operation_ShowAccessory addDependency:lastOperation];
        }
        [self.queue addOperation:operation_ShowAccessory];
    }
}

- (void)calculateDataAccordingDynamicValue {
    _startX = (self.bounds.size.width - self.rectangleWidth) / 2;
    _xEveryLine = self.rectangleWidth / (self.lineCountToShow - 1);
}

- (NSArray *)calculateFourKeyPointForRectangleWithStartPoint:(CGPoint)startPoint moveX:(CGFloat)moveX lineWidth:(CGFloat)lineWidth lineHeigth:(CGFloat)lineHeight isProtrudingUp:(BOOL)isProtrudingUp isProtrudingDown:(BOOL)isProtrudingDown {
    
    CGFloat topLeftPointX = moveX -  lineWidth / 2.0;
    CGFloat topLeftPointY = startPoint.y;
    CGFloat YDistance = self.lineHeight;
    
    if (isProtrudingUp) {
        topLeftPointY = topLeftPointY - (lineHeight - self.lineHeight);
        YDistance += lineHeight - self.lineHeight;
    }
    if (isProtrudingDown) {
        YDistance += lineHeight - self.lineHeight;
    }
    
    NSValue *topLeftPointValue = [NSValue valueWithCGPoint:CGPointMake(topLeftPointX, topLeftPointY)];
    
    CGFloat topRightPointX = topLeftPointX + lineWidth;
    CGFloat topRightPointY = topLeftPointY;
    NSValue *topRightPointValue = [NSValue valueWithCGPoint:CGPointMake(topRightPointX, topRightPointY)];
    
    CGFloat bottomRightPointX = topRightPointX;
    CGFloat bottomRightPointY = topLeftPointY + YDistance;
    NSValue *bottomRightPointValue = [NSValue valueWithCGPoint:CGPointMake(bottomRightPointX, bottomRightPointY)];
    
    CGFloat bottomLeftPointX = bottomRightPointX - lineWidth;
    CGFloat bottomLeftPointY = bottomRightPointY;
    NSValue *bottomLeftPointValue = [NSValue valueWithCGPoint:CGPointMake(bottomLeftPointX, bottomLeftPointY)];
    
    NSArray *pointArray = @[topLeftPointValue, topRightPointValue, bottomRightPointValue, bottomLeftPointValue];
    
    return pointArray;
}

- (void)showAccessoryOnLineWitLineNumber:(NSInteger)lineNumber {
    NSInteger minLineNumber = [self lineNumberWithIndicatorValue:self.minValue];
    NSInteger maxLineNumber = [self lineNumberWithIndicatorValue:self.maxValue];
    if (lineNumber < minLineNumber || lineNumber > maxLineNumber) {
        return;
    }
    
    CAShapeLayer *maskLayerForLayer2 = (CAShapeLayer *)self.layer2.mask;
    //━━━━━━━━━━━━━━━━━━━━ 添加圆点和文字 ━━━━━━━━━━━━━━━━━━━━
    // 1.添加圆点
    UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:maskLayerForLayer2.path];
    
    CGFloat x = self.startX + lineNumber * self.xEveryLine;
    
    CGFloat redDotCenterX = x;
    CGFloat redDotCenterY = self.rectangleY - (self.lineProtrudingUpHeight - self.lineHeight);
    
    CGPoint dotCircleCenter = CGPointMake(redDotCenterX, redDotCenterY);
    
    UIBezierPath *dotPath = [UIBezierPath bezierPathWithArcCenter:dotCircleCenter radius:self.dotRadius startAngle:AngleToRadian(0) endAngle:AngleToRadian(360) clockwise:YES];
    [path appendPath:dotPath];
    maskLayerForLayer2.path = path.CGPath;
    self.layer2.mask = maskLayerForLayer2;
    
    // 2.添加文字
    UILabel *indicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 32, 20)];
    CGFloat indicatorLabelHeight = 20 / 13 * self.indicatorLabelFontSize;
    
    indicatorLabel.font = [UIFont systemFontOfSize:self.indicatorLabelFontSize];
    indicatorLabel.textAlignment = NSTextAlignmentCenter;
    indicatorLabel.text = [NSString stringWithFormat:@"%@°C", @(self.indicatorValue)];
    indicatorLabel.center = CGPointMake(150, 150);
    [indicatorLabel sizeToFit];
    // 这句话只是为了持有 indicatorLabel，防止因它释放而导致 indicatorLabel 没有机会往 layer 上绘制文字，从而导致 indicatorLabel.layer 是没有内容的，透明的遮罩是不能显示出遮罩盖住的内容的
    [self addSubview:indicatorLabel];
    [maskLayerForLayer2 addSublayer:indicatorLabel.layer];
    
    CGFloat indicatorLabelCenterX = redDotCenterX;
    
    CGFloat indicatorLabelCenterY = redDotCenterY - self.dotRadius - self.indicatorLabelOffset - indicatorLabelHeight / 2;
    
    indicatorLabel.center = CGPointMake(indicatorLabelCenterX, indicatorLabelCenterY);
}

- (NSInteger)lineNumberWithIndicatorValue:(CGFloat)indicatorValue {
    
    if (indicatorValue < self.minValue) {
        return -1;
    }
    
    if (indicatorValue > self.maxValue) {
        return self.lineCountToShow - 1;
    }
    
    CGFloat valueEveryLine = (self.maxValue - self.minValue) / (CGFloat)(self.lineCountToShow - 1);
    // 商
    CGFloat quotientFloat = (CGFloat)(indicatorValue - self.minValue) / valueEveryLine;
    // 余数
    CGFloat remainder = quotientFloat - (int)quotientFloat;
    NSInteger numberReturn = remainder > (valueEveryLine / 2) ? ceil(quotientFloat) : floorf(quotientFloat);
    return numberReturn;
}

/// layer1 的 maskLayer
- (CAShapeLayer *)maskLayerForLayer1 {

    CAShapeLayer * maskLayer= [CAShapeLayer layer];
    maskLayer.frame = CGRectMake(0, 0, self.layer1.bounds.size.width, self.layer1.bounds.size.height);
    UIBezierPath *basePath = [UIBezierPath bezierPath];
    
    for (int i = 0; i < self.lineCountToShow; i++) {
        
        CGFloat moveX = self.startX + i * self.xEveryLine;
        CGPoint startPoint = CGPointMake(self.startX, self.rectangleY);
        
        BOOL isScaleLine = NO;
        CGFloat lineWidth = self.lineWidth;
        CGFloat lineHeight = self.lineHeight;
        NSNumber *scaleValueNumber = nil;
        
        for (NSNumber *scaleValue in self.valueToShowArray) {
            NSUInteger lineNumber = [self lineNumberWithIndicatorValue:scaleValue.floatValue];
            if (i == lineNumber) {
                isScaleLine = YES;
                lineHeight = self.lineProtrudingDownHeight;
                scaleValueNumber = scaleValue;
                break;
            }
        }
        
        NSArray *rectanglePointArray = [self calculateFourKeyPointForRectangleWithStartPoint:startPoint moveX:moveX lineWidth:lineWidth lineHeigth:lineHeight isProtrudingUp:NO isProtrudingDown:isScaleLine];
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
        
        [basePath appendPath:path];
        
        if (isScaleLine) {
            // 添加刻度文字
            UILabel *scaleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 32, 20)];
            CGFloat scaleLabelHeight = 20 / 13 * self.scaleLabelFontSize;
            
            scaleLabel.font = [UIFont systemFontOfSize:self.scaleLabelFontSize];
            scaleLabel.textAlignment = NSTextAlignmentCenter;
            scaleLabel.text = [NSString stringWithFormat:@"%@℃", @(scaleValueNumber.integerValue)];
            scaleLabel.center = CGPointMake(150, 150);
            [scaleLabel sizeToFit];
            // 这句话只是为了持有 indicatorLabel，防止因它释放而导致 indicatorLabel 没有机会往 layer 上绘制文字，从而导致 indicatorLabel.layer 是没有内容的，透明的遮罩是不能显示出遮罩盖住的内容的
            [self addSubview:scaleLabel];
            [maskLayer addSublayer:scaleLabel.layer]; // 添加文字的 layer
            
            CGFloat scaleLabelCenterX = moveX;
            
            CGFloat scaleLabelCenterY = startPoint.y + lineHeight + self.scaleLabelOffset + scaleLabelHeight / 2;
            
            scaleLabel.center = CGPointMake(scaleLabelCenterX, scaleLabelCenterY);
        }
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
        
        CGFloat moveX = self.startX + i * self.xEveryLine;
        CGPoint startPoint = CGPointMake(self.startX, self.rectangleY);
        
        BOOL isUp = NO;
        BOOL isDown = NO;
        CGFloat lineWidth = self.lineWidth;
        CGFloat lineHeight = self.lineHeight;
        
        for (NSNumber *scaleValueNumber in self.valueToShowArray) {
            NSUInteger lineNumber = [self lineNumberWithIndicatorValue:scaleValueNumber.floatValue];
            if (i == lineNumber) {
                isDown = YES;
                lineHeight = self.lineProtrudingDownHeight;
                break;
            }
        }

        if (i == lineNumber) {
            isUp = YES;
            lineHeight = self.lineProtrudingUpHeight;
        }
        
        NSArray *rectanglePointArray = [self calculateFourKeyPointForRectangleWithStartPoint:startPoint moveX:moveX lineWidth:lineWidth lineHeigth:lineHeight isProtrudingUp:isUp isProtrudingDown:isDown];
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
        
        [basePath appendPath:path];
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
    //YYLog(@"加锁");
    self.isStop = YES;
    //YYLog(@"开始清除");
    [self.queue cancelAllOperations];
    self.layer2.mask = [self maskLayerForLayer2WithLineNumber:-1];
    _indicatorValue = self.minValue - 1;
    //YYLog(@"清除完成");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.animationTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //YYLog(@"打开锁")
        self.isStop = NO;
    });
}

- (void)setIndicatorValue:(NSInteger)indicatorValue animated:(BOOL)animated {
    if (!self.enable) {
        return;
    }
    
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
}

#pragma mark - ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ Getter and Setter ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

- (NSOperationQueue *)queue {
    if (_queue == nil) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
    }
    return _queue;
}

- (void)setIndicatorValue:(NSInteger)indicatorValue {
    
    if (!self.enable) {
        return;
    }
    
    if (indicatorValue > self.maxValue) {
        indicatorValue = self.maxValue;
    }
    
    NSUInteger oldIndicatorValue = _indicatorValue;
    
    _indicatorValue = indicatorValue;
    
    NSInteger fromLineNumber = [self lineNumberWithIndicatorValue:oldIndicatorValue];
    NSInteger toLineNumber = [self lineNumberWithIndicatorValue:indicatorValue];
    
    int minus = (int)(toLineNumber - fromLineNumber);
    CGFloat durationTemp = abs(minus) * 0.02;
    
    //YYLog(@"成功修改 %ld", indicatorValue);
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

- (void)setMinValue:(NSInteger)minValue {
    _minValue = minValue;
    
    [self.layer1 removeFromSuperlayer];
    [self.layer2 removeFromSuperlayer];
    [self addLayer1];
    [self addLayer2];
}

- (void)setMaxValue:(NSInteger)maxValue {
    _maxValue = maxValue;
    
    [self.layer1 removeFromSuperlayer];
    [self.layer2 removeFromSuperlayer];
    [self addLayer1];
    [self addLayer2];
}

- (void)setValueToShowArray:(NSArray<NSNumber *> *)valueToShowArray {
    _valueToShowArray = valueToShowArray;
    
    [self.layer1 removeFromSuperlayer];
    [self.layer2 removeFromSuperlayer];
    [self addLayer1];
    [self addLayer2];
}

@end
