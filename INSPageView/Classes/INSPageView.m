//
//  INSPageView.m
//  INSTabPageViewController
//
//  Created by XueFeng Chen on 2021/12/2.
//

#import "INSPageView.h"

@interface INSPageView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView; // 滚动视图，分页显示viewControllers的视图内容
@property (nonatomic, strong) UIStackView *headerContainerView; // 包括头部视图和Tab视图
@property (nonatomic, strong) UIView *headerView; //头部视图，高度可能拉伸
@property (nonatomic, strong) UIView<INSTabViewProtocol> *tabView; // Tab视图，切换Page页面

@property (nonatomic, strong) NSArray<UIViewController<INSPageContentViewControllerProtocol> *> *viewControllers;

@property (nonatomic, assign, readwrite) NSInteger currentIndex;

@property (nonatomic, assign) CGFloat headerContainerViewHeight;
@property (nonatomic, assign) CGFloat headerViewHeight;
@property (nonatomic, assign) CGFloat tabViewHeight;
@property (nonatomic, assign) CGFloat navigationBarHeight;
@property (nonatomic, assign) CGFloat minHeaderViewContainerHeight;
@property (nonatomic, assign) CGFloat minHeaderContainerViewFrameYPos;

@property (nonatomic, assign) CGFloat contentOffsetY;

@end

@implementation INSPageView

- (instancetype)initWithFrame:(CGRect)frame pageViewDataSource:(id<INSPageViewDataSource>)pageViewDataSource pageViewDelegate:(id<INSPageViewDelegate>)pageViewDelegate pageViewController:(UIViewController *)pageViewController {
    if (self = [super initWithFrame:frame]) {
        _pageViewDataSource = pageViewDataSource;
        _pageViewDelegate = pageViewDelegate;
        _pageViewController = pageViewController;
        
        [self _initializeNonLazyLoadProperties];

        [self _layoutSubViews];
        
        [self _layoutContentViews];
        
        [self _addCurrentContentView];
        
        [self _enableCurrentScrollViewScrollToTop:YES];
    }

    return self;
}

- (void)dealloc {
    for (UIViewController<INSPageContentViewControllerProtocol> *viewController in self.viewControllers) {
        @try {
            viewController.pageViewController = nil;
            [viewController.pageContentScrollView removeObserver:self forKeyPath:@"contentOffset"];
        } @catch (NSException *exception) {
            
        } @finally {
            
        }
    }
}

#pragma mark KVO

// 垂直滚动处理
// 我们唯一需要处理的就是随着滚动调整HeaderContainerView的frame，让他看起来也跟着一起滚动

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // 仅对@"contentOffset"做处理
    if (![keyPath isEqualToString:@"contentOffset"]) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    // 获取当前相应垂直滚动的ScrollView
    UIViewController<INSPageContentViewControllerProtocol> *viewController = self.viewControllers[self.currentIndex];
    UIScrollView *scrollView = viewController.pageContentScrollView;
    
    // 如果不是一致的，那么直接返回
    if (scrollView != object) {
        return;
    }
    
    // 屏幕向上滚动，scrollView.contentOffset.y会变大，所以向上滚动 distanceY < 0
    CGFloat distanceY = self.contentOffsetY - scrollView.contentOffset.y;
    self.contentOffsetY = scrollView.contentOffset.y;
    
    // 往下滚动，且还没有到TabView需要往下滚动的地步
    if (distanceY > 0 && self.contentOffsetY > -CGRectGetMaxY(self.headerContainerView.frame)) {
        return;
    }
    
    CGRect headContainerViewRect = self.headerContainerView.frame;
    if (self.contentOffsetY > -self.headerContainerViewHeight) {
        // 保证高度不变
        headContainerViewRect.size.height = self.headerContainerViewHeight;
        // Y坐标根据滚动的差值进行变化
        headContainerViewRect.origin.y += distanceY;
        // 保证Y值不 > 0
        headContainerViewRect.origin.y = MIN(CGRectGetMinY(headContainerViewRect), 0);
        // 保证TabView不会被隐藏
        headContainerViewRect.origin.y = MAX(CGRectGetMinY(headContainerViewRect), self.minHeaderContainerViewFrameYPos);
    } else {
        headContainerViewRect.origin.y = 0;
        headContainerViewRect.size.height =  -scrollView.contentOffset.y;
    }
    
    self.headerContainerView.frame = headContainerViewRect;
    
    // 这个百分比是指headerView被隐藏的百分比
    CGFloat percent = 1;
    if (self.minHeaderContainerViewFrameYPos != 0) {
        percent = MAX(0, CGRectGetMinY(headContainerViewRect) / self.minHeaderContainerViewFrameYPos);
        percent = MIN(1, percent);
    }
    
    // 默认的TabView该API是空函数
    // 自定义TabView时，在这种情况下，如果需要对TabView进行处理，例如随着HeaderView的隐藏进行变色等。
    if ([self.tabView respondsToSelector:@selector(pageViewheaderViewVerticalScrolledContentPercentY:)]) {
        [self.tabView pageViewheaderViewVerticalScrolledContentPercentY:percent];
    }
    
    // 调用者可以通过代理，进行垂直滚动时的额外处理
    // 这个API可以进行Navigation透明度的调整
    if ([self.pageViewDelegate respondsToSelector:@selector(pageView:headerViewVerticalScrolledContentPercentY:)]) {
        [self.pageViewDelegate pageView:self headerViewVerticalScrolledContentPercentY:percent];
    }
}

