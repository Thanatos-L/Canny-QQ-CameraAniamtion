//
//  CannyHelper.m
//  opencvCanny
//
//  Created by 李龑 on 2019/5/21.
//  Copyright © 2019 baidu. All rights reserved.
//

#import "CannyHelper.h"

#include <opencv2/core.hpp>
#import <Accelerate/Accelerate.h>
#import <ImageIO/ImageIO.h>
#include <opencv2/photo.hpp>
#include <map>
@interface CannyHelper()
@property (nonatomic, assign) cv::Mat backgroundMat;
@end

@implementation CannyHelper

- (void)setupBackground:(UIImage *)image {
    UIImageToMat(image, _backgroundMat, 1);
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)processImage:(UIImage *)image {
    // 传入uiimage
    cv::Mat im;

    UIImageToMat(image, im, 1);
    // uiimage转mat
    if(im.empty()) {
        return nil;
    }
    cv::Mat src = im.clone();
    cv::Mat src_gray;
    // 原图变成灰度图
    if (src.channels()==1)
    {
        src_gray = src;
    }
    if (src.channels() == 3)
    {
        cvtColor(src, src_gray, CV_BGR2GRAY);
    }
    if (src.channels() == 4)
    {
        cvtColor(src, src_gray, CV_BGRA2GRAY);
    }
    cv::Mat edgeMat;
    // 对原图进行高斯模糊
    cv::GaussianBlur(src_gray, src_gray, cv::Size(3,3), cv::BORDER_DEFAULT);
    // 使用Canny进行边缘提取，提取出来的图像放在edgeMat, 后面连个参数是低+高阈值，影响到提取出来的边缘是多是少
    cv::Canny(src_gray, edgeMat, self.lowThreshold, self.lowThreshold * 3);
//    // 生成一张透明的mat
//    cv::Mat dst = cv::Mat(src_gray.size(),CV_8UC4,cv::Scalar(0,0,0,0));;
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    // 将拿到的边缘提取成点，再做自定义绘制
    cv::findContours(edgeMat, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
    UIImage *result;
    // 将提取出来的边缘绘制在原图上，并且设置绘制的颜色，最后转成uiimage，贴合到相机的previewlayer上，就能看到提取绘制的边缘了
    // 并且因为是
    if (hierarchy.size() > 0) {
        cv::Scalar color2(155, 240, 250, 255);
        cv::drawContours( src, contours, -1, color2, -1, cv::LINE_4, hierarchy, INT_MAX, cv::Point(0,0));
        result = MatToUIImage(src);
    } else {
        result = nil;
    }

    return result;
}


CV_EXPORTS UIImage* MatToUIImage(const cv::Mat& image);
CV_EXPORTS void UIImageToMat(const UIImage* image, cv::Mat& m, bool alphaExist);

UIImage* MatToUIImage(const cv::Mat& image) {
    
    NSData *data = [NSData dataWithBytes:image.data
                                  length:image.step.p[0] * image.rows];
    
    CGColorSpaceRef colorSpace;
    
    if (image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Preserve alpha transparency, if exists
    bool alpha = image.channels() == 4;
    CGBitmapInfo bitmapInfo = (alpha ? kCGImageAlphaLast : kCGImageAlphaNone) | kCGBitmapByteOrderDefault;
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(image.cols,
                                        image.rows,
                                        8 * image.elemSize1(),
                                        8 * image.elemSize(),
                                        image.step.p[0],
                                        colorSpace,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

void UIImageToMat(const UIImage* image,
                  cv::Mat& m, bool alphaExist) {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = CGImageGetWidth(image.CGImage), rows = CGImageGetHeight(image.CGImage);
    CGContextRef contextRef;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome)
    {
        m.create(rows, cols, CV_8UC1); // 8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone;
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNone;
        else
            m = cv::Scalar(0);
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    else
    {
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
            kCGBitmapByteOrderDefault;
        else
            m = cv::Scalar(0);
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows),
                       image.CGImage);
    CGContextRelease(contextRef);
}

- (cv::Mat)convertSampleBufferToMat:(CMSampleBufferRef)sampleBuffer{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    //Processing here
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    // put buffer in open cv, no memory copied
    cv::Mat mat = cv::Mat(bufferHeight,bufferWidth,CV_8UC4,pixel, bytesPerRow);
    //cv::resize(mat, mat,cv::Size(720,1280));
    //End processing
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    return mat;
}
@end
