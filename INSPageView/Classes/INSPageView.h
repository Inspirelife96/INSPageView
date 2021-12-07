//
//  INSPageView.h
//  INSTabPageViewController
//
//  Created by XueFeng Chen on 2021/12/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class INSTabView;

@protocol INSTabViewProtocol <NSObject>

@required

- (void)scrollViewHorizontalScrolledContentOffsetX:(CGFloat)contentOffsetX;
- (void)scrollViewDidScrollToIndex:(NSInteger)index;

@optional

- (void)pageViewheaderViewVerticalScrolledContentPercentY:(CGFloat)contentPercentY;
- (void)scrollViewWillScrollFromIndex:(NSInteger)index;

@end

@class INSPageView;

@protocol INSPageContentViewControllerProtocol

@required

@property (nonatomic, strong) UIViewController  * _Nullable pageViewController;

- (UIScrollView *)pageContentScrollView;

@end

@protocol INSPageViewDataSource <NSObject>

@required

- (CGFloat)heightForNavigationBarInPagerView:(INSPageView *)pagerView;

- (CGFloat)heightForHeaderViewInPagerView:(INSPageView *)pagerView;

- (UIView *)headerViewInPagerView:(INSPageView *)pagerView;

- (CGFloat)heightForTabViewInPagerView:(INSPageView *)pagerView;

- (UIView<INSTabViewProtocol> *)tabViewInPagerView:(INSPageView *)pagerView;

- (NSInteger)numberOfPagesInPagerView:(INSPageView *)pagerView;

- (UIViewController<INSPageContentViewControllerProtocol> *)pageView:(INSPageView *)pagerView initPageContentViewControllerAtIndex:(NSInteger)index;

@end

@protocol INSPageViewDelegate <NSObject>

@optional

- (void)pageView:(INSPageView *)pageView headerViewVerticalScrolledContentPercentY:(CGFloat)contentPercentY;

- (void)pageView:(INSPageView *)pageView scrollViewHorizontalScrolledContentOffsetX:(CGFloat)contentOffsetX;

- (void)pageView:(INSPageView *)pageView scrollViewWillScrollFromIndex:(NSInteger)index;

- (void)pageView:(INSPageView *)pageView scrollViewDidScrollToIndex:(NSInteger)index;

@end

@interface INSPageView : UIView

@property (nonatomic, weak) id<INSPageViewDataSource> pageViewDataSource;
@property (nonatomic, weak) id<INSPageViewDelegate> pageViewDelegate;
@property (nonatomic, weak) UIViewController *pageViewController;

@property (nonatomic, assign, readonly) NSInteger currentIndex;

- (instancetype)initWithFrame:(CGRect)frame pageViewDataSource:(id<INSPageViewDataSource>)pageViewDataSource pageViewDelegate:(id<INSPageViewDelegate>)pageViewDelegate pageViewController:(UIViewController *)pageViewController NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
