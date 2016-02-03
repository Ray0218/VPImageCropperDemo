//
//  VPImageCropperViewController.m
//  VPolor
//
//  Created by Vinson.D.Warm on 12/30/13.
//  Copyright (c) 2013 Huang Vinson. All rights reserved.
//

#import "VPImageCropperViewController.h"

#define SCALE_FRAME_Y 100.0f
#define BOUNDCE_DURATION 0.3f

@interface VPImageCropperViewController ()

@property (nonatomic, retain) UIImage *originalImage;
@property (nonatomic, retain) UIImage *editedImage;

@property (nonatomic, retain) UIImageView *showImgView;
@property (nonatomic, retain) UIView *overCoverView;
@property (nonatomic, retain) UIView *circleView;

@property (nonatomic, assign) CGRect oldFrame;
@property (nonatomic, assign) CGRect largeFrame;

@property (nonatomic, assign) CGFloat limitMax;


@property (nonatomic, assign) CGRect latestFrame;

@end

@implementation VPImageCropperViewController

- (void)dealloc {
    self.originalImage = nil;
    self.showImgView = nil;
    self.editedImage = nil;
    self.overCoverView = nil;
    self.circleView = nil;
}

- (id)initWithImage:(UIImage *)originalImage circleFrame:(CGRect)cropFrame limitScaleRatio:(NSInteger)limitRatio {
    self = [super init];
    if (self) {
        self.circleFrame = cropFrame;
        self.limitMax = limitRatio;
        self.originalImage = originalImage;
     }
    return self;
}

 
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initView];
    [self initControlBtn];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

- (void)initView {
    self.showImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    [self.showImgView setMultipleTouchEnabled:YES];
    [self.showImgView setUserInteractionEnabled:YES];
    [self.showImgView setImage:self.originalImage];
    [self.showImgView setUserInteractionEnabled:YES];
    [self.showImgView setMultipleTouchEnabled:YES];
    
    // scale to fit the screen
    CGFloat oriWidth = self.circleFrame.size.width;
    CGFloat oriHeight = self.originalImage.size.height * (oriWidth / self.originalImage.size.width);
    CGFloat oriX = self.circleFrame.origin.x + (self.circleFrame.size.width - oriWidth) / 2;
    CGFloat oriY = self.circleFrame.origin.y + (self.circleFrame.size.height - oriHeight) / 2;
    self.oldFrame = CGRectMake(oriX, oriY, oriWidth, oriHeight);
    self.latestFrame = self.oldFrame;
    self.showImgView.frame = self.oldFrame;
    
    self.largeFrame = CGRectMake(0, 0, self.limitMax * self.oldFrame.size.width, self.limitMax * self.oldFrame.size.height);
    //最小图
    
    
    
    [self addGestureRecognizers];
    [self.view addSubview:self.showImgView];
    
    //半透明背景
    self.overCoverView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.overCoverView.alpha = .5f;
    self.overCoverView.backgroundColor = [UIColor blackColor];
    self.overCoverView.userInteractionEnabled = NO;
    self.overCoverView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.overCoverView];
    
    //圆圈
    self.circleView = [[UIView alloc] initWithFrame:self.circleFrame];
    self.circleView.layer.borderColor = [UIColor yellowColor].CGColor;
    self.circleView.layer.borderWidth = 1.0f;
    self.circleView.layer.cornerRadius = self.circleFrame.size.width/2.0 ;
    self.circleView.autoresizingMask = UIViewAutoresizingNone;
    [self.view addSubview:self.circleView];
    
    [self overlayClipping];
}

