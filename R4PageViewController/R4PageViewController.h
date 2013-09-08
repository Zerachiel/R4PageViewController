//
//  R4PageViewController.h
//  R4PageViewController
//
//  Created by Srđan Rašić on 9/8/13.
//  Copyright (c) 2013 Srđan Rašić. All rights reserved.
//

#import <UIKit/UIKit.h>

@class R4PageViewController;



/* Implement this protocol to provide data
 * for R4PageViewController
 */
@protocol R4PageViewControllerDataSource <NSObject>

@required
- (NSInteger)numberOfPagesInPageViewController:(R4PageViewController *)pageViewController;
- (UIViewController *)pageViewController:(R4PageViewController *)pageViewController viewControllerForPage:(NSInteger)page;

@end



/* Get informed of state changes through delegate
 */
@protocol R4PageViewControllerDelegate <NSObject>

@optional
- (void)pageViewController:(R4PageViewController *)pageViewController willScrollToPage:(NSInteger)toPage toController:(UIViewController *)toController;
- (void)pageViewController:(R4PageViewController *)pageViewController didScrollToPage:(NSInteger)toPage toController:(UIViewController *)toController;
- (void)pageViewController:(R4PageViewController *)pageViewController didTapOnPage:(NSInteger)page controller:(UIViewController *)controller;
- (void)pageViewController:(R4PageViewController *)pageViewController didScrollToOffset:(CGFloat)offset;

@end



/* R4PageViewController main class
 */
@interface R4PageViewController : UIViewController

/* Data source 
 */
@property (weak, nonatomic) id<R4PageViewControllerDataSource> dataSource;
@property (weak, nonatomic) id<R4PageViewControllerDelegate> delegate;
@property (assign, nonatomic) NSInteger currentPage;

/* Appearance 
 */
@property (strong, nonatomic) UIColor *frontPageShadowColor;
@property (assign, nonatomic) CGFloat frontPageShadowOpacity;
@property (assign, nonatomic) UIEdgeInsets frontPageInsets;
@property (assign, nonatomic) CGFloat sidePagesSpaceDelayRate;
@property (assign, nonatomic) CGFloat borderPageMaxIndent;

/* Methods
 */
+ (id)new;
- (void)reloadData;

@end



