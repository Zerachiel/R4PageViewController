//
//  R4AppDelegate.m
//  R4PageViewController
//
//  Created by Srđan Rašić on 9/8/13.
//  Copyright (c) 2013 Srđan Rašić. All rights reserved.
//

#import "R4AppDelegate.h"
#import "R4PageViewController.h"

#define DLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])

@interface R4AppDelegate () <R4PageViewControllerDataSource, R4PageViewControllerDelegate>
@end

@interface R4VC : UIViewController
@end

@implementation R4VC

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  DLog(@"fired");
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  DLog(@"fired");
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  DLog(@"fired");
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  DLog(@"fired");
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  DLog(@"fired");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  DLog(@"fired");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return YES;
}

@end


@implementation R4AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Override point for customization after application launch.
  NSDictionary *options = @{R4OptionFrontPageInsets: [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 10)],
                            R4OptionFrontPageShadowOpacity: [NSNumber numberWithFloat:0.4],
                            R4OptionFrontPageShadowRadius: [NSNumber numberWithFloat:4]};

  R4PageViewController *pageViewController = [[R4PageViewController alloc] initWithOptions:options];
  pageViewController.dataSource = self;
  pageViewController.delegate = self;
  
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = pageViewController;
  [self.window makeKeyAndVisible];
  return YES;
}
							
- (NSInteger)numberOfPagesInPageViewController:(R4PageViewController *)pageViewController
{
  return 10;
}

- (UIViewController *)pageViewController:(R4PageViewController *)pageViewController viewControllerForPage:(NSInteger)page
{
  UIViewController *controller = [R4VC new];
  UILabel *label = [[UILabel alloc] initWithFrame:controller.view.bounds];
  label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  label.textAlignment = NSTextAlignmentCenter;
  label.text = [NSString stringWithFormat:@"This is page number %d", page];
  label.backgroundColor = [UIColor colorWithHue:arc4random()/(float)UINT32_MAX saturation:arc4random()/(float)UINT32_MAX brightness:1 alpha:1];
  [controller.view addSubview:label];
  return controller;
}

- (void)pageViewController:(R4PageViewController *)pageViewController willScrollToPage:(NSInteger)toPage toController:(UIViewController *)toController
{
  DLog(@"fired. page %d", toPage);
}

- (void)pageViewController:(R4PageViewController *)pageViewController didScrollToPage:(NSInteger)toPage toController:(UIViewController *)toController
{
  DLog(@"fired. page %d", toPage);
}

- (void)pageViewController:(R4PageViewController *)pageViewController didTapOnPage:(NSInteger)page controller:(UIViewController *)controller
{
  DLog(@"fired. page %d", page);
}

- (void)pageViewController:(R4PageViewController *)pageViewController didScrollToOffset:(CGFloat)offset
{
  //DLog(@"fired. offset: %f", offset);
}

@end