- (void)initControlBtn {
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 50.0f, 100, 50)];
    cancelBtn.backgroundColor = [UIColor blackColor];
    cancelBtn.titleLabel.textColor = [UIColor whiteColor];
    [cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
    [cancelBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [cancelBtn.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [cancelBtn.titleLabel setNumberOfLines:0];
    [cancelBtn setTitleEdgeInsets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    [cancelBtn addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelBtn];
    
    UIButton *confirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 100.0f, self.view.frame.size.height - 50.0f, 100, 50)];
    confirmBtn.backgroundColor = [UIColor blackColor];
    confirmBtn.titleLabel.textColor = [UIColor whiteColor];
    [confirmBtn setTitle:@"OK" forState:UIControlStateNormal];
    [confirmBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
    [confirmBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    confirmBtn.titleLabel.textColor = [UIColor whiteColor];
    [confirmBtn.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [confirmBtn.titleLabel setNumberOfLines:0];
    [confirmBtn setTitleEdgeInsets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    [confirmBtn addTarget:self action:@selector(confirm:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:confirmBtn];
}

- (void)cancel:(id)sender {
     
    if (self.finishhandle) {
        self.finishhandle( self,nil) ;
    }
}

- (void)confirm:(id)sender {
     
    if (self.finishhandle) {
        self.finishhandle(self,[self getSubImage]) ;
    }
}

- (void)overlayClipping
{
    
    UIBezierPath *paths = [UIBezierPath bezierPathWithRect:self.overCoverView.frame] ;
    
    
   [paths appendPath: [[UIBezierPath bezierPathWithRoundedRect:self.circleView.frame cornerRadius:self.circleView.frame.size.width/2.0] bezierPathByReversingPath]];
    
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
//    maskLayer.fillColor = [UIColor greenColor].CGColor ;
//    CGMutablePathRef path = CGPathCreateMutable();
//    // Left side of the ratio view
//    CGPathAddRect(path, nil, CGRectMake(0, 0,
//                                        self.ratioView.frame.origin.x,
//                                        self.overlayView.frame.size.height));
//    // Right side of the ratio view
//    CGPathAddRect(path, nil, CGRectMake(
//                                        self.ratioView.frame.origin.x + self.ratioView.frame.size.width,
//                                        0,
//                                        self.overlayView.frame.size.width - self.ratioView.frame.origin.x - self.ratioView.frame.size.width,
//                                        self.overlayView.frame.size.height));
//    // Top side of the ratio view
//    CGPathAddRect(path, nil, CGRectMake(0, 0,
//                                        self.overlayView.frame.size.width,
//                                        self.ratioView.frame.origin.y));
//    // Bottom side of the ratio view
//    CGPathAddRect(path, nil, CGRectMake(0,
//                                        self.ratioView.frame.origin.y + self.ratioView.frame.size.height,
//                                        self.overlayView.frame.size.width,
//                                        self.overlayView.frame.size.height - self.ratioView.frame.origin.y + self.ratioView.frame.size.height));
    maskLayer.path = paths.CGPath;
    self.overCoverView.layer.mask = maskLayer;
//    CGPathRelease(path);
    
//    [self.view.layer addSublayer:maskLayer];
}

// register all gestures
- (void) addGestureRecognizers
{
    // add pinch gesture
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
    [self.view addGestureRecognizer:pinchGestureRecognizer];
    
    // add pan gesture
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
}

// pinch gesture handler
- (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    UIView *view = self.showImgView;
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
        pinchGestureRecognizer.scale = 1;
    }
    else if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGRect newFrame = self.showImgView.frame;
        newFrame = [self handleScaleOverflow:newFrame];
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:BOUNDCE_DURATION animations:^{
            self.showImgView.frame = newFrame;
            self.latestFrame = newFrame;
        }];
    }
}

// pan gesture handler
- (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    UIView *view = self.showImgView;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        // calculate accelerator
        CGFloat absCenterX = self.circleFrame.origin.x + self.circleFrame.size.width / 2;
        CGFloat absCenterY = self.circleFrame.origin.y + self.circleFrame.size.height / 2;
        CGFloat scaleRatio = self.showImgView.frame.size.width / self.circleFrame.size.width;
        CGFloat acceleratorX = 1 - ABS(absCenterX - view.center.x) / (scaleRatio * absCenterX);
        CGFloat acceleratorY = 1 - ABS(absCenterY - view.center.y) / (scaleRatio * absCenterY);
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x * acceleratorX, view.center.y + translation.y * acceleratorY}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }
    else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // bounce to original frame
        CGRect newFrame = self.showImgView.frame;
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:BOUNDCE_DURATION animations:^{
            self.showImgView.frame = newFrame;
            self.latestFrame = newFrame;
        }];
    }
}

