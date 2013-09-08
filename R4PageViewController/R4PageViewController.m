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


/* UIView+Position helper
 */
@interface UIView (Position)
@property (assign, nonatomic) CGSize size;
@property (assign, nonatomic) CGPoint origin;
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
@property (strong, nonatomic) UIViewController *previousViewController;
@property (strong, nonatomic) UIViewController *currentViewController;
@property (strong, nonatomic) UIViewController *nextViewController;
@property (strong, nonatomic) R4SwipeGestureRecognizer *swipeGestureRecognizer;

@end


@implementation R4PageViewController

+ (id)new
{
  return [[self alloc] init];
}

- (id)init
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    [self initializePublicProperties];
    [self initializePrivateProperties];
  }
  return self;
}

- (void)dealloc
{
  [self.currentViewController removeFromParentViewController];
  [self.currentViewController.view removeFromSuperview];
  self.currentViewController = nil;
  
  [self.previousViewController removeFromParentViewController];
  [self.previousViewController.view removeFromSuperview];
  self.previousViewController = nil;
  
  [self.nextViewController removeFromParentViewController];
  [self.nextViewController.view removeFromSuperview];
  self.nextViewController = nil;
}

- (void)initializePublicProperties
{
  self.frontPageShadowColor = [UIColor blackColor];
  self.frontPageShadowOpacity = .2;
  self.frontPageInsets = UIEdgeInsetsMake(0, 0, 0, 0);
  self.sidePagesSpaceDelayRate = 0.7;
  self.borderPageMaxIndent = 50;
}

- (void)initializePrivateProperties
{
  self.wantsFullScreenLayout = YES;
  self.view.userInteractionEnabled = YES;
  self.currentPage = 2;
}

- (void)setCurrentViewController:(UIViewController *)currentViewController
{
  [self removeQuartzCoreEffects:_currentViewController.view];
  [self applyQuartzCoreEffects:currentViewController.view];
  _currentViewController = currentViewController;
}

- (void)setSidePagesSpaceDelayRate:(CGFloat)sidePagesSpaceDelayRate
{
  _sidePagesSpaceDelayRate = MAX(0.5, MIN(1, sidePagesSpaceDelayRate));
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];

  /* This guy provides swiping mechanism */
	self.swipeGestureRecognizer = [[R4SwipeGestureRecognizer alloc] initWithPageViewController:self];
  [self.view addGestureRecognizer:self.swipeGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self reloadData];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [self layoutForDragging];
}

- (NSUInteger)supportedInterfaceOrientations
{
  if (self.currentViewController) {
    return [self.currentViewController supportedInterfaceOrientations];
  } else {
    return UIInterfaceOrientationMaskAll;
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  if (self.currentViewController) {
    return [self.currentViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
  } else {
    return YES;
  }
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  [self updateQuartzCoreEffects:self.currentViewController.view];
}

- (void)layoutForDragging
{
  [self.view bringSubviewToFront:self.currentViewController.view];

  CGSize mySize = self.view.bounds.size;
  self.previousViewController.view.frame = UIEdgeInsetsInsetRect(CGRectMake(-mySize.width * self.sidePagesSpaceDelayRate, 0, mySize.width, mySize.height), self.frontPageInsets);
  self.nextViewController.view.frame = UIEdgeInsetsInsetRect(CGRectMake(mySize.width * self.sidePagesSpaceDelayRate, 0, mySize.width, mySize.height), self.frontPageInsets);
  self.currentViewController.view.frame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, mySize.width, mySize.height), self.frontPageInsets);
}

- (void)updateQuartzCoreEffects:(UIView *)view
{
  view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
}

- (void)applyQuartzCoreEffects:(UIView *)view
{
  view.layer.shadowColor = self.frontPageShadowColor.CGColor;
  view.layer.shadowRadius = 10;
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
  [self setViewHierarchy:self.currentViewController.view scrollsToTop:YES maxLevel:2];
  [self setViewHierarchy:self.previousViewController.view scrollsToTop:NO maxLevel:2];
  [self setViewHierarchy:self.nextViewController.view scrollsToTop:NO maxLevel:2];
}

- (void)reloadData
{
  self.numberOfPages = [self.dataSource numberOfPagesInPageViewController:self];
  NSAssert(self.numberOfPages >= 0, @"Error: Number of pages in R4PageViewController < 0!");
  
  self.currentPage = MAX(0, MIN(self.numberOfPages - 1, self.currentPage));
  [self setupForPage:self.currentPage];
}