#pragma mark - ScrollView Delegate

// 开始滚动时，不知道是往左还是往右，所以，把当前页面的左右页面都准备好
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self _enableCurrentScrollViewScrollToTop:NO];
    
    [self _viewControllersFitToScrollToIndex:self.currentIndex - 1];
    [self _viewControllersFitToScrollToIndex:self.currentIndex + 1];
    
    if ([self.pageViewDelegate respondsToSelector:@selector(pageView:scrollViewWillScrollFromIndex:)]) {
        [self.pageViewDelegate pageView:self scrollViewWillScrollFromIndex:self.currentIndex];
    }
    
    if ([self.tabView respondsToSelector:@selector(scrollViewWillScrollFromIndex:)]) {
        [self.tabView scrollViewWillScrollFromIndex:self.currentIndex];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self _addCurrentContentView];
    
    if ([self.pageViewDelegate respondsToSelector:@selector(pageView:scrollViewHorizontalScrolledContentOffsetX:)]) {
        [self.pageViewDelegate pageView:self scrollViewHorizontalScrolledContentOffsetX:scrollView.contentOffset.x];
    }
    
    if ([self.tabView respondsToSelector:@selector(scrollViewHorizontalScrolledContentOffsetX:)]) {
        [self.tabView scrollViewHorizontalScrolledContentOffsetX:scrollView.contentOffset.x];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 停止滑动，能确定最终的页面了
    self.currentIndex = scrollView.contentOffset.x / CGRectGetWidth(self.scrollView.frame);
    
    // 这点代码很重要
    // 主要是为了设置 self.contentOffsetY = currentScrollView.contentOffset.y;
    UIViewController<INSPageContentViewControllerProtocol> *viewController = (UIViewController<INSPageContentViewControllerProtocol> *)[self _viewControllerForIndex:self.currentIndex];
    UIScrollView *currentScrollView = viewController.pageContentScrollView;
    UIEdgeInsets insets = currentScrollView.contentInset;
    CGFloat maxY = insets.bottom + currentScrollView.contentSize.height - currentScrollView.bounds.size.height;
    if (currentScrollView.contentOffset.y > maxY) {
        [currentScrollView setContentOffset:CGPointMake(0, -insets.top) animated:YES];
    }
    self.contentOffsetY = currentScrollView.contentOffset.y;
    if (self.contentOffsetY < 0 && self.contentOffsetY < -CGRectGetMaxY(self.headerContainerView.frame)) {
        // 垂直方向内容的调整
        [self observeValueForKeyPath:@"contentOffset" ofObject:currentScrollView change:nil context:nil];
    }
    
    [self _enableCurrentScrollViewScrollToTop:YES];
    
    if ([self.pageViewDelegate respondsToSelector:@selector(pageView:scrollViewDidScrollToIndex:)]) {
        [self.pageViewDelegate pageView:self scrollViewDidScrollToIndex:self.currentIndex];
    }
    
    if ([self.tabView respondsToSelector:@selector(scrollViewDidScrollToIndex:)]) {
        [self.tabView scrollViewDidScrollToIndex:self.currentIndex];
    }
}

