//
//  ViewController.m
//  KeyboardTest
//
//  Created by Omer Hagopian on 5/18/14.
//  Copyright (c) 2014 Omer Hagopian. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface OHView : UIView

@property (nonatomic, strong) UIView *responderView;

@end

@implementation OHView

- (BOOL)isUserInteractionEnabled {
    return NO;
}

@end

@interface ViewController ()

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, readonly) UIView *keyboardWindow;
@property (nonatomic, strong) OHView *keyboardView;

@property (nonatomic, assign) CGPoint initialPoint;
@property (nonatomic, strong) NSTimer *xTimer;
@property (nonatomic, strong) NSTimer *yTimer;

@property (nonatomic, assign) int xOffset;
@property (nonatomic, assign) int yOffset;


@end

@implementation ViewController

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidAppear:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    self.xOffset = 0;
    self.yOffset = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Keyboard Test";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.textView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
    self.textView.font = [UIFont systemFontOfSize:14];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textView.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque dictum ipsum sit amet eleifend congue. Fusce id ornare arcu. Maecenas venenatis consequat tincidunt. Integer id sollicitudin enim, vel eleifend mi. Duis porta turpis a augue vestibulum rutrum. Vestibulum vel leo luctus, pulvinar odio";
    [self.view addSubview:self.textView];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIBarButtonItem *hideKeyboard = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                           target:self action:@selector(hideKeyboardAction:)];
    
    [self.navigationItem setRightBarButtonItem:hideKeyboard];
}

- (void)hideKeyboardAction:(id)sender {
    [self.view endEditing:YES];
}

- (void)invalidateTimers {
    [self.xTimer invalidate];
    self.xTimer = nil;
    
    [self.yTimer invalidate];
    self.yTimer = nil;
}

- (UIView *)keyboardWindow {
    NSArray *windows = [[UIApplication sharedApplication] windows];
    return [windows lastObject];
}

- (void)keyboardDidAppear:(NSNotification *)notification {
//    NSLog(@"keyboardDidAppear :: userinfo :: %@", notification.userInfo.description);
    
    NSValue *frameValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [frameValue CGRectValue];
    
    self.keyboardView = [[OHView alloc] initWithFrame:keyboardFrame];
    self.keyboardView.responderView = self.keyboardWindow;
    self.keyboardView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.1];
    
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    gesture.minimumPressDuration = 1;
    
    [self.keyboardWindow addSubview:self.keyboardView];
    for (UIView *aView in self.keyboardWindow.subviews) {
        if (aView != self.keyboardView) {
            [aView addGestureRecognizer:gesture];
        }
    }
}

- (void)xTimerTriggered:(NSTimer *)timer {

    UITextRange *selectedRange = [self.textView selectedTextRange];
    UITextPosition *newPosition = nil;
    
    //new x position
    if (self.yOffset == 0 && self.xOffset != 0) {
        NSLog(@"xOffset: %d", self.xOffset);
        UITextLayoutDirection xDirection = self.xOffset > 0 ? UITextLayoutDirectionRight : UITextLayoutDirectionLeft;
        newPosition = [self.textView positionFromPosition:selectedRange.start inDirection:xDirection offset:abs(self.xOffset)];
    }
    
    if (newPosition) {
        UITextRange *newRange = [self.textView textRangeFromPosition:newPosition toPosition:newPosition];
        [self.textView setSelectedTextRange:newRange];
    }
}

- (void)yTimerTriggered:(NSTimer *)timer {
    
    UITextRange *selectedRange = [self.textView selectedTextRange];
    UITextPosition *newPosition = nil;
    
    //new y position
    if (self.yOffset != 0) {
        UITextLayoutDirection yDirection = self.yOffset > 0 ? UITextLayoutDirectionDown : UITextLayoutDirectionUp;
        newPosition = [self.textView positionFromPosition:selectedRange.start inDirection:yDirection offset:1];
    }
    
    if (newPosition) {
        UITextRange *newRange = [self.textView textRangeFromPosition:newPosition toPosition:newPosition];
        [self.textView setSelectedTextRange:newRange];
    }
}

- (void)longPressAction:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.keyboardView.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.2];
        self.initialPoint = [gesture locationInView:gesture.view];
        
        [self invalidateTimers];
        self.xTimer = [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(xTimerTriggered:) userInfo:nil repeats:YES];
        self.yTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(yTimerTriggered:) userInfo:nil repeats:YES];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded ||
             gesture.state == UIGestureRecognizerStateCancelled) {
        self.keyboardView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.1];
        [self invalidateTimers];
        
        self.xOffset = 0;
        self.yOffset = 0;
        return;
    }
    else if (gesture.state == UIGestureRecognizerStateFailed ){
        return;
    }
    
    CGPoint currentPoint = [gesture locationInView:gesture.view];
    
    
    //Horizontal Offset
    int xOffset = 0;
    int xDistance = currentPoint.x - self.initialPoint.x;
//    NSLog(@"Distance: %d", xDistance);
    
    if (abs(xDistance) < 30)
        xOffset = 0;
    else if (abs(xDistance) < 70)
        xOffset = 1;
    else if (abs(xDistance) < 100)
        xOffset = 2;
    else if (abs(xDistance) < 140)
        xOffset = 4;
    else if (abs(xDistance) < 180)
        xOffset = 8;
    else if (abs(xDistance) < 240)
        xOffset = 16;
    
    if (xDistance < 0)
        xOffset = 0-xOffset;
    
    self.xOffset = xOffset;
    
//    //Vertical Offset
    int yOffset = 0;
    int yDistance = currentPoint.y - self.initialPoint.y;
//    NSLog(@"Distance: %d", yDistance);
    
    if (abs(yDistance) > 30)
        yOffset = 1;
    
    if (yDistance < 0)
        yOffset = 0-yOffset;
    
    self.yOffset = yOffset;
}

- (void)keyboardDidHide:(NSNotification *)notification {
//    NSLog(@"keyboardDidHide :: userinfo :: %@", notification.userInfo.description);
    [self.keyboardView removeFromSuperview];
    self.keyboardView = nil;
}

@end
