//
//  R4PageViewController.m
//  R4PageViewController
//
//  Created by Srđan Rašić on 9/8/13.
//  Copyright (c) 2013 Srđan Rašić. All rights reserved.
//

#import "R4PageViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

/* Global defines
 */
typedef void (^CompletionBlock)(void);

NSString * const R4OptionFrontPageShadowColor = @"R4OptionFrontPageShadowColor";
NSString * const R4OptionFrontPageShadowOpacity = @"R4OptionFrontPageShadowOpacity";
NSString * const R4OptionFrontPageShadowRadius = @"R4OptionFrontPageShadowRadius";
NSString * const R4OptionFrontPageInsets = @"R4OptionFrontPageInsets";
NSString * const R4OptionSidePagesSpaceDelayRate = @"R4OptionSidePagesSpaceDelayRate";
NSString * const R4OptionBorderPageMaxIndent = @"R4OptionBorderPageMaxIndent";


/* UIView+Position helper
 */
@interface UIView (Position)
@property (assign, nonatomic) CGSize size;
@property (assign, nonatomic) CGPoint origin;
@end


/* Container view
 */
@interface R4PageContainerView : UIView
@property (strong, nonatomic) UIViewController *viewController;
@end


/* Implements swiping mechanism
 */
@interface R4SwipeGestureRecognizer : UIGestureRecognizer

@property (weak, nonatomic) R4PageViewController *pageViewController;
@property (assign, nonatomic) CGPoint previousTouchPoint;
@property (assign, nonatomic) CFAbsoluteTime previousTouchTime;
@property (assign, nonatomic) CGFloat velocity;

- (id)initWithPageViewController:(R4PageViewController *)pageViewController;

@end


/* Main class
 */
@interface R4PageViewController ()

@property (assign, nonatomic) NSInteger numberOfPages;
@property (strong, nonatomic) R4PageContainerView *previousViewContainer;
@property (strong, nonatomic) R4PageContainerView *currentViewContainer;
@property (strong, nonatomic) R4PageContainerView *nextViewContainer;
@property (strong, nonatomic) UIViewController *needsAppearanceUpdateViewController;
@property (strong, nonatomic) R4SwipeGestureRecognizer *swipeGestureRecognizer;

@property (strong, nonatomic) NSMutableDictionary *options;

@end


@implementation R4PageViewController

- (id)initWithOptions:(NSDictionary *)options
{
  self.options = [options mutableCopy];
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    [self initializePrivateProperties];
  }
  return self;
}

- (void)dealloc
{
  self.previousViewContainer = nil;
  self.currentViewContainer = nil;
  self.nextViewContainer = nil;
}

- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers
{
  return NO;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
  return NO;
}

- (BOOL)shouldAutomaticallyForwardRotationMethods
{
  return NO;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

#pragma mark - Properties

- (void)initializePrivateProperties
{
  self.wantsFullScreenLayout = YES;
  self.currentPage = 0;
}

- (UIColor *)frontPageShadowColor
{
  UIColor *color = [self.options objectForKey:R4OptionFrontPageShadowColor];
  if (!color) {
    color = [UIColor blackColor];
    [self.options setObject:color forKey:R4OptionFrontPageShadowColor];
  }
  return color;
}

- (CGFloat)frontPageShadowOpacity
{
  NSNumber *opacity = [self.options objectForKey:R4OptionFrontPageShadowOpacity];
  if (!opacity) {
    opacity = [NSNumber numberWithFloat:0.2];
    [self.options setObject:opacity forKey:R4OptionFrontPageShadowOpacity];
  }
  return MAX(0, MIN(1, [opacity floatValue]));
}

- (CGFloat)frontPageShadowRadius
{
  NSNumber *radius = [self.options objectForKey:R4OptionFrontPageShadowRadius];
  if (!radius) {
    radius = [NSNumber numberWithFloat:4];
    [self.options setObject:radius forKey:R4OptionFrontPageShadowRadius];
  }
  return [radius floatValue];
}

- (UIEdgeInsets)frontPageInsets
{
  NSValue *insets = [self.options objectForKey:R4OptionFrontPageInsets];
  if (!insets) {
    insets = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [self.options setObject:insets forKey:R4OptionFrontPageInsets];
  }
  return [insets UIEdgeInsetsValue];
}

- (CGFloat)sidePagesSpaceDelayRate
{
  NSNumber *delay = [self.options objectForKey:R4OptionSidePagesSpaceDelayRate];
  if (!delay) {
    delay = [NSNumber numberWithFloat:0.7];
    [self.options setObject:delay forKey:R4OptionSidePagesSpaceDelayRate];
  }
  return MAX(0.5, MIN(1.5, [delay floatValue]));
}

- (CGFloat)borderPageMaxIndent
{
  NSNumber *indent = [self.options objectForKey:R4OptionBorderPageMaxIndent];
  if (!indent) {
    indent = [NSNumber numberWithFloat:20];
    [self.options setObject:indent forKey:R4OptionBorderPageMaxIndent];
  }
  return [indent floatValue];
}

- (UIViewController *)currentViewController
{
  return self.currentViewContainer.viewController;
}

#pragma mark - View handling

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.view.layer.masksToBounds = YES;
  
  [self loadContainerViews];

  /* This guy provides swiping mechanism */
	self.swipeGestureRecognizer = [[R4SwipeGestureRecognizer alloc] initWithPageViewController:self];
  [self.view addGestureRecognizer:self.swipeGestureRecognizer];
}