#pragma mark Public Methods

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {

    // 超出范围或者就是本身，则直接返回
    if (index < 0 || index >= self.viewControllers.count || index == self.currentIndex) {
        return;
    }
    
    //
    [self _enableCurrentScrollViewScrollToTop:NO];
    
    //
    [self _viewControllersFitToScrollToIndex:index];
    
    if ([self.pageViewDelegate respondsToSelector:@selector(pageView:scrollViewWillScrollFromIndex:)]) {
        [self.pageViewDelegate pageView:self scrollViewWillScrollFromIndex:self.currentIndex];
    }
    
    if ([self.tabView respondsToSelector:@selector(scrollViewWillScrollFromIndex:)]) {
        [self.tabView scrollViewWillScrollFromIndex:self.currentIndex];
    }
    
    [self.scrollView setContentOffset:CGPointMake(index * CGRectGetWidth(self.scrollView.bounds), 0) animated:animated];
    
    // 重要
    if (!animated) {
        [self scrollViewDidEndDecelerating:self.scrollView];
    }
}

#pragma mark Private Methods

- (void)_initializeNonLazyLoadProperties {
    _currentIndex = 0;
    
    _headerViewHeight = 0;
    if ([self.pageViewDataSource respondsToSelector:@selector(heightForHeaderViewInPagerView:)]) {
        _headerViewHeight = [self.pageViewDataSource heightForHeaderViewInPagerView:self];
    }
    
    _tabViewHeight = 0;
    if ([self.pageViewDataSource respondsToSelector:@selector(heightForTabViewInPagerView:)]) {
        _tabViewHeight = [self.pageViewDataSource heightForTabViewInPagerView:self];
    }

    _headerContainerViewHeight = self.headerViewHeight + self.tabViewHeight;

    _navigationBarHeight = 0;
    if ([self.pageViewDataSource respondsToSelector:@selector(heightForNavigationBarInPagerView:)]) {
        _navigationBarHeight = [self.pageViewDataSource heightForNavigationBarInPagerView:self];
    }
    
    _minHeaderViewContainerHeight = [self _statusBarHeight] + self.navigationBarHeight + self.tabViewHeight;
    
    // Y Postion如果是-_headerContainerViewHeight，则代表整个headerContainerView被移出屏幕顶部
    // 但我们需要保证 statusbar，navigationbar以及tabView置顶显示，因此至少需要minHeaderViewContainerHeight的高度
    _minHeaderContainerViewFrameYPos =  -_headerContainerViewHeight + _minHeaderViewContainerHeight;
    
    _contentOffsetY = 0;
}

- (void)_layoutSubViews {
    [self addSubview:self.scrollView];
    
    [self.headerContainerView addArrangedSubview:self.headerView];
    [self.headerContainerView addArrangedSubview:self.tabView];
    [self.tabView.heightAnchor constraintEqualToConstant:self.tabViewHeight].active = true;
    
    [self addSubview:self.headerContainerView];
}

- (void)_layoutContentViews {
    NSInteger count = self.viewControllers.count;

    CGFloat width = CGRectGetWidth(self.scrollView.bounds);
    CGFloat height = CGRectGetHeight(self.scrollView.bounds);
    
    // 根据需要加载的内容的页数，确定scrollView的contentSize
    self.scrollView.contentSize = CGSizeMake(width * count, height);

    // 确定每一页的scrollView
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController<INSPageContentViewControllerProtocol> *pageContentViewController, NSUInteger idx, BOOL *stop) {
        pageContentViewController.view.frame = CGRectMake(width * idx, 0, width, height);
        pageContentViewController.pageViewController = self.pageViewController;
        UIScrollView *pageContentScrollView = pageContentViewController.pageContentScrollView;
        
        // 重要：
        // 思路就是每个scrollView需要添加headerContainerViewHeight高度的Inset
        UIEdgeInsets inset = pageContentScrollView.contentInset;
        inset.top += self.headerContainerViewHeight;
        pageContentScrollView.contentInset = inset;
        pageContentScrollView.scrollIndicatorInsets = inset;
        pageContentScrollView.contentOffset = CGPointMake(0, -inset.top); // 初始状态是到inset.top的位置，相当于显示headerContainerView
        pageContentScrollView.scrollsToTop = NO;
        
        pageContentScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        
        // 添加观察者，我们需要监控这个ScrollView垂直方向的滚动
        [pageContentScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld context:nil];
    }];
}

