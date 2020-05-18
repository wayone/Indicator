//
//  ViewController.m
//  Indicator
//
//  Created by lwx on 2017/6/28.
//  Copyright © 2017年 MyCompany. All rights reserved.
//

#import "ViewController.h"
#import "RectangleIndicatorView.h"
#import "CircleIndicatorView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet CircleIndicatorView *circleIndicatorView;
@property (weak, nonatomic) IBOutlet RectangleIndicatorView *rectangleIndicatorView;

- (IBAction)circleIndicatorShine;
- (IBAction)rectangleIndicatorShine;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.rectangleIndicatorView.minValue = 40;
    self.rectangleIndicatorView.maxValue = 80;
    self.rectangleIndicatorView.valueToShowArray = @[@40, @50, @60, @70, @80];
    self.rectangleIndicatorView.indicatorValue = 50;
    __weak typeof(self) weakSelf = self;
    self.rectangleIndicatorView.minusBlock = ^{
        NSLog(@"点击了 -");
        weakSelf.rectangleIndicatorView.indicatorValue -= 1;
    };
    self.rectangleIndicatorView.addBlock = ^{
        NSLog(@"点击了 +");
        weakSelf.rectangleIndicatorView.indicatorValue += 1;
    };
    self.rectangleIndicatorView.touchEndBlock = ^(NSInteger indicatorValue){
        NSLog(@"触摸结束，%ld", indicatorValue);
    };
    
    self.circleIndicatorView.minValue = 40;
    self.circleIndicatorView.maxValue = 80;
    self.circleIndicatorView.innerAnnulusValueToShowArray = @[@40, @50, @60, @70, @80];
    self.circleIndicatorView.indicatorValue = 60;
    self.circleIndicatorView.minusBlock = ^{
        NSLog(@"点击了 -");
        weakSelf.circleIndicatorView.indicatorValue -= 1;
    };
    self.circleIndicatorView.addBlock = ^{
        NSLog(@"点击了 +");
        weakSelf.circleIndicatorView.indicatorValue += 1;
    };
    self.circleIndicatorView.touchEndBlock = ^(NSInteger indicatorValue){
        NSLog(@"触摸结束，%ld", indicatorValue);
    };
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self shineIndicatorView];
}

- (void)shineIndicatorView {
    [self.circleIndicatorView shineWithTimeInterval:0.01 pauseDuration:0 finalValue:70 finishBlock:^{
        //NSLog(@"---------- 执行完毕");
    }];
}

- (IBAction)circleIndicatorShine {
    [self.circleIndicatorView shineWithTimeInterval:0.01 pauseDuration:0 finalValue:70 finishBlock:^{
        //NSLog(@"---------- 执行完毕");
    }];
}

- (IBAction)rectangleIndicatorShine {
    [self.rectangleIndicatorView shineWithTimeInterval:0.01 pauseDuration:0 finalValue:72 finishBlock:^{
        //NSLog(@"---------- 执行完毕");
    }];
}

@end