- (void)loadContainerViews
{
  self.previousViewContainer = [[R4PageContainerView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:self.previousViewContainer];
  
  self.nextViewContainer = [[R4PageContainerView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:self.nextViewContainer];
  
  self.currentViewContainer = [[R4PageContainerView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:self.currentViewContainer];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self removeQuartzCoreEffects:self.currentViewContainer];
  
  [self.currentViewContainer.viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.previousViewContainer.viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.nextViewContainer.viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self applyQuartzCoreEffects:self.currentViewContainer];
  [self layoutForDragging];
  
  [self.currentViewContainer.viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self.previousViewContainer.viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self.nextViewContainer.viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (NSUInteger)supportedInterfaceOrientations
{
  if (self.currentViewContainer.viewController) {
    return [self.currentViewContainer.viewController supportedInterfaceOrientations];
  } else {
    return UIInterfaceOrientationMaskAll;
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  if (self.currentViewContainer.viewController) {
    return [self.currentViewContainer.viewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
  } else {
    return YES;
  }
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  [self layoutForDragging];
}

- (void)layoutForDragging
{
  [self.view bringSubviewToFront:self.currentViewContainer];

  CGSize mySize = self.view.bounds.size;
  self.previousViewContainer.frame = UIEdgeInsetsInsetRect(CGRectMake(-mySize.width * self.sidePagesSpaceDelayRate, 0, mySize.width, mySize.height), self.frontPageInsets);
  self.nextViewContainer.frame = UIEdgeInsetsInsetRect(CGRectMake(mySize.width * self.sidePagesSpaceDelayRate, 0, mySize.width, mySize.height), self.frontPageInsets);
  self.currentViewContainer.frame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, mySize.width, mySize.height), self.frontPageInsets);
  [self updateQuartzCoreEffects:self.currentViewContainer];
}

- (void)setCurrentViewContainer:(R4PageContainerView *)currentViewContainer
{
  [self removeQuartzCoreEffects:_currentViewContainer];
  _currentViewContainer = currentViewContainer;
  [self applyQuartzCoreEffects:_currentViewContainer];
}

- (void)updateQuartzCoreEffects:(UIView *)view
{
  view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
}

- (void)applyQuartzCoreEffects:(UIView *)view
{
  view.layer.shadowColor = self.frontPageShadowColor.CGColor;
  view.layer.shadowRadius = self.frontPageShadowRadius;
  view.layer.shadowOpacity = self.frontPageShadowOpacity;
  view.layer.shadowOffset = CGSizeMake(0, 0);
  view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
}

- (void)removeQuartzCoreEffects:(UIView *)view
{
  view.layer.shadowRadius = 0;
  view.layer.shadowOpacity = 0;
  view.layer.shadowOffset = CGSizeMake(0, 0);
  view.layer.shadowPath = nil;
}

- (void)animateToRestAndMakeAppearanceUpdates:(CompletionBlock)completion
{
  [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    [self layoutForDragging];
  } completion:^(BOOL finished) {
    [self.needsAppearanceUpdateViewController endAppearanceTransition];
    self.needsAppearanceUpdateViewController = nil;
    [self.currentViewContainer.viewController endAppearanceTransition];
    completion();
  }];
}

#pragma mark - Data handling

- (void)reloadData
{
  self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
  NSAssert(self.numberOfPages >= 0, @"Error: Number of pages in R4PageViewController < 0!");
  
  self.currentPage = MAX(0, MIN(self.numberOfPages - 1, self.currentPage));
  
  if (self.numberOfPages > 0) {
    self.currentViewContainer.viewController = [self viewControllerForPage:self.currentPage];
    
    if (self.currentPage > 0) {
      self.previousViewContainer.viewController = [self viewControllerForPage:self.currentPage-1];
    }
    
    if (self.currentPage < self.numberOfPages - 1) {
      self.nextViewContainer.viewController = [self viewControllerForPage:self.currentPage+1];
    }
  }
}

- (void)shiftContainersRight
{
  [self willScrollToPage:self.currentPage+1 toController:self.nextViewContainer.viewController];

  self.currentPage++;
  R4PageContainerView *previousViewContainer = self.previousViewContainer;
  
  [self.currentViewContainer.viewController beginAppearanceTransition:NO animated:YES];
  [self.nextViewContainer.viewController beginAppearanceTransition:YES animated:YES];
  self.needsAppearanceUpdateViewController = self.currentViewContainer.viewController;
  
  self.previousViewContainer = self.currentViewContainer;
  self.currentViewContainer = self.nextViewContainer;
  self.nextViewContainer = previousViewContainer;
  
  self.nextViewContainer.viewController = [self viewControllerForPage:self.currentPage+1];
  
  [self fixScrollingToTop];
}

- (void)shiftContainersLeft
{
  [self willScrollToPage:self.currentPage+1 toController:self.nextViewContainer.viewController];

  self.currentPage--;
  
  R4PageContainerView *nextViewContainer = self.nextViewContainer;
  
  [self.currentViewContainer.viewController beginAppearanceTransition:NO animated:YES];
  [self.previousViewContainer.viewController beginAppearanceTransition:YES animated:YES];
  self.needsAppearanceUpdateViewController = self.currentViewContainer.viewController;
  
  self.nextViewContainer = self.currentViewContainer;
  self.currentViewContainer = self.previousViewContainer;
  self.previousViewContainer = nextViewContainer;
  
  self.previousViewContainer.viewController = [self viewControllerForPage:self.currentPage-1];
  
  [self fixScrollingToTop];
}

#pragma mark - Helper methods

- (void)setViewHierarchy:(UIView *)rootView scrollsToTop:(BOOL)scrollsToTop maxLevel:(NSInteger)maxLevel
{
  if (maxLevel < 0) return;
  if ([rootView isKindOfClass:[UIScrollView class]]) {
    [(UIScrollView *)rootView setScrollsToTop:scrollsToTop];
  } else {
    for (UIView *view in [rootView subviews]) {
      [self setViewHierarchy:view scrollsToTop:scrollsToTop maxLevel:maxLevel-1];
    }
  }
}

- (void)fixScrollingToTop
{
  [self setViewHierarchy:self.currentViewContainer.viewController.view scrollsToTop:YES maxLevel:2];
  [self setViewHierarchy:self.previousViewContainer.viewController.view scrollsToTop:NO maxLevel:2];
  [self setViewHierarchy:self.nextViewContainer.viewController.view scrollsToTop:NO maxLevel:2];
}

#pragma mark -- DataSource methods

- (UIViewController *)viewControllerForPage:(NSInteger)page
{
  UIViewController *controller = nil;
  
  if (page >= 0 && page < self.numberOfPages) {
    controller = [self.dataSource pageViewController:self viewControllerForPage:page];
  }
  
  return controller;
}


#pragma mark -- Delegate methods

- (void)willScrollToPage:(NSInteger)toPage toController:(UIViewController *)toController
{
  if ([self.delegate respondsToSelector:@selector(pageViewController:willScrollToPage:toController:)]) {
    [self.delegate pageViewController:self willScrollToPage:toPage toController:toController];
  }
}

- (void)didScrollToPage:(NSInteger)toPage toController:(UIViewController *)toController
{
  if ([self.delegate respondsToSelector:@selector(pageViewController:didScrollToPage:toController:)]) {
    [self.delegate pageViewController:self didScrollToPage:toPage toController:toController];
  }
}

- (void)didTapOnPage:(NSInteger)page controller:(UIViewController *)controller
{
  if ([self.delegate respondsToSelector:@selector(pageViewController:didTapOnPage:controller:)]) {
    [self.delegate pageViewController:self didTapOnPage:page controller:controller];
  }
}

- (void)didScrollToOffset:(CGFloat)offset
{
  if ([self.delegate respondsToSelector:@selector(pageViewController:didScrollToOffset:)]) {
    [self.delegate pageViewController:self didScrollToOffset:offset];
  }
}

@end


@implementation UIView (Position)
- (void)setSize:(CGSize)size { self.frame = CGRectMake(self.origin.x, self.origin.y, size.width, size.height); }
- (CGSize)size { return self.frame.size; }
- (void)setOrigin:(CGPoint)origin { self.frame = CGRectMake(origin.x, origin.y, self.size.width, self.size.height); }
- (CGPoint)origin { return self.frame.origin; }
@end


@implementation R4PageContainerView

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  }
  return self;
}

- (void)setViewController:(UIViewController *)viewController
{
  UIViewController *parentViewController = _viewController.parentViewController;
  
  [_viewController willMoveToParentViewController:nil];
  [_viewController.view removeFromSuperview];
  [_viewController removeFromParentViewController];
  
  _viewController = viewController;
  
  [parentViewController addChildViewController:_viewController];
  
  _viewController.view.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
  _viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self addSubview:_viewController.view];

  [_viewController didMoveToParentViewController:parentViewController];
}