- (void)_addCurrentContentView {
    CGFloat width = CGRectGetWidth(self.scrollView.bounds);
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController<INSPageContentViewControllerProtocol> *pageContentViewController, NSUInteger idx, BOOL *stop) {
        CGFloat pageOffsetForContentView = idx * width;
        if (fabs(self.scrollView.contentOffset.x - pageOffsetForContentView) < width) {
            // 当前页面正好属于滚动范围，如果没有添加，则添加
            if (!pageContentViewController.parentViewController) {
                [pageContentViewController willMoveToParentViewController:self.pageViewController];
                [self.pageViewController addChildViewController:pageContentViewController];
                [self.scrollView addSubview:pageContentViewController.view];
                [pageContentViewController didMoveToParentViewController:self.pageViewController];
                [self _layoutHeaderContainerViewForViewController:pageContentViewController];
            }
        } else {
            // 当前页面正好不属于滚动范围，如果已经添加，则移除
            if (pageContentViewController.parentViewController) {
                [pageContentViewController willMoveToParentViewController:nil];
                [pageContentViewController.view removeFromSuperview];
                [pageContentViewController removeFromParentViewController];
            }
        }
    }];
}

// headerContainerView的状态保持不变，但内容需要
- (void)_layoutHeaderContainerViewForViewController:(UIViewController<INSPageContentViewControllerProtocol> *)viewController {
    UIScrollView *pageContentScrollView = viewController.pageContentScrollView;
    
    if (!pageContentScrollView) {
        return;
    }
    
    // 切换Page时，保证headerContainerView的位置不变
    CGFloat maxY = -MIN(CGRectGetMaxY(self.headerContainerView.frame), self.headerContainerViewHeight);
    if (pageContentScrollView.contentOffset.y < maxY) {
        pageContentScrollView.contentOffset = CGPointMake(pageContentScrollView.contentOffset.x, maxY);
    }
}

- (void)_enableCurrentScrollViewScrollToTop:(BOOL)enableScrollToTop {
    UIViewController<INSPageContentViewControllerProtocol> *viewController = (UIViewController<INSPageContentViewControllerProtocol> *)[self _viewControllerForIndex:self.currentIndex];
    viewController.pageContentScrollView.scrollsToTop = enableScrollToTop;
}

- (UIViewController<INSPageContentViewControllerProtocol> *)_viewControllerForIndex:(NSInteger)index {
    if (index < 0 || index >= self.viewControllers.count) {
        return nil;
    }
    
    return (UIViewController<INSPageContentViewControllerProtocol> *)self.viewControllers[index];
}

- (void)_viewControllersFitToScrollToIndex:(NSInteger)index {
    if (index < 0 || index >= self.viewControllers.count) {
        return;
    }
    
    NSInteger minIndex = 0;
    NSInteger maxIndex = self.viewControllers.count - 1;
    
    if (index < self.currentIndex) {
        minIndex = index;
        maxIndex = self.currentIndex - 1;
    } else {
        minIndex = self.currentIndex + 1;
        maxIndex = index;
    }
    
    for (NSInteger index = minIndex; index <= maxIndex; index++) {
        UIViewController<INSPageContentViewControllerProtocol> *viewController = self.viewControllers[index];
        [self _layoutHeaderContainerViewForViewController:viewController];
    }
}

- (CGFloat)_statusBarHeight {
    UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].windows[0].windowScene.statusBarManager;
    return statusBarManager.statusBarFrame.size.height;
}

#pragma mark Getter/Setter

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.directionalLockEnabled = YES;
        _scrollView.pagingEnabled = YES;
        _scrollView.bounces = NO;
        _scrollView.scrollsToTop = NO;
        _scrollView.delaysContentTouches = NO;
        _scrollView.delegate = self;
    }
    
    return _scrollView;
}

- (NSArray *)viewControllers {
    if (!_viewControllers) {
        NSInteger count = [self.pageViewDataSource numberOfPagesInPagerView:self];
        NSMutableArray *viewControllers = [NSMutableArray arrayWithCapacity:count];
        for (NSInteger index = 0; index < count; index++) {
            UIViewController *viewController = [self.pageViewDataSource pageView:self initPageContentViewControllerAtIndex:index];
            [viewControllers addObject:viewController];
        }
        
        _viewControllers = [viewControllers copy];
    }
    
    return _viewControllers;
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [self.pageViewDataSource headerViewInPagerView:self];
        _headerView.clipsToBounds = YES;
    }
    
    return _headerView;
}

- (UIView *)tabView {
    if (!_tabView) {
        _tabView = [self.pageViewDataSource tabViewInPagerView:self];
    }
    
    return _tabView;
}

- (UIStackView *)headerContainerView {
    if (!_headerContainerView) {
        _headerContainerView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.headerContainerViewHeight)];
        _headerContainerView.axis = UILayoutConstraintAxisVertical;
        _headerContainerView.distribution = UIStackViewDistributionFill;
        _headerContainerView.alignment = UIStackViewAlignmentFill;
    }
    
    return _headerContainerView;
}

@end
