//
//  ViewController.m
//  opencvCanny
//
//  Created by 李龑 on 2019/5/21.
//  Copyright © 2019 baidu. All rights reserved.
//

#import "ViewController.h"
#import "CannyHelper.h"
#import "LyCameraController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<LyCameraControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) LyCameraController *cameraController;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIImageView *edgeImageView;
@property (nonatomic, strong) CannyHelper *cannyHelper;
@property (nonatomic, strong) UIImage *background;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCamera];
    self.cannyHelper = [CannyHelper new];
    self.cannyHelper.lowThreshold = 60;
    self.background = [UIImage imageNamed:@"background"];
    [self.cannyHelper setupBackground:_background];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    [self showImage];
    [self.cameraController startCapture];
}

- (void)setupCamera {
    self.cameraController = [LyCameraController new];
    self.cameraController.cameraDelegate = self;
    self.cameraController.bufferDelegate = self;
    [self.cameraController prepareCaptureSession];
}

- (void)cameraContrllerFinishSetCamera {
    if (_previewLayer) {
        return;
    }
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_cameraController.avCaptureSession];
    _previewLayer.frame = self.view.frame;
    _previewLayer.videoGravity= AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:_previewLayer];
    [self setupEdgeView];
    [self setupSlider];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
//    UIImage *newImage = [self.cannyHelper processSampleBuffer:sampleBuffer];
    UIImage *newImage = [self.cannyHelper processImage:image];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.edgeImageView.image = newImage;
    });
}


//- (UIImage *)assembleBackgroundImageWith:(UIImage *)image {
//    UIGraphicsBeginImageContext(image.size);
//}


- (void)setupSlider {
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(50, 100, 300, 30)];
    [self.view addSubview:slider];
    [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [slider setBackgroundColor:[UIColor clearColor]];
    slider.minimumValue = 0.0;
    slider.maximumValue = 100.0;
    slider.continuous = YES;
    slider.value = 50.0;
}

- (void)sliderAction:(UISlider *)sender {
    NSLog(@"%f", sender.value);
    self.cannyHelper.lowThreshold = sender.value;
    
}

- (void)setupEdgeView {
    self.edgeImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.edgeImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.edgeImageView];
    [self animationEdgeImageView];
}

- (void)animationEdgeImageView {
    
    UIColor *color1 = [UIColor colorWithRed:(0/255.0)  green:(0/255.0)  blue:(0/255.0)  alpha:0];
    UIColor *color2 = [UIColor colorWithRed:(0/255.0)  green:(0/255.0)  blue:(0/255.0)  alpha:1];
    UIColor *color3 = [UIColor colorWithRed:(0/255.0)  green:(0/255.0)  blue:(0/255.0)  alpha:1];
    NSArray *colors = [NSArray arrayWithObjects:(id)color1.CGColor, color2.CGColor, color3.CGColor,nil];
    NSArray *locations = [NSArray arrayWithObjects:@0.0,@0.5,@1.0, nil];
    CAGradientLayer *gradientAnimLayer = [CAGradientLayer layer];
    gradientAnimLayer.frame = CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    [gradientAnimLayer setColors:colors];
    gradientAnimLayer.locations = locations;
    
    UIColor *color11 = [UIColor colorWithRed:(255/255.0)  green:(255/255.0)  blue:(255/255.0)  alpha:0];
    UIColor *color22 = [UIColor colorWithRed:(155/255.0)  green:(240/255.0)  blue:(240/255.0)  alpha:1];
    NSArray *colors2 = [NSArray arrayWithObjects:(id)color11.CGColor, color22.CGColor,nil];
    NSArray *locations2 = [NSArray arrayWithObjects:@0.7,@1.0, nil];
    CAGradientLayer *gradientColorLayer = [CAGradientLayer layer];
    gradientColorLayer.frame = CGRectMake(0,  -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    [gradientColorLayer setColors:colors2];
    gradientColorLayer.locations = locations2;
    
    self.edgeImageView.layer.mask = gradientAnimLayer;
    [self.edgeImageView.layer addSublayer:gradientColorLayer];
    
    CGPoint originPosition = CGPointMake(self.view.frame.size.width / 2, -self.view.frame.size.height/1.5);
    CGPoint finalPosition = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 1.5);
    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    maskLayerAnimation.fromValue = [NSValue valueWithCGPoint:originPosition];
    maskLayerAnimation.toValue = [NSValue valueWithCGPoint:finalPosition];;
    maskLayerAnimation.removedOnCompletion = NO;
    maskLayerAnimation.duration = 4.0;
    maskLayerAnimation.repeatCount = HUGE_VALF;
    maskLayerAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [gradientAnimLayer addAnimation:maskLayerAnimation forKey:@"maskLayerAnimation"];
    [gradientColorLayer addAnimation:maskLayerAnimation forKey:@"maskLayerAnimation"];
}

-(void)showImage {
    UIImage *image = [UIImage imageNamed:@"origin"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:imageView];
    
    UIImage *newImage = [self.cannyHelper processImage:image];
    
    imageView.image = newImage;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return nil;
    }
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    if (!baseAddress) {
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        return nil;
    }
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    // rotate image
    UIImage *image = [[UIImage alloc] initWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

@end
