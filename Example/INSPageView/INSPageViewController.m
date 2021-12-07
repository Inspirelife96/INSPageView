//
//  INSPageViewController.m
//  INSTabPageViewController
//
//  Created by XueFeng Chen on 2021/12/3.
//

#import "INSPageViewController.h"

#import "INSPageContentViewController.h"



@interface INSPageViewController ()

@property (nonatomic, strong) INSPageView *pageView;
@property (nonatomic, strong) INSTabView *tabView;
@property (nonatomic, strong) UIView *headerView;

@end

@implementation INSPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.pageView];
}

#pragma mark INSPageViewDataSource

- (CGFloat)heightForNavigationBarInPagerView:(INSPageView *)pagerView {
    if (self.navigationController.navigationBar) {
        return self.navigationController.navigationBar.frame.size.height;
    } else {
        return 0.0f;
    }
}

- (CGFloat)heightForHeaderViewInPagerView:(INSPageView *)pagerView {
    return 200.0f;
}

- (UIView *)headerViewInPagerView:(INSPageView *)pagerView {
    return self.headerView;
}

- (CGFloat)heightForTabViewInPagerView:(INSPageView *)pagerView {
    return 44.0f;
}

- (UIView *)tabViewInPagerView:(INSPageView *)pagerView {
    return self.tabView;
}

- (NSInteger)numberOfPagesInPagerView:(INSPageView *)pagerView {
    return 4;
}

- (UIViewController<INSPageContentViewControllerProtocol> *)pageView:(INSPageView *)pagerView initPageContentViewControllerAtIndex:(NSInteger)index {
    return [[INSPageContentViewController alloc] init];
}


#pragma mark INSPageViewDelegate
- (void)pageView:(INSPageView *)pageView headerViewVerticalScrolledContentPercentY:(CGFloat)contentPercentY {
    CGFloat red = 0;
    CGFloat blue = 0;
    CGFloat green = 0;
    CGFloat alpha = 0;
    
    UIColor *finalbackgroundColor = [UIColor secondarySystemBackgroundColor];
    [finalbackgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    UIColor *backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:contentPercentY];
    
    UIColor *finalShadowColor = [UIColor separatorColor];
    [finalShadowColor getRed:&red green:&green blue:&blue alpha:&alpha];
    UIColor *shadowColor = [UIColor colorWithRed:red green:green blue:blue alpha:contentPercentY];
    
    UIColor *finalLabelColor = [UIColor labelColor];
    [finalLabelColor getRed:&red green:&green blue:&blue alpha:&alpha];
    UIColor *labelColor = [UIColor colorWithRed:red green:green blue:blue alpha:contentPercentY];

    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    // 注意，一定得是Opaque，不能使用configureWithDefaultBackground。
    // 通过backgroundColor的alpha来决定视图的透明度
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = backgroundColor;
    appearance.shadowColor = shadowColor;
    appearance.titleTextAttributes = @{NSForegroundColorAttributeName:labelColor};
    
    self.navigationItem.standardAppearance = appearance;
    self.navigationItem.scrollEdgeAppearance = appearance;
}

#pragma mark INSTabViewDataSource

- (NSInteger)numberOfTabsForTabView:(INSTabView *)tabView {
    return 4;
}

- (NSString *)tabView:(INSTabView *)tabView tabTitleForIndex:(NSInteger)index {
    return @[@"page1", @"page2", @"page3", @"page4"][index];
}

#pragma mark INSTabViewDelegate
 
- (void)tabView:(INSTabView *)tabView didSelectIndex:(NSInteger)index {
    BOOL animated = labs(index - self.pageView.currentIndex) > 1 ? NO: YES;
    [self.pageView scrollToIndex:index animated:animated];
}


- (INSPageView *)pageView {
    if (!_pageView) {
        _pageView = [[INSPageView alloc] initWithFrame:self.view.bounds pageViewDataSource:self pageViewDelegate:self pageViewController:self];
    }
    
    return _pageView;
}

- (INSTabView *)tabView {
    if (!_tabView) {
        _tabView = [[INSTabView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.0f) tabViewDataSource:self INSTabViewDelegate:self];
    }
    
    return _tabView;
}

- (UIView *)headerView {
    if (!_headerView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200.0f)];
        imageView.image = [UIImage imageNamed:@"user_profile_background0"];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
    
        _headerView = imageView;
    }
    
    return _headerView;
}

@end