@end


@implementation R4SwipeGestureRecognizer

- (id)initWithPageViewController:(R4PageViewController *)pageViewController
{
  self = [super init];
  if (self) {
    self.pageViewController = pageViewController;
  }
  return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  self.previousTouchPoint = [touch locationInView:self.view];
  self.previousTouchTime = CFAbsoluteTimeGetCurrent();
  self.state = UIGestureRecognizerStatePossible;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self.view];
  
  if (self.state == UIGestureRecognizerStatePossible) {
    CGFloat dx = ABS(location.x - self.previousTouchPoint.x);
    CGFloat dy = ABS(location.y - self.previousTouchPoint.y);
    
    if (dx > dy) {
      self.state = UIGestureRecognizerStateBegan;
    } else {
      self.state = UIGestureRecognizerStateFailed;
    }
  } else if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
    
    CGFloat deltaX = location.x - self.previousTouchPoint.x;
    CFAbsoluteTime deltaT = time - self.previousTouchTime;
    
    UIView *view = self.pageViewController.currentViewContainer;
    view.origin = CGPointMake(view.origin.x + deltaX, view.origin.y);
    
    view = self.pageViewController.previousViewContainer;
    view.origin = CGPointMake(view.origin.x + deltaX * self.pageViewController.sidePagesSpaceDelayRate, view.origin.y);
    
    view = self.pageViewController.nextViewContainer;
    view.origin = CGPointMake(view.origin.x + deltaX * self.pageViewController.sidePagesSpaceDelayRate, view.origin.y);
    
    self.velocity = deltaX / deltaT;
    self.previousTouchPoint = location;
    self.previousTouchTime = CFAbsoluteTimeGetCurrent();
    
    if (self.pageViewController.currentPage == 0 && self.pageViewController.currentViewContainer.origin.x > self.pageViewController.borderPageMaxIndent) {
      self.pageViewController.currentViewContainer.origin = CGPointMake(self.pageViewController.borderPageMaxIndent, self.pageViewController.currentViewContainer.origin.y);
    } else if (self.pageViewController.currentPage == self.pageViewController.numberOfPages-1 && self.pageViewController.currentViewContainer.origin.x < -self.pageViewController.borderPageMaxIndent) {
      self.pageViewController.currentViewContainer.origin = CGPointMake(-self.pageViewController.borderPageMaxIndent, self.pageViewController.currentViewContainer.origin.y);
    }
    
    [self.pageViewController didScrollToOffset:self.pageViewController.currentViewContainer.frame.origin.x];
    
    self.state = UIGestureRecognizerStateChanged;
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
    BOOL pageChanged = NO;
    
    UIView *curentVCView = self.pageViewController.currentViewContainer;
    if (curentVCView.origin.x > curentVCView.size.width / 2 && self.pageViewController.currentPage > 0) {
      [self.pageViewController shiftContainersLeft];
      pageChanged = YES;
    } else if (curentVCView.origin.x < -curentVCView.size.width / 2 && self.pageViewController.currentPage < self.pageViewController.numberOfPages-1) {
      [self.pageViewController shiftContainersRight];
      pageChanged = YES;
    } else if (ABS(self.velocity) > 500) {
      if (self.velocity < 0) {
        if (self.pageViewController.currentPage < self.pageViewController.numberOfPages-1) {
          [self.pageViewController shiftContainersRight];
          pageChanged = YES;
        }
      } else if (self.pageViewController.currentPage > 0) {
        [self.pageViewController shiftContainersLeft];
        pageChanged = YES;
      }
    }
    
    [self.pageViewController animateToRestAndMakeAppearanceUpdates:^{
      self.state = UIGestureRecognizerStateEnded;
      if (pageChanged) {
        [self.pageViewController didScrollToPage:self.pageViewController.currentPage toController:self.pageViewController.currentViewContainer.viewController];
      }
    }];
  } else {
    self.state = UIGestureRecognizerStateCancelled;
  }
}

@end


