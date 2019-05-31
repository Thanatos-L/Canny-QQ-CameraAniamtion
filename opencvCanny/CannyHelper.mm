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
@implementation CannyHelper

- (UIImage *)processImage:(UIImage *)image {
    cv::Mat im;
    UIImageToMat(image, im, 1);
    if(im.empty()) {
        return nil;
    }
    cv::Mat src = im.clone();
    cv::Mat src_gray;
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
    cv::GaussianBlur(src_gray, src_gray, cv::Size(3,3), cv::BORDER_DEFAULT);
    
    cv::Canny(src_gray, edgeMat, self.lowThreshold, self.lowThreshold * 3);
    
    cv::Mat dst = cv::Mat(src_gray.size(),CV_8UC4,cv::Scalar(130,180,180,255));;
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(edgeMat, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
    
    int idx = 0;
    UIImage *result;
    if (hierarchy.size() > 0) {
        cv::Scalar color2(155, 240, 250, 255);
//        for( ; idx >= 0; idx = hierarchy[idx][0] )
//        {
//            cv::Scalar color( rand()&255, rand()&255, rand()&255 );
////            cv::drawContours( dst, contours, idx, color2, -1, cv::LINE_AA, CV_FILLED, 8, hierarchy );
//            cv::drawContours( dst, contours, idx, color2, 1, cv::LINE_AA, hierarchy, INT_MAX, cv::Point(0,0));
//        }
        cv::drawContours( dst, contours, -1, color2, -1, cv::LINE_4, hierarchy, INT_MAX, cv::Point(0,0));
//        cv::drawContours( im, contours, -1, cv::Scalar(255,255,255,255), CV_FILLED, 8, hierarchy );
        result = MatToUIImage(dst);
    } else {
        result = nil;
    }

    return result;
}


- (UIImage *)processSampleBuffer:(CMSampleBufferRef)buffer {
//    cv::Mat im = [self convertSampleBufferToMat:buffer];
//
//    if(im.empty()) {
//        return nil;
//    }
//    cv::Mat src = im.clone();
//    cv::Mat src_gray;
//    if (src.channels()==1)
//    {
//        src_gray = src;
//    }
//    if (src.channels() == 3)
//    {
//        cvtColor(src, src_gray, CV_BGR2GRAY);
//    }
//    if (src.channels() == 4)
//    {
//        cvtColor(src, src_gray, CV_BGRA2GRAY);
//    }
//    UIImage *origin = MatToUIImage(src);
//    cv::Mat edgeMat;
//    cv::GaussianBlur(src_gray, src_gray, cv::Size(5,5), cv::BORDER_DEFAULT);
//    cv::Canny(src_gray, edgeMat, 10, 100);
//
//    cv::Mat dst = cv::Mat(src_gray.size(),CV_8UC4,cv::Scalar(0,0,0,255));;
//    std::vector<std::vector<cv::Point>> contours;
//    std::vector<cv::Vec4i> hierarchy;
//    cv::findContours(edgeMat, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
//
//    int idx = 0;
//    UIImage *result;
//    if (hierarchy.size() > 0) {
////        for( ; idx >= 0; idx = hierarchy[idx][0] )
////        {
////            cv::Scalar color( rand()&255, rand()&255, rand()&255 );
////            cv::Scalar color2(255, 255, 255, 255);
////            cv::drawContours( im, contours, idx, color2, CV_FILLED, 8, hierarchy );
////        }
//                cv::drawContours( im, contours, -1, cv::Scalar(255,255,255,255), CV_FILLED, 8, hierarchy );
//        result = MatToUIImage(im);
//    } else {
//        result = nil;
//    }
//
//    return result;
    return nil;
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