- (CGRect)handleScaleOverflow:(CGRect)newFrame {
    // bounce to original frame
    CGPoint oriCenter = CGPointMake(newFrame.origin.x + newFrame.size.width/2, newFrame.origin.y + newFrame.size.height/2);
    if (newFrame.size.width < self.oldFrame.size.width) {
        newFrame = self.oldFrame;
    }
    
    if (newFrame.size.width > self.largeFrame.size.width) {
        newFrame = self.largeFrame;
    }
    newFrame.origin.x = oriCenter.x - newFrame.size.width/2;
    newFrame.origin.y = oriCenter.y - newFrame.size.height/2;
    return newFrame;
}


- (CGRect)handleBorderOverflow:(CGRect)newFrame {
    // horizontally
    if (newFrame.origin.x > self.circleFrame.origin.x)
        newFrame.origin.x = self.circleFrame.origin.x;
    if (CGRectGetMaxX(newFrame) < self.circleFrame.size.width)
        newFrame.origin.x = self.circleFrame.size.width - newFrame.size.width;
    // vertically
    if (newFrame.origin.y > self.circleFrame.origin.y) newFrame.origin.y = self.circleFrame.origin.y;
    if (CGRectGetMaxY(newFrame) < self.circleFrame.origin.y + self.circleFrame.size.height) {
        newFrame.origin.y = self.circleFrame.origin.y + self.circleFrame.size.height - newFrame.size.height;
    }
    // adapt horizontally rectangle
    if (self.showImgView.frame.size.width > self.showImgView.frame.size.height && newFrame.size.height <= self.circleFrame.size.height) {
        newFrame.origin.y = self.circleFrame.origin.y + (self.circleFrame.size.height - newFrame.size.height) / 2;
    }
    return newFrame;
}



-(UIImage *)getSubImage{
    CGRect squareFrame = self.circleFrame;
    CGFloat scaleRatio = self.latestFrame.size.width / self.originalImage.size.width;
    CGFloat x = (squareFrame.origin.x - self.latestFrame.origin.x) / scaleRatio;
    CGFloat y = (squareFrame.origin.y - self.latestFrame.origin.y) / scaleRatio;
    CGFloat w = squareFrame.size.width / scaleRatio;
    CGFloat h = squareFrame.size.width / scaleRatio;
    if (self.latestFrame.size.width < self.circleFrame.size.width) {
        CGFloat newW = self.originalImage.size.width;
        CGFloat newH = newW * (self.circleFrame.size.height / self.circleFrame.size.width);
        x = 0; y = y + (h - newH) / 2;
        w = newH; h = newH;
    }
    if (self.latestFrame.size.height < self.circleFrame.size.height) {
        CGFloat newH = self.originalImage.size.height;
        CGFloat newW = newH * (self.circleFrame.size.width / self.circleFrame.size.height);
        x = x + (w - newW) / 2; y = 0;
        w = newH; h = newH;
    }
    CGRect myImageRect = CGRectMake(x, y, w, h);
    CGImageRef imageRef = self.originalImage.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, myImageRect);
    CGSize size;
    size.width = myImageRect.size.width;
    size.height = myImageRect.size.height;
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, myImageRect, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    
    return smallImage ;
//    return [self circleImage:smallImage];
 }


#pragma mark - 图片变成圆形
-(UIImage*) circleImage:(UIImage*) image {
    UIGraphicsBeginImageContext(image.size);
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    
    CGRect rect = CGRectMake(0,0, image.size.width, image.size.height);
    CGContextAddEllipseInRect(context, rect);
    CGContextClip(context);
    [image drawInRect:rect];
    
     CGContextAddEllipseInRect(context, rect);
    CGContextStrokePath(context);
    
    
    UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newimg;
}


@end
