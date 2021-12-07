//
//  INSPageViewController.h
//  INSTabPageViewController
//
//  Created by XueFeng Chen on 2021/12/3.
//

#import <UIKit/UIKit.h>

#import <INSPageView/INSPageView-umbrella.h>
#import "INSTabView.h"

NS_ASSUME_NONNULL_BEGIN

@interface INSPageViewController : UIViewController <INSPageViewDelegate, INSPageViewDataSource, INSTabViewDelegate, INSTabViewDataSource>

@end

NS_ASSUME_NONNULL_END
