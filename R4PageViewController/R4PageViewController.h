//
//  R4PageViewController.h
//  R4PageViewController
//
//  Created by Srđan Rašić on 9/8/13.
//  Copyright (c) 2013 Srđan Rašić. All rights reserved.
//

#import <UIKit/UIKit.h>

@class R4PageViewController;


//! Default: [UIColor blackColor]
extern NSString * const R4OptionFrontPageShadowColor;

//! Default: [NSNumber numberWithFloat:0.2]
extern NSString * const R4OptionFrontPageShadowOpacity;

//! Default: [NSNumber numberWithFloat:4]
extern NSString * const R4OptionFrontPageShadowRadius;

//! Default: [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)]
extern NSString * const R4OptionFrontPageInsets;

//! Default: [NSNumber numberWithFloat:0.7]
extern NSString * const R4OptionSidePagesSpaceDelayRate;

//! Default: [NSNumber numberWithInteger:50]
extern NSString * const R4OptionBorderPageMaxIndent;



//! Implement this protocol to provide data for R4PageViewController.
@protocol R4PageViewControllerDataSource <NSObject>

@required
- (NSInteger)numberOfPagesInPageViewController:(R4PageViewController *)pageViewController;
- (UIViewController *)pageViewController:(R4PageViewController *)pageViewController viewControllerForPage:(NSInteger)page;

@end



//! Get informed of state changes through delegate.
@protocol R4PageViewControllerDelegate <NSObject>

@optional
- (void)pageViewController:(R4PageViewController *)pageViewController willScrollToPage:(NSInteger)toPage toController:(UIViewController *)toController;
- (void)pageViewController:(R4PageViewController *)pageViewController didScrollToPage:(NSInteger)toPage toController:(UIViewController *)toController;
- (void)pageViewController:(R4PageViewController *)pageViewController didTapOnPage:(NSInteger)page controller:(UIViewController *)controller;
- (void)pageViewController:(R4PageViewController *)pageViewController didScrollToOffset:(CGFloat)offset;

@end



//! R4PageViewController main class.
@interface R4PageViewController : UIViewController

@property (weak, nonatomic) id<R4PageViewControllerDataSource> dataSource;
@property (weak, nonatomic) id<R4PageViewControllerDelegate> delegate;
@property (strong, nonatomic, readonly) UIViewController *currentViewController;
@property (assign, nonatomic) NSInteger currentPage;

// Methods
- (id)initWithOptions:(NSDictionary *)options;
- (void)reloadData;

@end



