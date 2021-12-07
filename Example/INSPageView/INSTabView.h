//
//  INSTabView.h
//  INSTabPageViewController
//
//  Created by XueFeng Chen on 2021/11/29.
//

#import <UIKit/UIKit.h>

#import <INSPageView/INSPageView-umbrella.h>

NS_ASSUME_NONNULL_BEGIN

@class INSTabView;

@protocol INSTabViewDataSource <NSObject>

- (NSInteger)numberOfTabsForTabView:(INSTabView *)tabView;
- (NSString *)tabView:(INSTabView *)tabView tabTitleForIndex:(NSInteger)index;

@end

@protocol INSTabViewDelegate <NSObject>

- (void)tabView:(INSTabView *)tabView didSelectIndex:(NSInteger)index;

@end

@interface INSTabView : UIView <INSTabViewProtocol>

- (instancetype)initWithFrame:(CGRect)frame tabViewDataSource:(id<INSTabViewDataSource>)tabViewDataSource INSTabViewDelegate:(id<INSTabViewDelegate>)tabViewDelegate;

@property (nonatomic, weak) id<INSTabViewDataSource> tabViewDataSource;
@property (nonatomic, weak) id<INSTabViewDelegate> tabViewDelegate;

@end

NS_ASSUME_NONNULL_END
