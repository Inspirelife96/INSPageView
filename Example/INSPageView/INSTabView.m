//
//  INSTabView.m
//  INSTabPageViewController
//
//  Created by XueFeng Chen on 2021/11/29.
//

#import "INSTabView.h"

@interface INSTabView ()

@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) UIView *seperatorView;

@property (nonatomic, strong) UIStackView *buttonsContainerStackView;
@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, strong) NSMutableDictionary *widths;

@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, strong) UIColor *highlightedColor;

@property (nonatomic, assign) NSInteger currentIndex;

@end

@implementation INSTabView

- (UIStackView *)buttonsContainerStackView {
    if (!_buttonsContainerStackView) {
        _buttonsContainerStackView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
        _buttonsContainerStackView.axis = UILayoutConstraintAxisHorizontal;
        _buttonsContainerStackView.distribution = UIStackViewDistributionFillEqually;
        _buttonsContainerStackView.alignment = UIStackViewAlignmentFill;
    }
    
    return _buttonsContainerStackView;
}

- (UIView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _indicatorView.backgroundColor = self.highlightedColor;
        _indicatorView.layer.cornerRadius = 1;
        _indicatorView.layer.masksToBounds = YES;
    }
    
    return _indicatorView;
}

- (UIView *)seperatorView {
    if (!_seperatorView) {
        _seperatorView =  [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds) - 0.5, CGRectGetWidth(self.bounds), 0.5)];
        _seperatorView.backgroundColor = [UIColor separatorColor];
    }
    
    return _seperatorView;
}


- (UIColor *)normalColor {
    if (!_normalColor) {
        _normalColor = [UIColor labelColor];
    }
    
    return _normalColor;
}

- (UIColor *)highlightedColor {
    if (!_highlightedColor) {
        _highlightedColor = [UIColor linkColor];
    }
    
    return _highlightedColor;
}

- (instancetype)initWithFrame:(CGRect)frame tabViewDataSource:(id<INSTabViewDataSource>)tabViewDataSource INSTabViewDelegate:(id<INSTabViewDelegate>)tabViewDelegate {
    if (self = [super initWithFrame:frame]) {
        self.tabViewDataSource = tabViewDataSource;
        self.tabViewDelegate = tabViewDelegate;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor systemBackgroundColor];
        self.widths = [NSMutableDictionary dictionary];
        
        [self buildUI];
    }
    
    return self;
}

//- (instancetype)initWithFrame:(CGRect)frame {
//    if (self = [super initWithFrame:frame]) {
//        self.clipsToBounds = YES;
//        self.backgroundColor = [UIColor systemBackgroundColor];
//        self.widths = [NSMutableDictionary dictionary];
//
//        [self buildUI];
//
//
//        return self;
//    }
//    return nil;
//}

- (UIButton *)createTabButton {
    UIButton *tabButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tabButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [tabButton setTitleColor:self.normalColor forState:UIControlStateNormal];
    [tabButton setTitleColor:self.highlightedColor forState:UIControlStateDisabled];
    [tabButton addTarget:self action:@selector(clickTabButton:) forControlEvents:UIControlEventTouchUpInside];
    return tabButton;
}

- (void)buildUI {
    [self addSubview:self.buttonsContainerStackView];
    
    NSInteger count = [self.tabViewDataSource numberOfTabsForTabView:self];
    CGFloat buttonWidth = CGRectGetWidth(self.bounds) / count;
    
    NSMutableArray *tabButtonArray = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger index = 0; index < count; index++) {
        UIButton *tabButton = [self createTabButton];
        tabButton.tag = index;
        NSString *title = [self.tabViewDataSource tabView:self tabTitleForIndex:index];
        
        [tabButton setTitle:title forState:UIControlStateNormal];
        [tabButton setTitle:title forState:UIControlStateDisabled];
        
        [self.buttonsContainerStackView addArrangedSubview:tabButton];
//        [tabButton mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.bottom.equalTo(self);
//            make.left.equalTo(self).with.offset(index * buttonWidth);
//            make.width.mas_equalTo(buttonWidth);
//        }];
        
        NSInteger width = [tabButton.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT, self.frame.size.width)].width;

        [tabButtonArray addObject:tabButton];
        [self.widths setObject:@(width) forKey:@(index)];
    }
    
    [self addSubview:self.indicatorView];
    self.indicatorView.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - 8, buttonWidth, 2);
    
    [self addSubview:self.seperatorView];