- (void)setupForPage:(NSInteger)page
{
  self.currentViewController = [self viewControllerForPage:page];
  [self addChildViewController:self.currentViewController];

  if (page > 0) {
    self.previousViewController = [self viewControllerForPage:page-1];
    [self addChildViewController:self.previousViewController];
  } else {
    self.previousViewController = nil;
  }
  
  if (page < self.numberOfPages - 1) {
    self.nextViewController = [self viewControllerForPage:page+1];
    [self addChildViewController:self.nextViewController];
  } else {
    self.nextViewController = nil;
  }
  
  self.currentPage = page;
  
  [self.view addSubview:self.previousViewController.view];
  [self.previousViewController didMoveToParentViewController:self];
  
  [self.view addSubview:self.nextViewController.view];
  [self.nextViewController didMoveToParentViewController:self];
  
  [self.view addSubview:self.currentViewController.view];
  [self.currentViewController didMoveToParentViewController:self];
  
  [self fixScrollingToTop];
  [self layoutForDragging];
}

- (void)shiftControllerHierarchyNext
{
  [self willScrollToPage:self.currentPage+1 toController:self.nextViewController];

  self.currentPage++;
  
  [self.previousViewController.view removeFromSuperview];
  [self.previousViewController removeFromParentViewController];
  self.previousViewController = self.currentViewController;
  
  self.currentViewController = self.nextViewController;
  
  self.nextViewController = [self viewControllerForPage:self.currentPage+1];
  [self.view insertSubview:self.nextViewController.view belowSubview:self.currentViewController.view];
  
  [self fixScrollingToTop];
}

- (void)shiftControllerHierarchyBack
{
  [self willScrollToPage:self.currentPage-1 toController:self.previousViewController];
  
  self.currentPage--;
  
  [self.nextViewController.view removeFromSuperview];
  [self.nextViewController removeFromParentViewController];
  self.nextViewController = self.currentViewController;
  
  self.currentViewController = self.previousViewController;
  
  self.previousViewController = [self viewControllerForPage:self.currentPage-1];
  [self.view insertSubview:self.previousViewController.view belowSubview:self.currentViewController.view];
  
  [self fixScrollingToTop];
}

- (void)animateToRest:(CompletionBlock)completion
{
  [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    [self layoutForDragging];
  } completion:^(BOOL finished) {
    completion();
  }];
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
  //[self.pageViewController layoutForDragging];
  
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
    
    UIView *view = self.pageViewController.currentViewController.view;
    view.origin = CGPointMake(view.origin.x + deltaX, view.origin.y);
    
    view = self.pageViewController.previousViewController.view;
    view.origin = CGPointMake(view.origin.x + deltaX * self.pageViewController.sidePagesSpaceDelayRate, view.origin.y);
    
    view = self.pageViewController.nextViewController.view;
    view.origin = CGPointMake(view.origin.x + deltaX * self.pageViewController.sidePagesSpaceDelayRate, view.origin.y);
    
    self.velocity = deltaX / deltaT;
    self.previousTouchPoint = location;
    self.previousTouchTime = CFAbsoluteTimeGetCurrent();
    
    if (self.pageViewController.currentPage == 0 && self.pageViewController.currentViewController.view.origin.x > self.pageViewController.borderPageMaxIndent) {
      self.pageViewController.currentViewController.view.origin = CGPointMake(self.pageViewController.borderPageMaxIndent, self.pageViewController.currentViewController.view.origin.y);
    } else if (self.pageViewController.currentPage == self.pageViewController.numberOfPages-1 && self.pageViewController.currentViewController.view.origin.x < -self.pageViewController.borderPageMaxIndent) {
      self.pageViewController.currentViewController.view.origin = CGPointMake(-self.pageViewController.borderPageMaxIndent, self.pageViewController.currentViewController.view.origin.y);
    }
    
    [self.pageViewController didScrollToOffset:self.pageViewController.currentViewController.view.frame.origin.x];
    
    self.state = UIGestureRecognizerStateChanged;
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
    BOOL pageChanged = NO;
    
    UIView *curentVCView = self.pageViewController.currentViewController.view;
    if (curentVCView.origin.x > curentVCView.size.width / 2 && self.pageViewController.currentPage > 0) {
      [self.pageViewController shiftControllerHierarchyBack];
      pageChanged = YES;
    } else if (curentVCView.origin.x < -curentVCView.size.width / 2 && self.pageViewController.currentPage < self.pageViewController.numberOfPages-1) {
      [self.pageViewController shiftControllerHierarchyNext];
      pageChanged = YES;
    } else if (ABS(self.velocity) > 500) {
      if (self.velocity < 0) {
        if (self.pageViewController.currentPage < self.pageViewController.numberOfPages-1) {
          [self.pageViewController shiftControllerHierarchyNext];
          pageChanged = YES;
        }
      } else if (self.pageViewController.currentPage > 0) {
        [self.pageViewController shiftControllerHierarchyBack];
        pageChanged = YES;
      }
    }
    
    [self.pageViewController animateToRest:^{
      self.state = UIGestureRecognizerStateEnded;
      if (pageChanged) {
        [self.pageViewController didScrollToPage:self.pageViewController.currentPage toController:self.pageViewController.currentViewController];
      }
    }];
  } else {
    self.state = UIGestureRecognizerStateCancelled;
  }
}

@end