//    [self.seperatorView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.bottom.equalTo(self);
//        make.height.mas_equalTo(0.5f);
//    }];
    
    self.buttons = tabButtonArray;
    
    if (self.buttons.count < 1) {
        return;
    }
    
    [self tabDidScrollToIndex:self.currentIndex];
}

- (IBAction)clickTabButton:(UIButton *)sender {
    if ([self.tabViewDelegate respondsToSelector:@selector(tabView:didSelectIndex:)]) {
        [self.tabViewDelegate tabView:self didSelectIndex:sender.tag];
    }
}

- (void)tabDidScrollToIndex:(NSInteger)index {
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *tabButton, NSUInteger idx, BOOL *stop) {
        tabButton.enabled = YES;
    }];
    
    _currentIndex = index;
    UIButton *currentTabButton = [self buttonAtIndex:self.currentIndex];
    currentTabButton.enabled = NO;
    
    CGFloat percent = (CGFloat)index / MAX(1, self.buttons.count - 1);
    [self updateIndicatorFrameWithPercent:percent];
}

- (void)updateIndicatorFrameWithPercent:(CGFloat)percent {
    if (self.buttons == 0) {
        return;
    }
    NSInteger index = (NSInteger)((self.buttons.count - 1) * percent);
    
    CGFloat averageWidth = CGRectGetWidth(self.frame) / self.buttons.count;
    CGFloat preWidth = [self.widths[@(index)] floatValue];
    if (preWidth == 0) {
        preWidth = averageWidth;
    }
    
    if (index == self.buttons.count - 1) {
        CGRect rect = _indicatorView.frame;
        rect.size.width = preWidth;
        rect.origin.x = CGRectGetWidth(self.bounds) - averageWidth / 2.0f - preWidth / 2.0f;
        _indicatorView.frame = rect;
        return;
    }
    
    CGFloat nextWidth = [self.widths[@(index+1)] floatValue];
    if (nextWidth == 0) {
        nextWidth = averageWidth;
    }
    
    CGFloat prePercent = (CGFloat)index / MAX(1, self.buttons.count - 1);
    CGFloat nextPercent = (CGFloat)(index + 1) / MAX(1, self.buttons.count - 1);
    
    CGFloat width = preWidth + (percent - prePercent) / (nextPercent - prePercent) * (nextWidth - preWidth);
    CGFloat centerX = averageWidth * (0.5 + (self.buttons.count - 1) * percent);
    
    CGRect rect = _indicatorView.frame;
    rect.origin.x = centerX - width / 2.0f;
    rect.size.width = width;
    _indicatorView.frame = rect;
}

- (UIButton *)buttonAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.buttons.count) {
        return nil;
    }
    return self.buttons[index];
}

- (void)pageViewheaderViewVerticalScrolledContentPercentY:(CGFloat)contentPercentY {
    
}

- (void)tabScrollXPercent:(CGFloat)percent {
    percent = MAX(0, percent);
    percent = MIN(1, percent);
    [self updateIndicatorFrameWithPercent:percent];
}

- (void)scrollViewHorizontalScrolledContentOffsetX:(CGFloat)contentOffsetX {
    NSInteger count = [self.tabViewDataSource numberOfTabsForTabView:self];
    CGFloat percent = contentOffsetX / (self.bounds.size.width * (count - 1));
    [self tabScrollXPercent:percent];
}

- (void)scrollViewWillScrollFromIndex:(NSInteger)index {
    
}

- (void)scrollViewDidScrollToIndex:(NSInteger)index {
    [self tabDidScrollToIndex:index];
}

@end
